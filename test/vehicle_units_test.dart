import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';

VehicleUnits units({
  MeasurementSystem base = MeasurementSystem.metric,
  DistanceUnit distance = DistanceUnit.km,
  FuelEconomyUnit economy = FuelEconomyUnit.l100km,
  bool isElectric = false,
  bool useHours = false,
}) => VehicleUnits(
  UnitsSettings(base: base, distance: distance, economy: economy),
  isElectric: isElectric,
  useHours: useHours,
);

void main() {
  group('odometer round-trip', () {
    test('a display unit matching the stored one never touches the value', () {
      // The pair the drift would be invisible in and the most damaging: every
      // untouched record re-saved through a form would creep by a few metres.
      for (final pair in [
        (MeasurementSystem.metric, DistanceUnit.km),
        (MeasurementSystem.imperial, DistanceUnit.mi),
        (MeasurementSystem.imperialUk, DistanceUnit.mi),
      ]) {
        final u = units(base: pair.$1, distance: pair.$2);
        expect(u.toDisplayDistance(100000), 100000);
        expect(u.toStoredDistance(100000), 100000);
      }
    });

    test('a metric server shown in miles converts both ways', () {
      final u = units(distance: DistanceUnit.mi);
      expect(u.toDisplayDistance(100000), closeTo(62137.1, 0.1));
      expect(u.toStoredDistance(62137), closeTo(99999.8, 0.1));
    });

    test('engine hours are stored and shown as hours', () {
      final u = units(distance: DistanceUnit.mi, useHours: true);
      expect(u.toDisplayDistance(1250), 1250);
      expect(u.toStoredDistance(1250), 1250);
      expect(u.distanceLabel, 'h');
    });
  });

  group('labels', () {
    test('a combustion vehicle keeps the established unit names', () {
      expect(units().economyLabel, 'L/100 km');
      expect(units(economy: FuelEconomyUnit.mpg).economyLabel, 'MPG');
      expect(units(economy: FuelEconomyUnit.mpgUk).economyLabel, 'MPG (UK)');
      expect(units().consumptionLabel, 'L');
      expect(units(base: MeasurementSystem.imperial).consumptionLabel, 'gal');
      expect(units(base: MeasurementSystem.imperialUk).consumptionLabel, 'L');
    });

    test('an electric vehicle reads in kWh', () {
      expect(units(isElectric: true).consumptionLabel, 'kWh');
      expect(units(isElectric: true).economyLabel, 'kWh/100 km');
      expect(
        units(isElectric: true, economy: FuelEconomyUnit.kmPerL).economyLabel,
        'km/kWh',
      );
      // The server spells the miles-based electric unit mi/kWh: a UK gallon
      // says nothing about electricity, so it collapses onto the US one.
      for (final e in [FuelEconomyUnit.mpg, FuelEconomyUnit.mpgUk]) {
        expect(units(isElectric: true, economy: e).economyLabel, 'mi/kWh');
      }
    });

    test('an hour-metered vehicle swaps distance for hours', () {
      expect(units(useHours: true).economyLabel, 'L/100 h');
      expect(
        units(useHours: true, economy: FuelEconomyUnit.mpg).economyLabel,
        'h/gal',
      );
      expect(units(isElectric: true, useHours: true).economyLabel, 'kWh/100 h');
    });
  });

  group('economy', () {
    test('kWh skips the gallon factor a litre would take', () {
      // 626 km on 100 kWh: 16.0 kWh/100 km and 6.26 km/kWh, whatever the
      // economy unit's liquid half would otherwise have done.
      expect(
        units(isElectric: true).economyValue(626, 100),
        closeTo(15.97, 0.01),
      );
      expect(
        units(
          isElectric: true,
          economy: FuelEconomyUnit.kmPerL,
        ).economyValue(626, 100),
        closeTo(6.26, 0.01),
      );
      expect(
        units(
          isElectric: true,
          economy: FuelEconomyUnit.mpg,
        ).economyValue(626, 100),
        closeTo(626 * 0.621371 / 100, 0.01),
      );
    });

    test('the measurement base does not scale kWh', () {
      // An imperial server stores miles and gallons — but a kWh is a kWh, so
      // reading the same numbers as miles may only stretch the distance half.
      const electricKmPerKwh = FuelEconomyUnit.kmPerL;
      final metric = units(
        isElectric: true,
        economy: electricKmPerKwh,
      ).economyValue(626, 100)!;
      final imperial = units(
        base: MeasurementSystem.imperial,
        isElectric: true,
        economy: electricKmPerKwh,
      ).economyValue(626, 100)!;
      expect(
        imperial,
        closeTo(metric * MeasurementSystem.imperial.kmPerUnit, 0.01),
      );
    });

    test('hours are not run through the distance conversion', () {
      // 100 h on 250 L is 250 L/100 h on any server, metric or imperial.
      for (final base in MeasurementSystem.values) {
        expect(
          units(base: base, useHours: true).economyValue(100, 250),
          closeTo(250 * base.litresPerUnit, 1e-9),
        );
      }
    });

    test('labelled economy falls back to a dash', () {
      expect(units().economy(0, 10), '—');
      expect(units().economy(100, 0), '—');
      expect(units().economy(626, 50.37), '8.0 L/100 km');
    });
  });
}
