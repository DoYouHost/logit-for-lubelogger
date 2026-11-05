import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';

void main() {
  group('UnitsSettings base', () {
    for (final base in MeasurementSystem.values) {
      test('${base.name} survives a save and load', () {
        final json = UnitsSettings(base: base).toJson();
        expect(UnitsSettings.fromJson(json).base, base);
      });
    }

    test('an unknown stored base falls back to metric', () {
      expect(
        UnitsSettings.fromJson({'base': 'imperialAu'}).base,
        MeasurementSystem.metric,
      );
    });

    test('only the US imperial base stores gallons', () {
      expect(MeasurementSystem.metric.volumeLabel, 'L');
      expect(MeasurementSystem.imperial.volumeLabel, 'gal');
      expect(MeasurementSystem.imperialUk.volumeLabel, 'L');
    });
  });
}
