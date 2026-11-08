import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_tabs.dart';

void main() {
  // The palette itself is audited in dash_ui; the accent is ours, so this is
  // the only place a change to it can fail.
  test('the brand accent passes the design system\'s contrast audit', () {
    expect(dashContrastAudit(lubeLoggerBrand), isEmpty);
  });

  // No token covers a positive status, so the app's own green is held to the
  // same floor the palette's inks are.
  for (final brightness in Brightness.values) {
    test('${brightness.name}: the equipped headline is readable', () {
      final t = DashTokens.resolve(brightness, lubeLoggerBrand);
      expect(dashWorstContrast(equippedInk(t), t), greaterThanOrEqualTo(4.5));
    });
  }
}
