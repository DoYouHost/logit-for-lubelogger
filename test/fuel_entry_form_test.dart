import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/fuel_entry_mode.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/models/gas_record.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/add_fuel_form.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final en = AppLocalizationsEn();

class _CapturingAdapter implements HttpClientAdapter {
  /// The last write; reads such as the server info probe are not the point.
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method != 'GET') captured = options;
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

/// The fuel form's data entry modes, driven through the real form.
void main() {
  const vehicleId = 1;
  const units = VehicleUnits(UnitsSettings());
  final price = en.formFuelPriceLabel(units.consumptionLabel);
  final fuel = en.formFuelLabel(units.consumptionLabel);
  final cost = en.colCost;

  late ProviderContainer container;

  Future<_CapturingAdapter> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    GasRecord? existing,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://server'))
      ..httpClientAdapter = adapter;
    final scope = ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        vehiclesRepositoryProvider.overrideWithValue(VehiclesRepository(dio)),
        vehicleUnitsProvider.overrideWith((ref, id) => units),
        extraFieldTemplatesProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showAddFuelForm(context, vehicleId, existing: existing),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(scope);
    container = ProviderScope.containerOf(
      tester.element(find.byType(ElevatedButton)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return adapter;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  String text(WidgetTester tester, String label) =>
      tester.widget<TextFormField>(field(label)).controller!.text;

  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.ensureVisible(field(label));
    await tester.enterText(field(label), value);
    await tester.pump();
  }

  Future<void> pickMode(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, {String? label}) async {
    final button = find.widgetWithText(FilledButton, label ?? en.actionAdd);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// A field of the request body; the wire format is a string, `50.0`.
  double sent(_CapturingAdapter adapter, String key) => double.parse(
    (adapter.captured!.data as Map<String, dynamic>)[key] as String,
  );

  Future<void> typeOdometer(WidgetTester tester) =>
      type(tester, en.formOdometerLabel(units.distanceLabel), '1000');

  testWidgets('the default mode has no price field and sends what was typed', (
    tester,
  ) async {
    final adapter = await pump(tester);
    expect(field(price), findsNothing);

    await typeOdometer(tester);
    await type(tester, fuel, '12.5');
    await type(tester, cost, '50');
    await save(tester);

    expect(sent(adapter, 'fuelConsumed'), 12.5);
    expect(sent(adapter, 'cost'), 50);
  });

  testWidgets('price and cost calculate the fuel amount', (tester) async {
    final adapter = await pump(tester);
    await pickMode(tester, en.formEntryModePriceCost);

    await typeOdometer(tester);
    await type(tester, price, '3.459');
    await type(tester, cost, '40');

    expect(text(tester, fuel), '11.564');
    expect(tester.widget<TextFormField>(field(fuel)).enabled, isFalse);

    await save(tester);
    expect(sent(adapter, 'fuelConsumed'), 11.564);
    expect(sent(adapter, 'cost'), 40);
  });

  testWidgets('price and amount calculate the total cost', (tester) async {
    final adapter = await pump(tester);
    await pickMode(tester, en.formEntryModePriceAmount);

    await typeOdometer(tester);
    await type(tester, price, '3.459');
    await type(tester, fuel, '11.5');

    expect(text(tester, cost), '39.78');
    await save(tester);
    expect(sent(adapter, 'cost'), 39.78);
    expect(sent(adapter, 'fuelConsumed'), 11.5);
  });

  testWidgets('a zero total in price and cost mode blocks the save', (
    tester,
  ) async {
    final adapter = await pump(tester);
    await pickMode(tester, en.formEntryModePriceCost);

    await typeOdometer(tester);
    await type(tester, price, '3');
    await type(tester, cost, '0');
    await save(tester);

    expect(adapter.captured, isNull);
    // The typed total is the one that is wrong; the empty amount only follows.
    expect(find.text(en.validationNumber), findsOneWidget);
    expect(find.text(en.validationRequired), findsOneWidget);
  });

  testWidgets('a calculated amount that rounds to zero blocks the save', (
    tester,
  ) async {
    final adapter = await pump(tester);
    await pickMode(tester, en.formEntryModePriceCost);

    await typeOdometer(tester);
    await type(tester, price, '1000');
    await type(tester, cost, '0.0001');
    expect(text(tester, fuel), '0');
    await save(tester);

    expect(adapter.captured, isNull);
    // Both typed values are valid; the error is on the calculated field.
    expect(find.text(en.validationNumber), findsOneWidget);
  });

  testWidgets('switching modes keeps what was typed and is remembered', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, fuel, '12.5');
    await type(tester, cost, '50');

    await pickMode(tester, en.formEntryModePriceAmount);
    expect(text(tester, fuel), '12.5');
    expect(text(tester, price), '4', reason: 'the price it was calculated as');
    expect(text(tester, cost), '50', reason: '4 * 12.5');
    expect(container.read(fuelEntryModeProvider), FuelEntryMode.priceAndFuel);
  });

  testWidgets('the form opens on the remembered mode', (tester) async {
    await pump(tester, prefs: {'fuel_entry_mode': 'priceAndCost'});
    expect(field(price), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<FuelEntryMode>>(
            find.byType(SegmentedButton<FuelEntryMode>),
          )
          .selected,
      {FuelEntryMode.priceAndCost},
    );
  });

  testWidgets('an untouched record is saved as stored, whatever the mode', (
    tester,
  ) async {
    // 25 / 7.777 rounds to a price of 3.215, which gives 7.776 back: opening
    // the record in the remembered mode would have rewritten the fuel.
    final adapter = await pump(
      tester,
      prefs: {'fuel_entry_mode': 'priceAndCost'},
      existing: GasRecord(
        id: 7,
        date: DateTime(2026, 4, 5),
        odometer: 1000,
        fuelConsumed: 7.777,
        cost: 25,
        isFillToFull: true,
        missedFuelUp: false,
      ),
    );

    expect(text(tester, fuel), '7.777');
    expect(text(tester, cost), '25');
    await save(tester, label: en.actionSave);
    expect(sent(adapter, 'fuelConsumed'), 7.777);
    expect(sent(adapter, 'cost'), 25);
  });
}
