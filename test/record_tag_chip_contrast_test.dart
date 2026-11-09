import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_filter.dart';
import 'package:material_ui/material_ui.dart';

import 'brand_contrast_test.dart' show contrastRatio;

void main() {
  // The chip's text sits on its own wash over the card, so the ratio is taken
  // against that blend, on the darkest ground the design system audits.
  for (final brightness in Brightness.values) {
    for (final selected in [true, false]) {
      testWidgets('${brightness.name}, selected: $selected: tag is readable', (
        tester,
      ) async {
        final t = DashTokens.resolve(brightness, lubeLoggerBrand);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildDashThemeData(brightness, brand: lubeLoggerBrand),
            home: Scaffold(
              body: RecordTagChip(
                tag: 'workshop',
                selected: selected,
                onTap: () {},
              ),
            ),
          ),
        );
        final text = tester.widget<Text>(find.text('workshop'));
        final wash =
            tester
                    .widget<Container>(
                      find.descendant(
                        of: find.byType(RecordTagChip),
                        matching: find.byType(Container),
                      ),
                    )
                    .decoration!
                as BoxDecoration;
        final worst = t.backgroundGradient.colors
            .map((ground) => Color.alphaBlend(wash.color!, ground))
            .map((fill) => contrastRatio(text.style!.color!, fill))
            .reduce((a, b) => a < b ? a : b);
        expect(worst, greaterThanOrEqualTo(4.5));
      });
    }
  }
}
