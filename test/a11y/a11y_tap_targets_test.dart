import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'a11y_harness.dart';

/// A strip of 120 dp wide buttons in a window 411 dp wide: three whole, and a
/// fourth cut by the viewport's right edge, so its semantic rect is narrower than
/// the button.
Future<void> _strip(WidgetTester tester, {required double height}) => a11yPump(
  tester,
  Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < 6; i++)
              SizedBox(
                width: 120,
                child: InkWell(
                  onTap: () {},
                  child: Center(child: Text('Tab $i')),
                ),
              ),
          ],
        ),
      ),
    ),
  ),
  Brightness.light,
  window: const Size(411, 400),
);

void main() {
  testWidgets('a control cut by the viewport is excused across the cut only', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _strip(tester, height: 48);
    // The fourth button is 91 dp of 120 dp wide in the viewport. Excused: it is the
    // viewport that makes it narrow, and it is 48 dp tall.
    await a11yMeetsAll(tester);
    handle.dispose();
  });

  testWidgets('the first row at offset 0 is whole, so its height counts', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _list(tester);
    // Nothing is above the first row, so flush with the top is not cut: it is 36 dp
    // tall and must be reported, not excused for touching the viewport.
    expect(await _failureOf(tester), contains('36.0'));
    handle.dispose();
  });

  testWidgets('a row cut at the top by a scroll is still excused', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _list(tester);
    // 20 dp down: row 0 (36 dp) is cut at the top, with content above it.
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(20);
    await tester.pump(const Duration(milliseconds: 100));
    expect(await _failureOf(tester), isNot(contains('36.0')));
    handle.dispose();
  });

  testWidgets('a short strip inside a tall scrolling page is still short', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // A horizontal strip of 40 dp buttons inside a page that scrolls vertically. The
    // strip's viewport is as tall as its buttons, so they are flush with its clip at
    // top and bottom; the page has content below, but that is another scrollable's
    // edge and says nothing about this clip.
    await a11yPump(
      tester,
      Scaffold(
        appBar: AppBar(title: const Text('Title')),
        body: ListView(
          children: [
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < 6; i++)
                    SizedBox(
                      width: 120,
                      child: InkWell(
                        onTap: () {},
                        child: Center(child: Text('Chip $i')),
                      ),
                    ),
                ],
              ),
            ),
            for (var i = 0; i < 20; i++)
              SizedBox(height: 100, child: Center(child: Text('Row $i'))),
          ],
        ),
      ),
      Brightness.light,
      window: const Size(411, 500),
    );
    final failure = await _failureOf(tester);
    // 40.0 is the height of every chip, the whole ones and the cut one alike.
    expect(failure, contains('40.0'));
    expect(
      failure,
      contains('Chip 3'),
      reason: 'the chip cut by the right edge',
    );
    handle.dispose();
  });

  testWidgets('a cut control that is too short along the strip still fails', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _strip(tester, height: 40);
    // Whole buttons fail by themselves; the cut one must fail too, for its height
    // is not the viewport's doing.
    await expectLater(a11yMeetsAll(tester), throwsA(isA<TestFailure>()));
    final cut = find.text('Tab 3');
    expect(cut, findsOneWidget);
    final failure = await _failureOf(tester);
    expect(
      failure,
      contains('cut by its viewport'),
      reason: 'the cut button is reported for its height, not skipped',
    );
    handle.dispose();
  });
}

/// A list under an app bar whose first row is 36 dp tall and the others 60.
Future<void> _list(WidgetTester tester) => a11yPump(
  tester,
  Scaffold(
    appBar: AppBar(title: const Text('Title')),
    body: ListView(
      children: [
        for (var i = 0; i < 6; i++)
          SizedBox(
            height: i == 0 ? 36 : 60,
            child: InkWell(
              onTap: () {},
              child: Center(child: Text('Row $i')),
            ),
          ),
      ],
    ),
  ),
  Brightness.light,
  window: const Size(411, 500),
);

Future<String> _failureOf(WidgetTester tester) async {
  try {
    await a11yMeetsAll(tester);
  } on TestFailure catch (e) {
    return e.message ?? '';
  }
  return '';
}
