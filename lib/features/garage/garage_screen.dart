import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_ui/app_report_ui.dart' show bugReportRoute;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/models/vehicle.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../sync/sync_sheet.dart';
import 'add_vehicle_form.dart';
import 'widgets/vehicle_card.dart';

/// The garage: the household's vehicles as photo cards, with an add-vehicle tile
/// at the end (design screen #2).
class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen>
    with TickerProviderStateMixin {
  // One swipe controller per vehicle (keyed by id) so we can force-close an open
  // Edit action when a control *outside* the list is tapped — the settings gear
  // and the add-vehicle tile sit beyond the per-card auto-close barrier.
  final Map<int, SlidableController> _slidableControllers = {};

  @override
  void dispose() {
    for (final controller in _slidableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  SlidableController _controllerFor(int vehicleId) => _slidableControllers
      .putIfAbsent(vehicleId, () => SlidableController(this));

  /// Closes any open swipe action. Returns true when one was open, so a tap on
  /// an outside control just dismisses it (as tapping a card does) rather than
  /// also firing that control's own action.
  bool _closeOpenActions() {
    var closedAny = false;
    for (final controller in _slidableControllers.values) {
      if (controller.ratio != 0) {
        controller.close();
        closedAny = true;
      }
    }
    return closedAny;
  }

  Future<void> _refresh() async {
    ref.invalidate(garageProvider);
    ref.invalidate(serverInfoProvider);
    await ref.read(garageProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garage = ref.watch(garageProvider);
    final baseUrl = ref.watch(serverProfileProvider)?.baseUrl ?? '';
    final apiKey = ref.watch(apiKeyProvider).value;
    final currency = ref.watch(currencySymbolProvider);
    final units = ref.watch(unitsSettingsProvider);

    // One surface for the screen: every control inside it that does not name
    // itself reports as `garage`, and the error and empty views know where they
    // are standing without being told.
    return logSurface(
      'garage',
      DashBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: dashAppBar(
            context,
            titleWidget: const LubeLoggerWordmark(),
            actions: [
              const SyncStatusAction(),
              // On the home screen rather than only in settings: a bug is
              // noticed while using the app, and a route that runs through six
              // preference groups is one the person having the bug does not
              // take. It also has to be reachable *before* reproducing, since
              // the recording has to be running by then.
              IconButton(
                tooltip: l10n.bugReportTitle,
                icon: const Icon(Icons.feedback_outlined),
                onPressed: _openFeedback,
              ).tagged('garage.feedback'),
              IconButton(
                tooltip: l10n.settingsTitle,
                icon: const Icon(Icons.settings_outlined),
                onPressed: _openSettings,
              ).tagged('garage.settings'),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: garage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => AsyncErrorView(
                // Its own scroll view, so the enclosing RefreshIndicator still
                // has something to pull.
                scrollable: true,
                message: l10n.garageLoadError,
                onRetry: _refresh,
                retryLabel: l10n.retry,
              ),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return _EmptyGarage(l10n: l10n, onAdd: _openAddVehicle);
                }
                // The cards flow into 2–3 columns on wider (landscape) screens,
                // built lazily so an off-screen vehicle costs nothing to scroll
                // past — its photo included. SlidableAutoCloseBehavior closes
                // any open Edit action when another card is tapped or the list
                // scrolls. The add tile rides along as the last cell.
                return SlidableAutoCloseBehavior(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          DashSpace.lg,
                          DashSpace.lg,
                          DashSpace.lg,
                          DashSpace.xxl,
                        ),
                        sliver: SliverResponsiveCards(
                          spacing: DashSpace.lg,
                          runSpacing: DashSpace.lg,
                          itemCount: vehicles.length + 1,
                          itemBuilder: (context, index) {
                            if (index == vehicles.length) {
                              return AddVehicleTile(onTap: _openAddVehicle);
                            }
                            final info = vehicles[index];
                            // Clip each card to its grid cell so a slid-open
                            // card stays within its own column instead of
                            // bleeding over the neighbouring vehicle.
                            return ClipRect(
                              // While another card is open, every card gets a tap that
                              // closes it, from inside `flutter_slidable`: it has no
                              // name of its own, so the card's is given from outside.
                              child: Semantics(
                                label: info.vehicle.makeModel,
                                child: Slidable(
                                  key: ValueKey(info.vehicle.id),
                                  controller: _controllerFor(info.vehicle.id),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.3,
                                    children: [
                                      _EditVehicleAction(
                                        onPressed: () =>
                                            _editVehicle(info.vehicle),
                                      ),
                                    ],
                                  ),
                                  child: logTag(
                                    'garage.card',
                                    VehicleCard(
                                      info: info,
                                      baseUrl: baseUrl,
                                      apiKey: apiKey,
                                      currencySymbol: currency,
                                      units: units,
                                      onTap: () => context.push(
                                        '/vehicle/${info.vehicle.id}',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Opens Settings — unless a swipe action is open, in which case the tap just
  /// closes it (consistent with tapping a card while one is open).
  void _openSettings() {
    if (_closeOpenActions()) return;
    context.push('/settings');
  }

  void _openFeedback() {
    if (_closeOpenActions()) return;
    context.push(bugReportRoute);
  }

  /// Opens the add-vehicle form and, on success, jumps to the new vehicle. A tap
  /// with a swipe action open just closes it first. The form invalidates
  /// [garageProvider] itself, so the list refreshes regardless.
  Future<void> _openAddVehicle() async {
    if (_closeOpenActions()) return;
    final newId = await showVehicleForm(context);
    if (newId != null && mounted) {
      context.push('/vehicle/$newId');
    }
  }

  /// Opens the edit form for [vehicle] (slide action). The form invalidates the
  /// garage + vehicle-info providers itself, so no navigation is needed.
  Future<void> _editVehicle(Vehicle vehicle) =>
      showVehicleForm(context, existing: vehicle);
}

/// The slide-out "Edit" action for a vehicle card: a floating gold→orange pill
/// with an icon chip, bold label and a soft gold glow, so it reads as a real
/// button rather than a flat colour block. Wraps [CustomSlidableAction] (same
/// pane nesting as the stock [SlidableAction]) to host the custom child.
class _EditVehicleAction extends StatelessWidget {
  const _EditVehicleAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final ink = Theme.of(context).colorScheme.onPrimary;
    // Named on the pill and not around the action: CustomSlidableAction builds
    // an Expanded, and anything wrapped around it lands between that Expanded
    // and the pane's flex layout, which throws on the first swipe. The tag still
    // reaches the log — the probe reads the deepest identifier under the finger.
    // SizedBox.expand is load-bearing: the action puts its child in an Align,
    // which would otherwise shrink the pill to its content.
    return CustomSlidableAction(
      onPressed: (_) => onPressed(),
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      // The button is the node that takes the tap, so it takes the name: a label
      // outside the tag merges into it, and the text under the tag is not read again.
      child: Semantics(
        label: l10n.actionEdit,
        child: logTag(
          'garage.edit',
          ExcludeSemantics(
            child: SizedBox.expand(
              child: Container(
                margin: const EdgeInsets.only(left: DashSpace.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [t.accentGold, t.accentOrange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: t.accentGold.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DashSpace.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_rounded, size: 22, color: ink),
                    ),
                    const SizedBox(height: DashSpace.sm),
                    Text(
                      l10n.actionEdit,
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state that still offers the add-vehicle tile.
class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.l10n, required this.onAdd});

  final AppLocalizations l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DashSpace.lg,
        DashSpace.xxl,
        DashSpace.lg,
        DashSpace.xxl,
      ),
      children: [
        Icon(Icons.garage_outlined, size: 56, color: t.textTertiary),
        const SizedBox(height: DashSpace.md),
        Text(
          l10n.garageEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: DashSpace.xl),
        AddVehicleTile(onTap: onAdd),
      ],
    );
  }
}
