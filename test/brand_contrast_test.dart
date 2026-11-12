import 'dart:math' as math;

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

  // Large text (the 30 sp wordmark) needs 3:1 on every stop of the background
  // gradient, the palest-contrast one included.
  for (final brightness in Brightness.values) {
    test('${brightness.name}: the wordmark clears 3:1 on the background', () {
      final t = DashTokens.resolve(brightness, lubeLoggerBrand);
      for (final stop in t.backgroundGradient.colors) {
        expect(
          contrastRatio(lubeLoggerWordmarkInk(t), stop),
          greaterThanOrEqualTo(3.0),
          reason: 'wordmark on ${stop.toARGB32().toRadixString(16)}',
        );
      }
    });
  }
}

/// WCAG 2.1 contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final (x, y) = (lum(a), lum(b));
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}
