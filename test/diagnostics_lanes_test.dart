import 'dart:convert';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/api_exceptions.dart';
import 'package:lubelogger_mobile/core/diagnostics/diagnostics_wiring.dart';
import 'package:lubelogger_mobile/core/diagnostics/image_probe.dart';
import 'package:lubelogger_mobile/core/diagnostics/log_form.dart';
import 'package:lubelogger_mobile/core/settings/settings_repository.dart';
import 'package:dash_kit/dash_kit.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/record_form_scaffold.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

/// The lanes that exist so a failure the user *sees* is not invisible in the
/// log: a fetch the app decided to swallow, a screen that gave up, an image
/// that never loaded. None of them go through the HTTP probe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiagnosticRecorder recorder;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    recorder = lubeloggerRecorder(
      settings: SettingsRepository(await SharedPreferences.getInstance()),
      loadFacts: () async => const SessionFacts(app: '0.2.7+207'),
      resolveDirectory: () async => null,
    );
  });

  tearDown(() async {
    if (DiagnosticRecorder.isRecording) await recorder.stop();
  });

  Future<List<Map<String, Object?>>> stopAndRead() async {
    final jsonl = await recorder.stop();
    return [
      for (final line in const LineSplitter().convert(jsonl).skip(1))
        jsonDecode(line) as Map<String, Object?>,
    ];
  }

  Map<String, Object?> only(List<Map<String, Object?>> records, String evt) =>
      records.singleWhere((r) => r['evt'] == evt);

  group('guardOrNull', () {
    test('a swallowed failure says so, with what it was', () async {
      await recorder.start();
      final value = await guardOrNull<int>(
        () => throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/vehicle/info'),
          reason: 'no route to host',
        ),
      );

      expect(value, isNull);
      final record = only(await stopAndRead(), 'degraded');
      expect(record['src'], 'http');
      expect(record['lvl'], 'warn');
      expect(record['cause'], 'serverUnreachable');
      // Which call the screen carried on without: with several in flight, the
      // surrounding `http` records cannot say.
      expect(record['method'], 'GET');
      expect(record['path'], '/api/vehicle/info');
    });

    test('a parse failure is caught too — the probe never sees one', () async {
      await recorder.start();
      final value = await guardOrNull<int>(() => throw TypeError());

      expect(value, isNull);
      expect(only(await stopAndRead(), 'degraded')['cause'], contains('Error'));
    });

    test(
      'an auth failure is not swallowed, so it is not logged here',
      () async {
        await recorder.start();
        final options = RequestOptions(path: '/api/vehicles');
        await expectLater(
          guardOrNull<int>(
            () => throw DioException.badResponse(
              statusCode: 401,
              requestOptions: options,
              response: Response<void>(
                statusCode: 401,
                requestOptions: options,
              ),
            ),
          ),
          throwsA(isA<AuthException>()),
        );
        final records = await stopAndRead();
        expect(records.where((r) => r['evt'] == 'degraded'), isEmpty);
      },
    );
  });

  group('state views', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: logSurface('garage', Scaffold(body: child))),
    );

    testWidgets('an error view names the screen it gave up on', (tester) async {
      await recorder.start();
      await pump(
        tester,
        AsyncErrorView(
          message: 'could not load',
          onRetry: () {},
          retryLabel: 'retry',
        ),
      );

      final record = only(await stopAndRead(), 'error_view');
      expect(record['surface'], 'garage');
      expect(record['lvl'], 'warn');
      // The message is localized user-facing text and stays out.
      expect(record.toString(), isNot(contains('could not load')));
    });

    testWidgets('an empty view is its own event', (tester) async {
      await recorder.start();
      await pump(
        tester,
        const EmptyStateView(message: 'nothing here', icon: Icons.inbox),
      );

      expect(only(await stopAndRead(), 'empty_view')['surface'], 'garage');
    });

    testWidgets('a rebuild does not repeat the record', (tester) async {
      await recorder.start();
      for (var i = 0; i < 3; i++) {
        await pump(
          tester,
          EmptyStateView(message: 'nothing here $i', icon: Icons.inbox),
        );
        await tester.pump();
      }

      final records = await stopAndRead();
      expect(records.where((r) => r['evt'] == 'empty_view').length, 1);
    });
  });

  group('image probe', () {
    testWidgets('a broken photo is reported once per session', (tester) async {
      await recorder.start();
      final builder = ImageProbe.errorBuilder(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Three cards showing three broken photos, as a garage would.
              final failure = NetworkImageLoadException(
                statusCode: 401,
                uri: Uri.parse('https://example.invalid/documents/car.jpg'),
              );
              for (var i = 0; i < 3; i++) {
                builder(context, failure, null);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final records = await stopAndRead();
      expect(records.where((r) => r['evt'] == 'image_failed').length, 1);
      expect(
        only(records, 'image_failed')['type'],
        'NetworkImageLoadException',
      );
    });
  });

  group('form submit', () {
    /// A form the shared shell owns, with one field that always refuses.
    Widget refusingForm(GlobalKey<FormState> key, VoidCallback onSubmit) =>
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: logSurface(
            'form.fuel',
            Scaffold(
              body: RecordFormScaffold(
                formKey: key,
                title: 'Fuel',
                isEditing: false,
                submitting: false,
                onCancel: () {},
                onSubmit: onSubmit,
                onDelete: null,
                error: null,
                fields: [TextFormField(validator: (_) => 'required')],
              ),
            ),
          ),
        );

    testWidgets('a submit the form refuses leaves a record', (tester) async {
      await recorder.start();
      var submitted = false;
      await tester.pumpWidget(
        refusingForm(GlobalKey<FormState>(), () => submitted = true),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final record = only(await stopAndRead(), 'submit');
      expect(record['id'], 'form.fuel');
      expect(record['reason'], 'invalid');
      expect(record['lvl'], 'warn');
      // The shell holds the submit back, so the caller's own guard never runs
      // and the refusal is recorded exactly once.
      expect(submitted, isFalse);
    });

    testWidgets('an accepted submit is recorded too', (tester) async {
      await recorder.start();
      final key = GlobalKey<FormState>();
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: logSurface(
            'form.note',
            Scaffold(
              body: Builder(
                builder: (context) => Form(
                  key: key,
                  child: ElevatedButton(
                    onPressed: () {
                      if (validateAndLog(context, key)) submitted = true;
                    },
                    child: const Text('Save'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(en.actionSave));
      await tester.pump();

      final record = only(await stopAndRead(), 'submit');
      expect(record['id'], 'form.note');
      expect(record.containsKey('reason'), isFalse);
      expect(submitted, isTrue);
    });
  });
}
