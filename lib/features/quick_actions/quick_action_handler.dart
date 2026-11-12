import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/vehicle_info.dart';
import '../../core/quick_actions_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../vehicle/forms/add_fuel_form.dart';
import '../vehicle/forms/add_odometer_form.dart';
import 'vehicle_picker_sheet.dart';

/// A launcher shortcut tapped by the user. Set from the quick-actions callback
/// — possibly before the UI exists on a cold launch — and consumed by
/// [QuickActionHandler] once the app is ready.
final ValueNotifier<String?> pendingQuickAction = ValueNotifier<String?>(null);

/// Turns a pending launcher shortcut into a record-add flow: resolve a vehicle
/// (auto-selected when there's exactly one, otherwise a picker) and open the
/// matching add-record form. Wraps the router so it's always mounted; all UI is
/// shown through the root navigator, so it works from any screen.
class QuickActionHandler extends ConsumerStatefulWidget {
  const QuickActionHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<QuickActionHandler> createState() => _QuickActionHandlerState();
}

class _QuickActionHandlerState extends ConsumerState<QuickActionHandler> {
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    pendingQuickAction.addListener(_onPending);
    // A cold-launch action may already be queued before this widget mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPending());
  }

  @override
  void dispose() {
    pendingQuickAction.removeListener(_onPending);
    super.dispose();
  }

  /// The launcher-shortcut lane. Every branch below ends the flow somewhere the
  /// user cannot see, which is why each one leaves a record: a shortcut that
  /// silently does nothing is the report, and from the outside a dropped stale
  /// tap, an unreachable garage and a cancelled picker look identical.
  void _log(
    String evt, {
    LogLevel lvl = LogLevel.info,
    Map<String, Object?> fields = const {},
  }) => DiagnosticRecorder.active?.add(
    LogSource.app,
    evt,
    lvl: lvl,
    fields: fields,
  );

  void _onPending() {
    final action = pendingQuickAction.value;
    if (action == null || _handling) return;
    // Only actionable while signed in; otherwise drop it (shortcuts are cleared
    // on logout, so this only guards a stale tap).
    if (ref.read(serverProfileProvider) == null) {
      pendingQuickAction.value = null;
      _log(
        'quick_action_dropped',
        lvl: LogLevel.warn,
        fields: {'action': action, 'reason': 'signedOut'},
      );
      return;
    }
    pendingQuickAction.value = null;
    _handling = true;
    // Defer a frame so the navigator/overlay is settled before showing sheets.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle(action));
  }

  Future<void> _handle(String action) async {
    _log('quick_action', fields: {'action': action});
    try {
      final initialCtx = rootNavigatorKey.currentContext;
      if (initialCtx == null) {
        _log(
          'quick_action_dropped',
          lvl: LogLevel.warn,
          fields: {'action': action, 'reason': 'noNavigator'},
        );
        return;
      }
      final messenger = ScaffoldMessenger.of(initialCtx);
      final l10n = AppLocalizations.of(initialCtx);

      final List<VehicleInfo> vehicles;
      try {
        vehicles = await ref.read(garageProvider.future);
      } catch (error) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.garageLoadError)));
        _log(
          'quick_action_dropped',
          lvl: LogLevel.warn,
          fields: {
            'action': action,
            'reason': 'garageFailed',
            'type': error.runtimeType.toString(),
          },
        );
        return;
      }
      if (vehicles.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.garageEmpty)));
        _log(
          'quick_action_dropped',
          lvl: LogLevel.warn,
          fields: {'action': action, 'reason': 'noVehicles'},
        );
        return;
      }

      final int? vehicleId;
      if (vehicles.length == 1) {
        vehicleId = vehicles.first.vehicle.id;
      } else {
        final pickerCtx = rootNavigatorKey.currentContext;
        if (pickerCtx == null || !pickerCtx.mounted) return;
        vehicleId = await showVehiclePicker(pickerCtx, vehicles);
      }
      if (vehicleId == null) {
        _log(
          'quick_action_dropped',
          fields: {'action': action, 'reason': 'cancelled'},
        );
        return;
      }

      final formCtx = rootNavigatorKey.currentContext;
      if (formCtx == null || !formCtx.mounted) return;
      _log('quick_action_form', fields: {'action': action, 'vid': vehicleId});
      switch (action) {
        case QuickActionsService.addFuel:
          await showAddFuelForm(formCtx, vehicleId);
        case QuickActionsService.addOdometer:
          await showAddOdometerForm(formCtx, vehicleId);
      }
    } finally {
      _handling = false;
      // Pick up anything queued while this one was running (rapid taps).
      if (pendingQuickAction.value != null) _onPending();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
