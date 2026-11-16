import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/features/bug_report/report_wiring.dart';
import 'package:lubelogger_mobile/features/settings/settings_screen.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  // The test font draws every glyph as a 1 em square, far wider than Manrope;
  // a width check is only meaningful with the font the app ships.
  setUpAll(() async {
    final manrope = FontLoader(DashTokens.fontUi);
    for (final weight in [400, 500, 600, 700, 800]) {
      final bytes = File('assets/fonts/Manrope-$weight.ttf').readAsBytesSync();
      manrope.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await manrope.load();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Locale locale,
    required MeasurementSystem base,
    double width = 320,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({
      'units_settings': jsonEncode(UnitsSettings(base: base).toJson()),
    });
    prefs = await SharedPreferences.getInstance();
    // Tall enough that the list builds every section, not only the first few.
    tester.view.physicalSize = Size(width, 3200) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    // The server-backed rows never resolve: this test is about the units rows.
    Future<T> pending<T>(Ref _) => Completer<T>().future;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reportBindingsOverride,
          serverInfoProvider.overrideWith(pending),
          whoAmIProvider.overrideWith(pending),
          serverVersionProvider.overrideWith(pending),
          packageInfoProvider.overrideWith(pending),
          cacheSizeProvider.overrideWith(pending),
        ],
        child: MaterialApp(
          theme: buildDashThemeData(Brightness.dark, brand: lubeLoggerBrand),
          locale: locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the UK MPG base fits a 320 dp row in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        locale: locale,
        base: MeasurementSystem.imperialUk,
      );
      final l10n = await AppLocalizations.delegate.load(locale);

      expect(tester.takeException(), isNull);
      expect(find.text(l10n.baseImperialUk), findsOneWidget);
    });

    // A small phone with larger text: a control too wide to share the line
    // must move below its label, not crush the label or overflow the row.
    testWidgets(
      'every row fits 320 dp at 1.3x text in ${locale.languageCode}',
      (tester) async {
        await pumpSettings(
          tester,
          locale: locale,
          base: MeasurementSystem.imperialUk,
          textScale: 1.3,
        );
        final l10n = await AppLocalizations.delegate.load(locale);
        final oneLine = tester.getSize(find.text(l10n.settingsDistance)).height;

        expect(tester.takeException(), isNull);
        for (final label in [
          l10n.settingsStorageBase,
          l10n.settingsCurrency,
          l10n.settingsFuelCalculated,
        ]) {
          expect(
            tester.getSize(find.text(label)).height,
            oneLine,
            reason: label,
          );
        }
      },
    );
  }

  // Android's largest font sizes: the longest option wraps onto a second line,
  // which must neither overflow the screen edge nor be clipped by the button.
  for (final locale in AppLocalizations.supportedLocales) {
    for (final scale in [1.5, 2.0]) {
      testWidgets('the UK MPG option is shown whole at ${scale}x text in '
          '${locale.languageCode}', (tester) async {
        await pumpSettings(
          tester,
          locale: locale,
          base: MeasurementSystem.imperialUk,
          textScale: scale,
        );
        final l10n = await AppLocalizations.delegate.load(locale);

        expect(tester.takeException(), isNull);
        final option = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byType(DropdownButton<MeasurementSystem>),
            matching: find.text(l10n.baseImperialUk),
          ),
        );
        expect(
          option.size.height,
          greaterThanOrEqualTo(option.textSize.height),
        );
      });
    }
  }

  // 360 dp is the common phone width: the row label must not be squeezed onto
  // a second line by a long option.
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('the server data label stays on one line at 360 dp in '
        '${locale.languageCode}', (tester) async {
      await pumpSettings(
        tester,
        locale: locale,
        base: MeasurementSystem.imperialUk,
        width: 360,
      );
      final l10n = await AppLocalizations.delegate.load(locale);
      final oneLine = tester.getSize(find.text(l10n.settingsCurrency)).height;

      expect(
        tester.getSize(find.text(l10n.settingsStorageBase)).height,
        oneLine,
      );
    });
  }

  testWidgets('picking the UK MPG base persists it', (tester) async {
    const locale = Locale('en');
    await pumpSettings(tester, locale: locale, base: MeasurementSystem.metric);
    final l10n = await AppLocalizations.delegate.load(locale);

    await tester.tap(find.text(l10n.baseMetric));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.baseImperialUk).last);
    await tester.pumpAndSettle();

    final stored = jsonDecode(prefs.getString('units_settings')!);
    expect(stored['base'], 'imperialUk');
    expect(find.text(l10n.baseImperialUk), findsOneWidget);
  });

  testWidgets('picking the calculated fuel field persists it', (tester) async {
    const locale = Locale('en');
    await pumpSettings(tester, locale: locale, base: MeasurementSystem.metric);
    final l10n = await AppLocalizations.delegate.load(locale);

    await tester.tap(find.text(l10n.fuelCalculatedPrice));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.fuelCalculatedAmount).last);
    await tester.pumpAndSettle();

    expect(prefs.getString('fuel_entry_mode'), 'priceAndCost');
    expect(find.text(l10n.fuelCalculatedAmount), findsOneWidget);
  });
}
