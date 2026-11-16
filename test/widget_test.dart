// Smoke test: with no saved profile the app opens on the login screen.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/bug_report/report_wiring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lubelogger_mobile/app.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';

void main() {
  testWidgets('shows the login screen when unconfigured', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reportBindingsOverride,
        ],
        child: const LubeLoggerApp(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.connectToServer), findsWidgets);
    expect(find.text(l10n.serverAddressLabel), findsOneWidget);
    expect(find.text(l10n.connect), findsOneWidget);
  });
}
