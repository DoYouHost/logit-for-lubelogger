import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/formatters.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';

void main() {
  group('Formatters.fuelEconomyValue', () {
    // Real record from the live server: 626 km on 50.370 L, whose server-computed
    // metric fuel economy is 8.0463 L/100 km. Verifies our conversions line up.
    const distanceKm = 626.0;
    const litres = 50.370;
    const metric = MeasurementSystem.metric;

    test('L/100km matches the server-computed value', () {
      final v = Formatters.fuelEconomyValue(
        distanceKm,
        litres,
        metric,
        FuelEconomyUnit.l100km,
      );
      expect(v, closeTo(8.0463, 0.001));
    });

    test('km/L is distance over volume', () {
      final v = Formatters.fuelEconomyValue(
        distanceKm,
        litres,
        metric,
        FuelEconomyUnit.kmPerL,
      );
      expect(v, closeTo(12.428, 0.001));
    });

    test('US and UK MPG convert from the metric base', () {
      final us = Formatters.fuelEconomyValue(
        distanceKm,
        litres,
        metric,
        FuelEconomyUnit.mpg,
      )!;
      final uk = Formatters.fuelEconomyValue(
        distanceKm,
        litres,
        metric,
        FuelEconomyUnit.mpgUk,
      )!;
      // 8.05 L/100km ≈ 29.2 US MPG ≈ 35.1 UK MPG.
      expect(us, closeTo(29.23, 0.1));
      expect(uk, closeTo(35.10, 0.1));
      expect(uk, greaterThan(us)); // UK gallon is larger.
    });

    test('imperial base treats raw values as miles + US gallons', () {
      // Same raw numbers, but interpreted as 626 mi on 50.37 US gal.
      final mpg = Formatters.fuelEconomyValue(
        626,
        50.370,
        MeasurementSystem.imperial,
        FuelEconomyUnit.mpg,
      );
      expect(mpg, closeTo(626 / 50.370, 0.001)); // raw miles / raw gallons
    });

    test('imperialUk base matches the server\'s own UK MPG', () {
      // Same raw numbers as a UK MPG server stores them: 626 mi on 50.37 L.
      final mpg = Formatters.fuelEconomyValue(
        626,
        50.370,
        MeasurementSystem.imperialUk,
        FuelEconomyUnit.mpgUk,
      );
      // GasHelper.GetGasRecordViewModels divides the litres by 4.546.
      expect(mpg, closeTo(626 / (50.370 / 4.546), 0.01));
    });

    test('imperialUk base reads the litres as-is for L/100 km', () {
      final v = Formatters.fuelEconomyValue(
        626,
        50.370,
        MeasurementSystem.imperialUk,
        FuelEconomyUnit.l100km,
      );
      expect(v, closeTo(50.370 / (626 * 1.609344) * 100, 0.001));
    });

    test('returns null for zero distance or volume', () {
      expect(
        Formatters.fuelEconomyValue(0, 10, metric, FuelEconomyUnit.l100km),
        isNull,
      );
      expect(
        Formatters.fuelEconomyValue(100, 0, metric, FuelEconomyUnit.l100km),
        isNull,
      );
    });
  });

  group('Formatters.distance', () {
    test('metric base shows km as-is and converts to mi', () {
      expect(
        Formatters.distance(320775, MeasurementSystem.metric, DistanceUnit.km),
        '320,775 km',
      );
      expect(
        Formatters.distance(320775, MeasurementSystem.metric, DistanceUnit.mi),
        '199,320 mi',
      );
    });

    test('imperial base treats the raw value as miles', () {
      expect(
        Formatters.distance(
          100000,
          MeasurementSystem.imperial,
          DistanceUnit.mi,
        ),
        '100,000 mi',
      );
    });

    test('imperialUk base treats the raw value as miles', () {
      expect(
        Formatters.distance(
          100000,
          MeasurementSystem.imperialUk,
          DistanceUnit.mi,
        ),
        '100,000 mi',
      );
    });
  });

  group('Formatters.currency', () {
    // Every locale is restored to the intl default so later groups (and other
    // test files sharing the isolate) keep the en_US readouts they expect.
    tearDown(() => Formatters.useLocale(null));

    /// The amount's digits, separators and all, with the symbol stripped off.
    String amountOf(String formatted, String symbol) =>
        formatted.replaceAll(symbol, '').trim();

    test('the currency decides the layout, not the device locale', () {
      // Same amount, same two symbols, opposite device locales: each currency
      // keeps its own side and separators either way.
      for (final device in ['en_US', 'pl_PL']) {
        Formatters.useLocale(device);
        expect(
          Formatters.currency(5728.01, r'$'),
          r'$5,728.01',
          reason: 'device $device',
        );
        final zloty = Formatters.currency(5728.01, 'zł');
        expect(zloty.endsWith('zł'), isTrue, reason: '$device: $zloty');
        // Polish separators: comma decimal, non-breaking-space grouping.
        expect(
          amountOf(zloty, 'zł'),
          '5\u00a0728,01',
          reason: 'device $device',
        );
      }
    });

    test('an ISO code is recognized like its symbol', () {
      Formatters.useLocale('en_US');
      expect(
        amountOf(Formatters.currency(5728.01, 'PLN'), 'PLN'),
        '5\u00a0728,01',
      );
      expect(Formatters.currency(5728.01, 'USD'), 'USD5,728.01');
    });

    test('an unlisted currency follows the device locale', () {
      Formatters.useLocale('pl_PL');
      expect(amountOf(Formatters.currency(5728.01, '¤'), '¤'), '5\u00a0728,01');
      Formatters.useLocale('en_US');
      expect(amountOf(Formatters.currency(5728.01, '¤'), '¤'), '5,728.01');
    });

    test('an unknown device locale falls back instead of throwing', () {
      Formatters.useLocale('zz_ZZ');
      expect(Formatters.currency(1.5, '¤'), contains('1.50'));
    });

    test('rounds to the nearest whole unit', () {
      expect(Formatters.currency(5728.005, r'$'), r'$5,728.01');
      expect(Formatters.currencyRounded(1234.56, r'$'), r'$1,235');
    });
  });
}
