import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_ui/app_report_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/garage/garage_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/vehicle/vehicle_screen.dart';
import 'providers.dart';

/// Root navigator key — lets us push routes from outside the widget tree.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// App router. Without a saved profile every route redirects to `/setup`; once
/// a profile is saved the app opens at `/`.
final routerProvider = Provider<GoRouter>((ref) {
  final hasProfile = ref.watch(serverProfileProvider.select((p) => p != null));
  // Diagnostic log: the probe follows the location, the observer catches what
  // never touches it (sheets, dialogs, dropdowns). Both write through
  // `DiagnosticRecorder.active`, which is null unless a recording runs.
  final probe = NavigationProbe();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [ModalObserver()],
    initialLocation: hasProfile ? '/' : '/setup',
    redirect: (context, state) {
      // The bug report stays reachable without a profile: a setup that fails is
      // exactly the thing worth recording, and bouncing the user to /setup would
      // take the log away with the screen.
      if (state.matchedLocation == bugReportRoute) return null;
      if (!hasProfile && state.matchedLocation != '/setup') {
        return '/setup';
      }
      if (hasProfile && state.matchedLocation == '/setup') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/', builder: (_, _) => const GarageScreen()),
      GoRoute(
        path: '/vehicle/:id',
        builder: (_, state) => VehicleScreen(
          vehicleId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: bugReportRoute, builder: (_, _) => const BugReportScreen()),
    ],
  );
  probe.watch(router);
  // "Change server" (profile set→null→set) rebuilds a new GoRouter — dispose
  // the old one so its listeners don't leak.
  ref.onDispose(() {
    probe.unwatch();
    router.dispose();
  });
  return router;
});
