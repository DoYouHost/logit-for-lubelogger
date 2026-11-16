import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/models/odometer_record.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/add_odometer_form.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
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

/// A form is the one place the app writes a distance back, so it is the only
/// place a display unit can corrupt the odometer. These drive the real form.
void main() {
  const vehicleId = 1;

  OdometerRecord record(double odometer) => OdometerRecord(
    id: 7,
    date: DateTime(2026, 4, 5),
    odometer: odometer,
    initialOdometer: 0,
    notes: '',
    tags: '',
  );

  Future<_CapturingAdapter> pump(
    WidgetTester tester, {
    required VehicleUnits units,
    OdometerRecord? existing,
  }) async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://server'))
      ..httpClientAdapter = adapter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiclesRepositoryProvider.overrideWithValue(VehiclesRepository(dio)),
          vehicleUnitsProvider.overrideWith((ref, id) => units),
          extraFieldTemplatesProvider.overrideWith((ref) async => null),
          // The form reads the vehicle's other readings to hint at the last one
          // and warn when a new one goes below it. Left to fetch, that read
          // would go through this adapter and be the request the assertions
          // pick up.
          odometerRecordsProvider.overrideWith((ref, id) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, en.actionSave));
    await tester.pumpAndSettle();
  }

  String odometerField(WidgetTester tester) => tester
      .widget<TextFormField>(find.byType(TextFormField).first)
      .controller!
      .text;

  double sentOdometer(_CapturingAdapter adapter) => double.parse(
    (adapter.captured!.data as Map<String, dynamic>)['odometer'] as String,
  );

  testWidgets('a metric reading edited in miles is stored back in km', (
    tester,
  ) async {
    final adapter = await pump(
      tester,
      units: const VehicleUnits(UnitsSettings(distance: DistanceUnit.mi)),
      existing: record(100000),
    );

    // The list shows this record as 62,137 mi; the field has to agree with it,
    // not show the raw 100000 under a "mi" label.
    expect(odometerField(tester), '62137');
    expect(find.text(en.formOdometerLabel('mi')), findsOneWidget);

    await save(tester);
    // Back within a mile of where it started, rather than 62,137 km.
    expect(sentOdometer(adapter), closeTo(100000, 1609));
  });

  testWidgets('an untouched reading is saved byte-for-byte', (tester) async {
    final adapter = await pump(
      tester,
      units: const VehicleUnits(UnitsSettings()),
      existing: record(123456),
    );

    expect(odometerField(tester), '123456');
    await save(tester);
    expect(sentOdometer(adapter), 123456);
  });

  testWidgets('an hour-metered vehicle neither converts nor says km', (
    tester,
  ) async {
    final adapter = await pump(
      tester,
      units: const VehicleUnits(
        UnitsSettings(distance: DistanceUnit.mi),
        useHours: true,
      ),
      existing: record(1250),
    );

    expect(odometerField(tester), '1250');
    expect(find.text(en.formOdometerLabel('h')), findsOneWidget);
    await save(tester);
    expect(sentOdometer(adapter), 1250);
  });
}
