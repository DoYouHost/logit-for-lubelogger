import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_filter.dart';
import 'package:material_ui/material_ui.dart';

import 'brand_contrast_test.dart' show contrastRatio;

void main() {
  // The chip's text sits on its own wash, so the ratio is taken against that
  // blend over each stop of the page background gradient, bare and under the
  // sub-card a record card draws.
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
        // On the page, or in a record card, on the sub-card over it.
        final fills = [
          for (final ground in t.backgroundGradient.colors) ...[
            Color.alphaBlend(wash.color!, ground),
            Color.alphaBlend(wash.color!, Color.alphaBlend(t.subCard, ground)),
          ],
        ];
        double worst(Color ink) => fills
            .map((fill) => contrastRatio(ink, fill))
            .reduce((a, b) => a < b ? a : b);
        expect(worst(text.style!.color!), greaterThanOrEqualTo(4.5));
        // The close mark is a graphic that says how to deselect: 3:1.
        if (selected) {
          final close = tester.widget<Icon>(find.byIcon(Icons.close));
          expect(worst(close.color!), greaterThanOrEqualTo(3.0));
        }
      });
    }
  }
}
