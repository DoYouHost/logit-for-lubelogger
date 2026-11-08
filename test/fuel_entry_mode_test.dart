// Fuel form data entry modes: which of price / cost / fuel is calculated.

import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/fuel_entry_mode.dart';

void main() {
  group('costAndFuel derives the price', () {
    test('divides cost by fuel', () {
      expect(
        deriveFuelEntry(FuelEntryMode.costAndFuel, cost: 50, fuel: 12.5),
        4,
      );
    });

    test('rounds to three places', () {
      expect(
        deriveFuelEntry(FuelEntryMode.costAndFuel, cost: 10, fuel: 3),
        3.333,
      );
    });

    test('has no price for zero fuel or a missing input', () {
      expect(
        deriveFuelEntry(FuelEntryMode.costAndFuel, cost: 10, fuel: 0),
        isNull,
      );
      expect(deriveFuelEntry(FuelEntryMode.costAndFuel, cost: 10), isNull);
      expect(deriveFuelEntry(FuelEntryMode.costAndFuel, fuel: 10), isNull);
    });
  });

  group('priceAndCost derives the fuel amount', () {
    test('divides cost by price, rounded to three places', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndCost, price: 3.459, cost: 40),
        11.564,
      );
    });

    test('has no amount for a zero price or a missing input', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndCost, price: 0, cost: 40),
        isNull,
      );
      expect(deriveFuelEntry(FuelEntryMode.priceAndCost, price: 3), isNull);
      expect(deriveFuelEntry(FuelEntryMode.priceAndCost, cost: 40), isNull);
    });

    test('a zero total gives no amount, since the server needs fuel > 0', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndCost, price: 3, cost: 0),
        isNull,
      );
    });
  });

  group('priceAndFuel derives the total cost', () {
    test('multiplies price by fuel, rounded to two places', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndFuel, price: 3.459, fuel: 11.5),
        39.78,
      );
    });

    test('a free fill-up costs zero', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndFuel, price: 0, fuel: 10),
        0,
      );
    });

    test('zero fuel gives no total, since the server needs fuel > 0', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndFuel, price: 3, fuel: 0),
        isNull,
      );
    });

    test('has no total while an input is missing', () {
      expect(deriveFuelEntry(FuelEntryMode.priceAndFuel, price: 3), isNull);
      expect(deriveFuelEntry(FuelEntryMode.priceAndFuel, fuel: 3), isNull);
    });
  });

  group('halves round up despite binary floating point', () {
    // 2.01 * 0.5 and 20.035 / 10 sit a hair below the tie in IEEE 754.
    test('cost to the cent', () {
      expect(
        deriveFuelEntry(FuelEntryMode.priceAndFuel, price: 2.01, fuel: 0.5),
        1.01,
      );
    });

    test('price and fuel to the thousandth', () {
      expect(
        deriveFuelEntry(FuelEntryMode.costAndFuel, cost: 20.035, fuel: 10),
        2.004,
      );
    });
  });

  test('byName round-trips every mode and rejects an unknown one', () {
    for (final mode in FuelEntryMode.values) {
      expect(FuelEntryMode.byName(mode.name), mode);
    }
    expect(FuelEntryMode.byName('nonsense'), isNull);
    expect(FuelEntryMode.byName(''), isNull);
  });
}
