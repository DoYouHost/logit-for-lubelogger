import 'package:app_report_ui/app_report_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      theme: buildDashThemeData(Brightness.light, brand: lubeLoggerBrand),
      darkTheme: buildDashThemeData(Brightness.dark, brand: lubeLoggerBrand),
      // Follow the system setting; the design is dark-first.
      themeMode: ThemeMode.system,
      // Locale auto-detected from the system; en is the fallback.
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        ReportLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // Always-mounted hosts: launcher quick actions (see QuickActionHandler),
      // the offline write queue (see SyncHost), and the diagnostic recording
      // controls, which have to outlive the report screen — the bug is
      // reproduced somewhere else in the app.
      builder: (context, child) => QuickActionHandler(
        child: SyncHost(
          child: RecordingBannerScaffold(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
