import 'package:intl/intl.dart';

// User-selectable display units. LubeLogger's API does NOT expose (nor let us
// read) the units the server stores values in — its fuel-economy endpoints only
// take useMPG/useUKMPG as request params and never convert the distance base.
// So the app keeps two independent settings: [MeasurementSystem] (how to
// interpret the raw stored numbers) and the display units below. Raw values are
// normalized to a canonical base (km, litres) via the measurement system, then
// converted to the chosen display unit. Currency is a pure symbol relabel —
// amounts are never converted, matching how LubeLogger itself works.

/// How the LubeLogger server stores raw distance/volume values. [imperial]
/// assumes miles + US gallons. Note: when UK MPG is selected, LubeLogger's
/// "Use UK MPG Calculation" stores fuel quantity in litres and distance in miles;
enum MeasurementSystem {
  metric(kmPerUnit: 1, litresPerUnit: 1),
  imperial(kmPerUnit: 1.609344, litresPerUnit: 3.785411784),
  imperialUk(kmPerUnit: 1.609344, litresPerUnit: 1);

  const MeasurementSystem({
    required this.kmPerUnit,
    required this.litresPerUnit,
  });

  /// Kilometres per one stored distance unit.
  final double kmPerUnit;

  /// Litres per one stored volume unit.
  final double litresPerUnit;

  /// Short label for the stored volume unit (litres vs US gallons) — used for
  /// the fuel table's price-per-volume column header.
  String get volumeLabel => this == MeasurementSystem.imperial ? 'gal' : 'L';
}

/// Currency symbol shown next to money values. [auto] defers to the server's
/// `currencySymbol` from `GET /api/info`; the others force a fixed symbol.
enum CurrencyOption {
  auto(null),
  usd(r'$'),
  eur('€'),
  gbp('£'),
  pln('zł');

  const CurrencyOption(this.fixedSymbol);

  /// The forced symbol, or null for [auto] (resolved against the server info).
  final String? fixedSymbol;
}

/// Distance / odometer unit, sized in kilometres. Sizing it this way (rather
/// than as a factor off km) makes a display unit that matches
/// [MeasurementSystem]'s own divide out to exactly 1, so a form can show a
/// stored odometer and write it back untouched.
enum DistanceUnit {
  km('km', 1),
  mi('mi', 1.609344);

  const DistanceUnit(this.label, this.kmPerUnit);

  final String label;
  final double kmPerUnit;
}

/// Fuel-economy readout unit. Labels use conventional notation (not localized).
enum FuelEconomyUnit {
  l100km('L/100 km'),
  mpg('MPG'),
  mpgUk('MPG (UK)'),
  kmPerL('km/L');

  const FuelEconomyUnit(this.label);

  final String label;

  /// True when a smaller number means better economy (consumption units like
  /// L/100 km), false for distance-per-fuel units (MPG, km/L). Drives the
  /// efficiency coloring of the monthly-mileage bars.
  bool get lowerIsBetter => this == FuelEconomyUnit.l100km;
}

/// Field order for displayed dates. [pattern] holds the `intl` tokens and
/// [display] the uppercase notation, both split into parts so the separator can
/// be chosen independently ([DateSeparator]). Locale-independent, for a
/// predictable readout.
enum DateOrder {
  dmy(['dd', 'MM', 'yyyy'], ['DD', 'MM', 'YYYY']),
  mdy(['MM', 'dd', 'yyyy'], ['MM', 'DD', 'YYYY']),
  ymd(['yyyy', 'MM', 'dd'], ['YYYY', 'MM', 'DD']);

  const DateOrder(this.pattern, this.display);

  final List<String> pattern;
  final List<String> display;

  /// Uppercase notation with [sep] between fields, e.g. `DD/MM/YYYY`.
  String labelWith(DateSeparator sep) => display.join(sep.value);

  String format(DateTime date, DateSeparator sep) =>
      DateFormat(pattern.join(sep.value)).format(date);
}

/// Separator between date fields.
enum DateSeparator {
  slash('/'),
  dash('-'),
  dot('.');

  const DateSeparator(this.value);

  final String value;
}

/// The user's display-unit preferences. Persisted locally (SharedPreferences),
/// independent of the server's own locale settings.
class UnitsSettings {
  const UnitsSettings({
    this.base = MeasurementSystem.metric,
    this.currency = CurrencyOption.auto,
    this.distance = DistanceUnit.km,
    this.economy = FuelEconomyUnit.l100km,
    this.dateOrder = DateOrder.dmy,
    this.dateSeparator = DateSeparator.slash,
  });

  factory UnitsSettings.fromJson(Map<String, dynamic> json) => UnitsSettings(
    base:
        _byName(MeasurementSystem.values, json['base']) ??
        MeasurementSystem.metric,
    currency:
        _byName(CurrencyOption.values, json['currency']) ?? CurrencyOption.auto,
    distance: _byName(DistanceUnit.values, json['distance']) ?? DistanceUnit.km,
    economy:
        _byName(FuelEconomyUnit.values, json['economy']) ??
        FuelEconomyUnit.l100km,
    dateOrder: _byName(DateOrder.values, json['dateOrder']) ?? DateOrder.dmy,
    dateSeparator:
        _byName(DateSeparator.values, json['dateSeparator']) ??
        DateSeparator.slash,
  );

  /// How the server stores raw values (metric km/L vs imperial mi/US-gal).
  final MeasurementSystem base;
  final CurrencyOption currency;
  final DistanceUnit distance;
  final FuelEconomyUnit economy;
  final DateOrder dateOrder;
  final DateSeparator dateSeparator;

  /// Formats [date] with the chosen field order and separator.
  String formatDate(DateTime date) => dateOrder.format(date, dateSeparator);

  Map<String, dynamic> toJson() => {
    'base': base.name,
    'currency': currency.name,
    'distance': distance.name,
    'economy': economy.name,
    'dateOrder': dateOrder.name,
    'dateSeparator': dateSeparator.name,
  };

  UnitsSettings copyWith({
    MeasurementSystem? base,
    CurrencyOption? currency,
    DistanceUnit? distance,
    FuelEconomyUnit? economy,
    DateOrder? dateOrder,
    DateSeparator? dateSeparator,
  }) => UnitsSettings(
    base: base ?? this.base,
    currency: currency ?? this.currency,
    distance: distance ?? this.distance,
    economy: economy ?? this.economy,
    dateOrder: dateOrder ?? this.dateOrder,
    dateSeparator: dateSeparator ?? this.dateSeparator,
  );

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
