import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/models/odometer_record.dart';
import 'package:lubelogger_mobile/core/models/vehicle_info.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/add_odometer_form.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

class _WriteCapturingAdapter implements HttpClientAdapter {
  final writes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method != 'GET') writes.add(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'message': ''}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// An odometer reading that goes backwards is not illegal — a swapped cluster
/// or a corrected entry both produce one — but it is almost always a fumbled
/// digit, and every number derived from it (gain since last, economy, the
/// distance chart) inherits the mistake with nothing to mark it as wrong.
void main() {
  const vehicleId = 1;

  OdometerRecord record({
    required int id,
    required double odometer,
    required DateTime date,
  }) => OdometerRecord(
    id: id,
    date: date,
    odometer: odometer,
    initialOdometer: 0,
    notes: '',
    tags: '',
  );

  VehicleInfo info(double lastReported) => VehicleInfo.fromJson({
    'vehicleData': {'id': vehicleId, 'year': 2020, 'make': 'M', 'model': 'X'},
    'lastReportedOdometer': lastReported,
  });

  Future<_WriteCapturingAdapter> pump(
    WidgetTester tester, {
    List<OdometerRecord> records = const [],
    VehicleInfo? vehicleInfo,
    OdometerRecord? existing,
  }) async {
    final adapter = _WriteCapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://server'))
      ..httpClientAdapter = adapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiclesRepositoryProvider.overrideWithValue(VehiclesRepository(dio)),
          vehicleUnitsProvider.overrideWith(
            (ref, id) => const VehicleUnits(UnitsSettings()),
          ),
          extraFieldTemplatesProvider.overrideWith((ref) async => null),
          odometerRecordsProvider.overrideWith((ref, id) async => records),
          vehicleInfoProvider.overrideWith(
            (ref, id) async => vehicleInfo ?? info(0),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAddOdometerForm(
                    context,
                    vehicleId,
                    existing: existing,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return adapter;
  }

  Future<void> type(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField).first, value);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, en.actionAdd));
    await tester.pumpAndSettle();
  }

  testWidgets('the last reading is offered as a hint', (tester) async {
    await pump(
      tester,
      records: [
        record(id: 1, odometer: 67650, date: DateTime(2026, 4, 1)),
        record(id: 2, odometer: 64200, date: DateTime(2026, 1, 1)),
      ],
    );

    expect(find.text(en.formOdometerLast('67,650 km')), findsOneWidget);
  });

  testWidgets('a garage that logs only fuel-ups falls back to the server', (
    tester,
  ) async {
    // No odometer records at all, but the server counts the readings that came
    // in with fill-ups and services.
    await pump(tester, vehicleInfo: info(88000));

    expect(find.text(en.formOdometerLast('88,000 km')), findsOneWidget);
  });

  testWidgets('a lower reading warns while it is typed', (tester) async {
    await pump(
      tester,
      records: [record(id: 1, odometer: 67650, date: DateTime(2026, 4, 1))],
    );

    await type(tester, '6765'); // a dropped digit
    expect(find.text(en.formOdometerBackwards('67,650 km')), findsOneWidget);
    expect(find.text(en.formOdometerLast('67,650 km')), findsNothing);
  });

  testWidgets('a higher reading keeps the plain hint', (tester) async {
    await pump(
      tester,
      records: [record(id: 1, odometer: 67650, date: DateTime(2026, 4, 1))],
    );

    await type(tester, '67900');
    expect(find.text(en.formOdometerLast('67,650 km')), findsOneWidget);
  });

  testWidgets(
    'saving a lower reading asks first, and a cancel writes nothing',
    (tester) async {
      final adapter = await pump(
        tester,
        records: [record(id: 1, odometer: 67650, date: DateTime(2026, 4, 1))],
      );

      await type(tester, '6765');
      await save(tester);

      expect(find.text(en.formOdometerBackwardsTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, en.actionCancel));
      await tester.pumpAndSettle();
      expect(adapter.writes, isEmpty);
    },
  );

  testWidgets('confirming saves it anyway', (tester) async {
    final adapter = await pump(
      tester,
      records: [record(id: 1, odometer: 67650, date: DateTime(2026, 4, 1))],
    );

    await type(tester, '6765');
    await save(tester);
    await tester.tap(find.widgetWithText(FilledButton, en.actionSaveAnyway));
    await tester.pumpAndSettle();

    expect(adapter.writes, hasLength(1));
  });

  testWidgets('a rising reading is never questioned', (tester) async {
    final adapter = await pump(
      tester,
      records: [record(id: 1, odometer: 67650, date: DateTime(2026, 4, 1))],
    );

    await type(tester, '67900');
    await save(tester);

    expect(find.text(en.formOdometerBackwardsTitle), findsNothing);
    expect(adapter.writes, hasLength(1));
  });

  testWidgets('an old record is measured against the one before it', (
    tester,
  ) async {
    // Editing a reading from January: the March one came later, so it is not
    // what this record has to beat. Comparing against the newest instead would
    // flag every historical entry.
    final january = record(id: 2, odometer: 64200, date: DateTime(2026, 1, 1));
    await pump(
      tester,
      existing: january,
      records: [
        record(id: 1, odometer: 67650, date: DateTime(2026, 3, 1)),
        january,
        record(id: 3, odometer: 61000, date: DateTime(2025, 11, 1)),
      ],
    );

    expect(find.text(en.formOdometerLast('61,000 km')), findsOneWidget);
  });
}
