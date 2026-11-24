import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale, basicLocaleListResolution;

import '../l10n/app_localizations.dart';

/// Loads [AppLocalizations] for the current system locale outside the widget
/// tree — needed by the notification code, which runs before `MaterialApp` (app
/// start) and inside the WorkManager background isolate, where there is no
/// `BuildContext`.
Future<AppLocalizations> loadAppLocalizations() => AppLocalizations.delegate
    .load(resolveAppLocale(PlatformDispatcher.instance.locales));

/// [AppLocalizations.supportedLocales] with English first. gen-l10n sorts them
/// alphabetically, and Flutter falls back to the first entry when nothing
/// matches, so the generated order would send a phone set to Italian to German.
final List<Locale> appSupportedLocales = [
  const Locale('en'),
  ...AppLocalizations.supportedLocales.where((l) => l.languageCode != 'en'),
];

/// The same resolution `MaterialApp` applies to `supportedLocales`, so text
/// built outside the tree speaks the language of the screen it opens. Matching
/// on `languageCode` alone read only the first preferred language, so a phone
/// set to Italian then Polish got English notifications.
Locale resolveAppLocale(List<Locale> preferred) =>
    basicLocaleListResolution(preferred, appSupportedLocales);
