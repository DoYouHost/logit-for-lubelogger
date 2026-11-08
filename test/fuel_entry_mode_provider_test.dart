import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/fuel_entry_mode.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> container([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('price is calculated until the user picks another field', () async {
    final c = await container();
    expect(c.read(fuelEntryModeProvider), FuelEntryMode.costAndFuel);

    await c
        .read(fuelEntryModeProvider.notifier)
        .set(FuelEntryMode.priceAndCost);
    expect(c.read(fuelEntryModeProvider), FuelEntryMode.priceAndCost);

    final reloaded = await container({'fuel_entry_mode': 'priceAndCost'});
    expect(reloaded.read(fuelEntryModeProvider), FuelEntryMode.priceAndCost);
  });

  test('an unknown stored mode falls back to the default', () async {
    final c = await container({'fuel_entry_mode': 'from-a-newer-version'});
    expect(c.read(fuelEntryModeProvider), FuelEntryMode.costAndFuel);
  });
}
