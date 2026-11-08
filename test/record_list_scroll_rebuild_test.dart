import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_list.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';

/// Scrolling must not rebuild the cards that are already on screen. A card only
/// changes when its record changes, so a frame spent rebuilding the same rows is
/// a frame the scroll does not get — and this is measured rather than assumed,
/// because the cost lands on the UI thread where it shows up as stutter.
void main() {
  testWidgets('scrolling builds each card once, not once per frame', (
    tester,
  ) async {
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: RecordsTabBody<int>(
            async: AsyncValue.data(List.generate(40, (i) => i)),
            onRefresh: () async {},
            emptyIcon: Icons.speed,
            emptyLabel: 'nothing here',
            builder: (records, _) => RecordsContent(
              count: records.length,
              card: (context, index) {
                builds++;
                return RecordCard(date: 'row $index', headline: '$index');
              },
            ),
          ),
        ),
      ),
    );

    final afterFirstFrame = builds;
    builds = 0;

    // A slow drag over many frames: the rows under the finger stay the same, so
    // the only builds owed are the few cards scrolling into view.
    final gesture = await tester.startGesture(const Offset(400, 300));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(0, -4));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    // 80 logical pixels of travel exposes at most a couple of new cards. Rebuilding
    // every visible card on every one of the 20 frames would be an order of
    // magnitude more than this.
    expect(
      builds,
      lessThan(afterFirstFrame),
      reason:
          'rebuilt $builds cards over 20 frames of a small drag, '
          'having built $afterFirstFrame for the whole first screen',
    );
  });
}
