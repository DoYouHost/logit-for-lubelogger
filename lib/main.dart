import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_localizations_loader.dart';
import 'core/format/formatters.dart';
import 'core/notifications/notification_service.dart';
import 'core/background/background_worker.dart';
import 'core/theme/dash_theme.dart';
import 'core/quick_actions_service.dart';
import 'core/settings/settings_repository.dart';
import 'features/bug_report/report_wiring.dart';
import 'features/quick_actions/quick_action_handler.dart';
import 'providers.dart';
import 'router.dart';

/// Shared notification handle for the UI isolate (init + launch payload). The
/// WorkManager background isolate builds its own instance — the two isolates
/// share no Dart state, only the native plugin underneath.
final notificationService = NotificationService();

/// Navigate to a vehicle from a tapped reminder notification (payload = vehicle
/// id). Best-effort: silently ignores a malformed payload or a not-yet-ready
/// navigator — and says so in the diagnostic log, because "I tapped the
/// notification and nothing opened" is otherwise an event with no trace at all.
void _openVehicleFromNotification(String? payload) {
  final id = int.tryParse(payload ?? '');
  final context = rootNavigatorKey.currentContext;
  DiagnosticRecorder.active?.add(
    LogSource.notif,
    'tapped',
    lvl: id == null || context == null ? LogLevel.warn : LogLevel.info,
    fields: {
      'vid': id,
      'reason': id == null
          ? 'badPayload'
          : context == null
          ? 'noNavigator'
          : null,
    },
  );
  if (id == null) return;
  context?.go('/vehicle/$id');
}

Future<void> main() async {
  AppStart.at = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  // The OFL texts of the bundled faces, which dash_ui carries.
  registerDashFontLicenses();
  // Numbers and money follow the device's regional format (separators, and
  // whether the currency symbol leads or trails the amount).
  Formatters.useLocale(
    WidgetsBinding.instance.platformDispatcher.locale.toString(),
  );
  final prefs = await SharedPreferences.getInstance();

  // Notification + quick-action setup is non-essential to the app running, so a
  // failure here (e.g. a missing/stripped resource) must never keep runApp()
  // below from executing — swallow and log instead of taking the whole app down.
  String? launchPayload;
  try {
    // Notifications plugin + the recurring background pass (queued writes,
    // stored data, reminders).
    final l10n = await loadAppLocalizations();
    await notificationService.init(
      channelName: l10n.notifReminderChannelName,
      channelDescription: l10n.notifReminderChannelDescription,
      onTap: _openVehicleFromNotification,
    );
    await initBackgroundWorker();
    final settings = SettingsRepository(prefs);
    final signedIn = settings.loadProfile() != null;
    // Armed for anyone signed in, whatever their notification preference: the
    // same pass is what retries a write the server wasn't there to take.
    if (signedIn) {
      await registerBackgroundWorker();
    }

    // Launcher quick actions: register the tap handler (it fires now if the app
    // was cold-launched from a shortcut) and publish the add-record shortcuts
    // while signed in.
    await quickActionsService.init((type) => pendingQuickAction.value = type);
    if (signedIn) {
      await quickActionsService.setRecordShortcuts(
        fuelLabel: l10n.quickActionAddFuel,
        odometerLabel: l10n.quickActionAddOdometer,
      );
    }

    launchPayload = await notificationService.launchPayload();
  } catch (error, stack) {
    debugPrint(
      'Non-essential startup init failed (continuing): $error\n$stack',
    );
  }

  runApp(
    ProviderScope(
      retry: neverRetry,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reportBindingsOverride,
      ],
      child: const LubeLoggerApp(),
    ),
  );

  // App launched by tapping a notification: deep-link once the first frame (and
  // thus the router) is ready.
  if (launchPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openVehicleFromNotification(launchPayload),
    );
  }
}
