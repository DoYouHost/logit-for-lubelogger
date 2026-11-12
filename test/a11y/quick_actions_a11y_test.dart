import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/quick_actions/vehicle_picker_sheet.dart';
import 'package:lubelogger_mobile/providers.dart';

import 'a11y_harness.dart';

/// The sheet a launcher shortcut opens when the garage holds more than one
/// vehicle. The shortcut itself arrives from the platform, which a widget test
/// has no way to send; the sheet and the forms it leads to are what a person
/// sees, and the forms have their own surfaces in `record_forms_a11y_test.dart`.
Future<void> _openPicker(WidgetTester tester, {int? only}) async {
  final garage = await a11yContainer(tester).read(garageProvider.future);
  final vehicles = only == null ? garage : garage.take(only).toList();
  showVehiclePicker(a11yContext(tester), vehicles).ignore();
  await a11ySettle(tester, const Duration(milliseconds: 700));
}

void main() {
  a11ySurface(
    'vehicle picker of a shortcut',
    arrange: _openPicker,
    shows: find.text(pl.quickActionSelectVehicle),
  );

  a11ySurface(
    'vehicle picker with two vehicles',
    arrange: (tester) => _openPicker(tester, only: 2),
    shows: find.text(pl.quickActionSelectVehicle),
  );
}
