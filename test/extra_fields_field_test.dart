import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/models/extra_field.dart';
import 'package:lubelogger_mobile/core/models/server_info.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/extra_fields_field.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';

/// Drives the custom-fields editor the way a record form does: hand it the
/// record's stored fields, let the template arrive, and check what it would
/// send back.
void main() {
  late List<ExtraField> reported;
  final formKey = GlobalKey<FormState>();

  Future<void> pump(
    WidgetTester tester, {
    required List<ExtraField> initial,
    Map<ExtraFieldRecordType, List<ExtraField>>? templates,
  }) async {
    reported = const [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          extraFieldTemplatesProvider.overrideWith((ref) async => templates),
          serverInfoProvider.overrideWith(
            (ref) async => const ServerInfo(
              currentVersion: '1.7.0',
              locale: 'en-US',
              currencySymbol: r'$',
              decimalSeparator: '.',
              dateFormat: 'dd.MM.yyyy',
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: ExtraFieldsField(
                  recordType: ExtraFieldRecordType.service,
                  initial: initial,
                  enabled: true,
                  onChanged: (fields) => reported = fields,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the template and reports what the user fills in', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const [],
      templates: {
        ExtraFieldRecordType.service: const [
          ExtraField(name: 'Workshop', isRequired: true),
          ExtraField(name: 'Invoice no'),
        ],
      },
    );

    expect(find.text('Workshop *'), findsOneWidget);
    expect(find.text('Invoice no'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Demo Motors');
    await tester.pump();

    expect(reported.single.name, 'Workshop');
    expect(reported.single.value, 'Demo Motors');
  });

  testWidgets('a required field blocks the enclosing form', (tester) async {
    await pump(
      tester,
      initial: const [],
      templates: {
        ExtraFieldRecordType.service: const [
          ExtraField(name: 'Workshop', isRequired: true),
        ],
      },
    );

    expect(formKey.currentState!.validate(), isFalse);

    await tester.enterText(find.byType(TextFormField).first, 'Demo Motors');
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('keeps a stored value and drops a field the template lost', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const [
        ExtraField(name: 'Workshop', value: 'Demo Motors'),
        ExtraField(name: 'Retired field', value: 'stale'),
      ],
      templates: {
        ExtraFieldRecordType.service: const [ExtraField(name: 'Workshop')],
      },
    );

    expect(find.text('Demo Motors'), findsOneWidget);
    expect(find.text('stale'), findsNothing);
    expect(reported.single.name, 'Workshop');
  });

  testWidgets('round-trips stored fields when the template is unknown', (
    tester,
  ) async {
    await pump(
      tester,
      initial: const [ExtraField(name: 'Workshop', value: 'Demo Motors')],
    );

    expect(find.text('Demo Motors'), findsOneWidget);
    expect(reported.single.value, 'Demo Motors');
  });

  testWidgets('a date field writes the server\'s own format', (tester) async {
    await pump(
      tester,
      initial: const [],
      templates: {
        ExtraFieldRecordType.service: const [
          ExtraField(name: 'Warranty until', fieldType: ExtraFieldType.date),
        ],
      },
    );

    await tester.tap(find.text('—'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(reported, hasLength(1));
    expect(reported.single.value, matches(RegExp(r'^\d{2}\.\d{2}\.\d{4}$')));
    expect(find.text(reported.single.value), findsOneWidget);
  });

  testWidgets('a stored date outside the calendar still opens it', (
    tester,
  ) async {
    // `showDatePicker` asserts that it opens inside its range; a value typed on
    // the server before 1900 used to throw instead of opening the picker.
    await pump(
      tester,
      initial: const [ExtraField(name: 'Warranty until', value: '01.01.1850')],
      templates: {
        ExtraFieldRecordType.service: const [
          ExtraField(name: 'Warranty until', fieldType: ExtraFieldType.date),
        ],
      },
    );

    await tester.tap(find.text('01.01.1850'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(reported.last.value, '01.01.1900');
  });
}
