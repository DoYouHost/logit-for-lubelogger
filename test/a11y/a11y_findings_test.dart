import 'package:flutter_test/flutter_test.dart';

import 'a11y_harness.dart';

void main() {
  test('two findings of one node: the one that keeps failing is kept', () {
    // Element A of node 10 fails at the shipped position only; element B fails
    // at both. At the second phase A passes, so B is the node's first finding and
    // is numbered 10/0 there.
    final shipped = {'10/0': 'A fails', '10/1': 'B fails'};
    final again = {'10/0': 'B fails'};
    expect(a11yStillFailing(shipped, again), containsPair('10/1', 'B fails'));
  });

  test('a node that no longer fails is dropped', () {
    final shipped = {'10/0': 'A fails', '11/0': 'C fails'};
    final again = {'11/0': 'C fails'};
    expect(a11yStillFailing(shipped, again), {'11/0': 'C fails'});
  });

  test('nothing failing later leaves nothing', () {
    expect(a11yStillFailing({'10/0': 'A fails'}, {}), isEmpty);
  });
}
