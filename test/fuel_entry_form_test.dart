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

/// The fuel form shows price, amount and total cost together: two of them give
/// the third, live, and the third is greyed out meanwhile. A new record opens
/// with the pair picked in Settings first and its calculated field last.
void main() {
  const vehicleId = 1;
  const units = VehicleUnits(UnitsSettings());
  final price = en.formFuelPriceLabel(units.consumptionLabel);
  final fuel = en.formFuelLabel(units.consumptionLabel);
  final cost = en.colCost;

  late SharedPreferences prefs;

  /// [mode] is the Settings pair and [storedMode] a raw stored name; with
  /// neither the preference is unset.
  Future<_CapturingAdapter> pump(
    WidgetTester tester, {
    GasRecord? existing,
    FuelEntryMode? mode,
    String? storedMode,
  }) async {
    SharedPreferences.setMockInitialValues({
      'fuel_entry_mode': ?(storedMode ?? mode?.name),
    });
    prefs = await SharedPreferences.getInstance();
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://server'))
      ..httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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

  bool focused(WidgetTester tester, String label) => tester
      .widget<EditableText>(
        find.descendant(of: field(label), matching: find.byType(EditableText)),
      )
      .focusNode
      .hasFocus;

  /// The labels of price, amount and cost, top to bottom.
  List<String> order(WidgetTester tester) => [price, fuel, cost]
    ..sort(
      (a, b) => tester
          .getTopLeft(field(a))
          .dy
          .compareTo(tester.getTopLeft(field(b)).dy),
    );

  Future<void> typeOdometer(WidgetTester tester) =>
      type(tester, en.formOdometerLabel(units.distanceLabel), '1000');

  testWidgets('amount and cost give the price', (tester) async {
    final adapter = await pump(tester);
    expect(order(tester), [fuel, cost, price]);
    await typeOdometer(tester);
    await type(tester, fuel, '12.5');
    expect(text(tester, price), isEmpty, reason: 'one value is not enough');
    expect(enabled(tester, price), isTrue, reason: 'the pair can still change');
    await type(tester, cost, '50');

    expect(text(tester, price), '4');
    expect(enabled(tester, price), isFalse);
    expect([fuel, cost].map((l) => enabled(tester, l)), [true, true]);
    await save(tester);
    expect(sent(adapter, 'fuelConsumed'), 12.5);
    expect(sent(adapter, 'cost'), 50);
  });

  testWidgets('price and cost give the amount', (tester) async {
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndCost);
    expect(order(tester), [price, cost, fuel]);
    await typeOdometer(tester);
    await type(tester, price, '3.459');
    await type(tester, cost, '40');

    expect(text(tester, fuel), '11.564');
    await save(tester);
    expect(sent(adapter, 'fuelConsumed'), 11.564);
    expect(sent(adapter, 'cost'), 40);
  });

  testWidgets('price and amount give the total cost', (tester) async {
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndFuel);
    expect(order(tester), [price, fuel, cost]);
    await typeOdometer(tester);
    await type(tester, price, '3.459');
    await type(tester, fuel, '11.5');

    expect(text(tester, cost), '39.78');
    await save(tester);
    expect(sent(adapter, 'cost'), 39.78);
    expect(sent(adapter, 'fuelConsumed'), 11.5);
  });

  testWidgets('the calculated value follows every keystroke', (tester) async {
    await pump(tester, mode: FuelEntryMode.priceAndFuel);
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
    await pump(tester, mode: FuelEntryMode.priceAndFuel);
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
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndFuel);
    await typeOdometer(tester);
    await type(tester, price, '0');
    await type(tester, fuel, '10');
    await save(tester);

    expect(sent(adapter, 'cost'), 0);
  });

  testWidgets('a total of zero with a price blocks the save', (tester) async {
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndCost);
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
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndCost);
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
    // stored pair must not be recalculated from the price, whatever pair
    // Settings asks a new record for.
    final adapter = await pump(
      tester,
      mode: FuelEntryMode.priceAndCost,
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

    expect(order(tester), [fuel, cost, price]);
    expect(text(tester, price), '3.215');
    expect(enabled(tester, price), isFalse);
    expect([fuel, cost].map((l) => enabled(tester, l)), [true, true]);
    await save(tester, label: en.actionSave);
    expect(sent(adapter, 'fuelConsumed'), 7.777);
    expect(sent(adapter, 'cost'), 25);
  });

  testWidgets('an unknown stored pair opens like the default', (tester) async {
    await pump(tester, storedMode: 'from-a-newer-version');
    expect(order(tester), [fuel, cost, price]);
  });

  testWidgets('next walks the pair and skips the calculated field', (
    tester,
  ) async {
    await pump(tester, mode: FuelEntryMode.priceAndCost);
    // The key the keyboard shows; receiveAction below works without it.
    for (final label in [price, cost, fuel]) {
      final input = tester.widget<EditableText>(
        find.descendant(of: field(label), matching: find.byType(EditableText)),
      );
      expect(input.textInputAction, TextInputAction.next, reason: label);
    }
    await type(tester, price, '3');
    expect(focused(tester, price), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(tester, cost), isTrue);

    await type(tester, cost, '30');
    expect(enabled(tester, fuel), isFalse);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(focused(tester, fuel), isFalse);
    expect(focused(tester, cost), isFalse, reason: 'focus moved on');
  });

  testWidgets('clearing a typo keeps the Settings pair', (tester) async {
    await pump(tester);
    await type(tester, fuel, '9');
    await type(tester, fuel, '');
    await type(tester, fuel, '12.5');
    await type(tester, cost, '50');

    expect(text(tester, price), '4');
    expect(enabled(tester, price), isFalse);
  });

  testWidgets('retyping an input after clearing it keeps the pair', (
    tester,
  ) async {
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndCost);
    await typeOdometer(tester);
    await type(tester, cost, '40');
    await type(tester, cost, '');
    await type(tester, cost, '40');
    await save(tester);

    // Price is still the missing half of the pair, so the error is its own.
    expect(adapter.captured, isNull);
    expect(
      find.descendant(
        of: field(price),
        matching: find.text(en.validationRequired),
      ),
      findsOneWidget,
    );
    await type(tester, price, '4');
    expect(text(tester, fuel), '10');
    expect(enabled(tester, fuel), isFalse);
  });

  testWidgets('a one-off pair leaves the setting alone', (tester) async {
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndCost);
    await typeOdometer(tester);
    await type(tester, cost, '40');
    expect(enabled(tester, fuel), isTrue, reason: 'price is still empty');
    await type(tester, fuel, '10');

    expect(text(tester, price), '4');
    expect(enabled(tester, price), isFalse);
    await save(tester);
    expect(sent(adapter, 'fuelConsumed'), 10);
    expect(prefs.getString('fuel_entry_mode'), 'priceAndCost');
  });

  testWidgets('an empty price of the Settings pair is required', (
    tester,
  ) async {
    final adapter = await pump(tester, mode: FuelEntryMode.priceAndCost);
    await typeOdometer(tester);
    await type(tester, cost, '40');
    await save(tester);

    expect(adapter.captured, isNull);
    expect(
      find.descendant(
        of: field(price),
        matching: find.text(en.validationRequired),
      ),
      findsOneWidget,
    );
  });
}
