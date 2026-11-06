import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/models/gas_record.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/add_fuel_form.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';
import 'package:lubelogger_mobile/providers.dart';

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

/// The fuel form shows price, amount and total cost together: the first two
/// typed in give the third, live, and the third is greyed out meanwhile.
void main() {
  const vehicleId = 1;
  const units = VehicleUnits(UnitsSettings());
  final price = en.formFuelPriceLabel(units.consumptionLabel);
  final fuel = en.formFuelLabel(units.consumptionLabel);
  final cost = en.colCost;

  Future<_CapturingAdapter> pump(
    WidgetTester tester, {
    GasRecord? existing,
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
      ),
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

  bool enabled(WidgetTester tester, String label) =>
      tester.widget<TextFormField>(field(label)).enabled;

  Future<void> typeOdometer(WidgetTester tester) =>
      type(tester, en.formOdometerLabel(units.distanceLabel), '1000');

  testWidgets('amount and cost give the price', (tester) async {
    final adapter = await pump(tester);
    await typeOdometer(tester);
    await type(tester, fuel, '12.5');
    expect(text(tester, price), isEmpty, reason: 'one value is not enough');
    expect([price, cost].map((l) => enabled(tester, l)), [true, true]);
    await type(tester, cost, '50');

    expect(text(tester, price), '4');
    expect(enabled(tester, price), isFalse);
    expect([fuel, cost].map((l) => enabled(tester, l)), [true, true]);
    await save(tester);
    expect(sent(adapter, 'fuelConsumed'), 12.5);
    expect(sent(adapter, 'cost'), 50);
  });

  testWidgets('price and cost give the amount', (tester) async {
    final adapter = await pump(tester);
    await typeOdometer(tester);
    await type(tester, price, '3.459');
    await type(tester, cost, '40');

    expect(text(tester, fuel), '11.564');
    await save(tester);
    expect(sent(adapter, 'fuelConsumed'), 11.564);
    expect(sent(adapter, 'cost'), 40);
  });

  testWidgets('price and amount give the total cost', (tester) async {
    final adapter = await pump(tester);
    await typeOdometer(tester);
    await type(tester, price, '3.459');
    await type(tester, fuel, '11.5');

    expect(text(tester, cost), '39.78');
    await save(tester);
    expect(sent(adapter, 'cost'), 39.78);
    expect(sent(adapter, 'fuelConsumed'), 11.5);
  });

  testWidgets('the calculated value follows every keystroke', (tester) async {
    await pump(tester);
    await type(tester, price, '2');
    await type(tester, fuel, '1');
    expect(text(tester, cost), '2');
    await type(tester, fuel, '10');
    expect(text(tester, cost), '20');
  });

  testWidgets('correcting an input recalculates the same field', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, fuel, '12.5');
    await type(tester, cost, '50');
    expect(text(tester, price), '4');

    await type(tester, cost, '60');
    expect(text(tester, price), '4.8');
    await type(tester, fuel, '10');
    expect(text(tester, price), '6');
    expect(text(tester, cost), '60');
  });

  testWidgets('emptying an input frees the calculated field', (tester) async {
    await pump(tester);
    await type(tester, price, '3');
    await type(tester, fuel, '10');
    expect(text(tester, cost), '30');
    expect(enabled(tester, cost), isFalse);

    await type(tester, price, '');
    expect(text(tester, cost), isEmpty);
    expect(enabled(tester, cost), isTrue);
    expect(text(tester, fuel), '10');

    // The freed field can take the place of the emptied one.
    await type(tester, cost, '50');
    expect(text(tester, price), '5');
    expect(enabled(tester, price), isFalse);
  });

  testWidgets('a free fill-up is a price of zero', (tester) async {
    final adapter = await pump(tester);
    await typeOdometer(tester);
    await type(tester, price, '0');
    await type(tester, fuel, '10');
    await save(tester);

    expect(sent(adapter, 'cost'), 0);
  });

  testWidgets('a total of zero with a price blocks the save', (tester) async {
    final adapter = await pump(tester);
    await typeOdometer(tester);
    await type(tester, price, '3');
    await type(tester, cost, '0');
    await save(tester);

    // No amount can come out of a zero total.
    expect(adapter.captured, isNull);
    expect(find.text(en.validationRequired), findsOneWidget);
  });

  testWidgets('a calculated amount that rounds to zero blocks the save', (
    tester,
  ) async {
    final adapter = await pump(tester);
    await typeOdometer(tester);
    await type(tester, price, '1000');
    await type(tester, cost, '0.0001');
    expect(text(tester, fuel), '0');
    await save(tester);

    expect(adapter.captured, isNull);
    expect(find.text(en.validationNumber), findsOneWidget);
  });

  testWidgets('an untouched record is saved as stored', (tester) async {
    // 25 / 7.777 rounds to a price of 3.215, which would give 7.776 back: the
    // stored pair must not be recalculated from the price.
    final adapter = await pump(
      tester,
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

    expect(text(tester, price), '3.215');
    expect(enabled(tester, price), isFalse);
    await save(tester, label: en.actionSave);
    expect(sent(adapter, 'fuelConsumed'), 7.777);
    expect(sent(adapter, 'cost'), 25);
  });
}
