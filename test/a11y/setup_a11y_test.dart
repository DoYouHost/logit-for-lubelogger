import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'a11y_harness.dart';

Finder _field(String id) =>
    find.descendant(of: byLogId(id), matching: find.byType(TextField));

void main() {
  a11ySurface(
    'setup',
    signedIn: false,
    shows: find.text(pl.serverAddressLabel),
  );

  a11ySurface(
    'setup: both fields empty',
    signedIn: false,
    arrange: (tester) => a11yTap(tester, find.text(pl.connect)),
    shows: find.text(pl.errMissingUrl),
  );

  a11ySurface(
    'setup: address given, key missing',
    signedIn: false,
    arrange: (tester) async {
      await a11yEnter(tester, _field('setup.url'), 'demo');
      await a11yTap(tester, find.text(pl.connect));
    },
    shows: find.text(pl.errMissingApiKey),
  );

  a11ySurface(
    'setup: key rejected',
    signedIn: false,
    arrange: (tester) async {
      await a11yEnter(tester, _field('setup.url'), 'demo');
      await a11yEnter(tester, _field('setup.apiKey'), 'wrong-key');
      await a11yTap(tester, find.text(pl.connect));
    },
    shows: find.text(pl.errApiKeyRejected),
  );

  a11ySurface(
    'setup: key revealed',
    signedIn: false,
    arrange: (tester) async {
      await a11yEnter(tester, _field('setup.apiKey'), 'demodemodemo');
      await a11yTap(tester, byLogId('setup.apiKey.reveal'));
    },
    // Obscured, the field still holds the text: only an unobscured editor is the
    // revealed state.
    shows: find.byWidgetPredicate(
      (w) =>
          w is EditableText &&
          !w.obscureText &&
          w.controller.text == 'demodemodemo',
    ),
  );
}
