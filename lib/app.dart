import 'package:app_report_ui/app_report_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_localizations_loader.dart';
import 'core/theme/dash_theme.dart';
import 'features/quick_actions/quick_action_handler.dart';
import 'features/sync/sync_host.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

class LubeLoggerApp extends ConsumerWidget {
  const LubeLoggerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Logit',
      theme: buildLogitTheme(Brightness.light),
      darkTheme: buildLogitTheme(Brightness.dark),
      // Follow the system setting; the design is dark-first.
      themeMode: ThemeMode.system,
      // Locale auto-detected from the system; en is the fallback (it is first
      // in appSupportedLocales).
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        ReportLocalizations.delegate,
      ],
      supportedLocales: appSupportedLocales,
      routerConfig: ref.watch(routerProvider),
      // Always-mounted hosts: launcher quick actions (see QuickActionHandler),
      // the offline write queue (see SyncHost), and the diagnostic recording
      // controls, which have to outlive the report screen — the bug is
      // reproduced somewhere else in the app.
      // The overlay region covers screens that have no app bar to set it.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: logitSystemOverlay(Theme.brightnessOf(context)),
        child: QuickActionHandler(
          child: SyncHost(
            child: RecordingBannerScaffold(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
