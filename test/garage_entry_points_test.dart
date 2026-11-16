import 'dart:convert';

import 'package:app_report_ui/app_report_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/app.dart';
import 'package:lubelogger_mobile/core/models/vehicle_info.dart';
import 'package:lubelogger_mobile/features/bug_report/report_wiring.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ways out of the garage. Reporting is one of them on purpose: a bug is
/// noticed while using the app, and the recording has to be started *before* it
/// is reproduced — a path that runs through the settings screen is one the
/// person having the bug does not take.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pumpGarage(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'server_profile': jsonEncode({'baseUrl': 'https://lube.invalid'}),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reportBindingsOverride,
          // An empty garage still draws the app bar, and nothing else on the
          // screen reaches for the network.
          garageProvider.overrideWith((ref) async => <VehicleInfo>[]),
        ],
        child: const LubeLoggerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the garage offers reporting beside settings', (tester) async {
    await pumpGarage(tester);

    expect(find.byTooltip(l10n.bugReportTitle), findsOneWidget);
    expect(find.byTooltip(l10n.settingsTitle), findsOneWidget);
  });

  testWidgets('it opens the report screen in one tap', (tester) async {
    await pumpGarage(tester);

    await tester.tap(find.byTooltip(l10n.bugReportTitle));
    await tester.pumpAndSettle();

    final report = await ReportLocalizations.delegate.load(const Locale('en'));
    expect(find.text(report.bugReportKindQuestion), findsOneWidget);
  });

  testWidgets('the consent card carries this app\'s own lines', (tester) async {
    // The card is the shared package's; what it promises about the log is
    // LubeLogger's, and these two lines are the ones no other app would say.
    await pumpGarage(tester);
    await tester.tap(find.byTooltip(l10n.bugReportTitle));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(l10n.bugReportLogNoData), 200);
    expect(find.text(l10n.bugReportLogSetup), findsOneWidget);
    expect(find.text(l10n.bugReportLogNoData), findsOneWidget);
  });
}
