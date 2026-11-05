/// Which two of fuel price, total cost and fuel amount the user types in the
/// fuel form; the third is calculated.
enum FuelEntryMode {
  /// Total cost and fuel amount typed, price calculated (the original form).
  costAndFuel,

  /// Price and total cost typed, fuel amount calculated.
  priceAndCost,

  /// Price and fuel amount typed, total cost calculated.
  priceAndFuel;

  static FuelEntryMode? byName(String name) {
    for (final mode in values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}

/// Half-up rounding. The nudge keeps ties like 2.01 * 0.5 = 1.005, which
/// binary floating point stores a hair low, from rounding down.
double _round(double value, int places) {
  final factor = _pow10[places];
  return (value * factor + 1e-9).round() / factor;
}

const _pow10 = [1.0, 10.0, 100.0, 1000.0];

/// The value [mode] derives from the two typed ones, or `null` while an input
/// is missing or cannot give a meaningful result (a zero divisor, or a fuel
/// amount the server would refuse because it is not above zero). Fuel and cost
/// are what the record stores, so they are rounded to what a pump and a receipt
/// show (3 and 2 places); the price is derived only in [FuelEntryMode.costAndFuel],
/// where the form keeps it hidden until the user switches to a mode that types it.
double? deriveFuelEntry(
  FuelEntryMode mode, {
  double? price,
  double? cost,
  double? fuel,
}) {
  switch (mode) {
    case FuelEntryMode.costAndFuel:
      if (cost == null || fuel == null || fuel <= 0) return null;
      return _round(cost / fuel, 3);
    case FuelEntryMode.priceAndCost:
      if (price == null || cost == null || price <= 0 || cost <= 0) return null;
      return _round(cost / price, 3);
    case FuelEntryMode.priceAndFuel:
      if (price == null || fuel == null || fuel <= 0) return null;
      return _round(price * fuel, 2);
  }
}
