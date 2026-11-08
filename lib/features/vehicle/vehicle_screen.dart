import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/diagnostics/image_probe.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/vehicle_record.dart';
import '../../core/models/vehicle_tab.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../common/vehicle_image.dart';
import '../common/vehicle_tab_ui.dart';
import 'add_record_sheet.dart';
import 'widgets/record_tabs.dart';

/// One vehicle, with the dashboard and each record type as a tab. The vehicle
/// header + scrollable tab bar are shared chrome; each tab manages its own data
/// and pull-to-refresh. Reached at `/vehicle/:id`.
class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen>
    with TickerProviderStateMixin {
  // Recreated whenever the visible-tab count changes (settings toggles), so
  // TickerProviderStateMixin (not Single-) — we may hold successive controllers.
  TabController? _tabController;
  List<_VehicleTab> _tabs = const [];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Quietly re-fetches the newly-selected tab's data in the background.
  /// Invalidating alone is enough to trigger the refetch: the provider keeps
  /// serving its last value while it's in flight (Riverpod's default
  /// `skipLoadingOnRefresh`), so the tab repaints in place once fresh data
  /// arrives instead of flashing a full-screen spinner.
  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null) return;
    if (controller.indexIsChanging) return;
    _tabs[controller.index].refresh(ref);
  }

  /// Returns a controller of the given [length], reusing the current one when
  /// the count is unchanged and otherwise rebuilding it (preserving the
  /// selected index where possible). Called from [build] because the visible
  /// tab set — and thus the length — can change while the screen is alive.
  TabController _controllerFor(int length) {
    final existing = _tabController;
    if (existing != null && existing.length == length) return existing;
    final initialIndex = existing == null
        ? 0
        : existing.index.clamp(0, length - 1);
    existing?.removeListener(_onTabChanged);
    existing?.dispose();
    return _tabController = TabController(
      length: length,
      initialIndex: initialIndex,
      vsync: this,
    )..addListener(_onTabChanged);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = widget.vehicleId;
    final vehicle = ref.watch(vehicleInfoProvider(vehicleId)).value?.vehicle;
    final visible = ref.watch(visibleTabsProvider);
    final order = ref.watch(tabOrderProvider);

    // Dashboard always leads; the record tabs follow in the user's chosen order,
    // filtered to the visible set. The same list drives the FAB add sheet.
    final orderedVisible = [
      for (final tab in order)
        if (visible.contains(tab)) tab,
    ];
    final hidden = [
      for (final tab in order)
        if (!visible.contains(tab)) tab,
    ];
    _tabs = <_VehicleTab>[
      _VehicleTab(
        'dashboard',
        l10n.tabDashboard,
        Icons.dashboard_rounded,
        DashboardTab(vehicleId: vehicleId),
        (ref) => invalidateVehicleData(ref.invalidate, vehicleId),
      ),
      for (final tab in orderedVisible) _recordTab(tab, l10n, vehicleId),
    ];

    final controller = _controllerFor(_tabs.length);

    return DashBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // On a record tab the FAB adds that tab's record type straight away;
        // the dashboard, or a long press anywhere, opens the full picker.
        // The long press is a node of its own, apart from the button's tap: named
        // here, outside the detector, it merges into that node.
        floatingActionButton: Semantics(
          label: l10n.addRecordTitle,
          child: GestureDetector(
            onLongPress: () {
              Feedback.forLongPress(context);
              showAddRecordSheet(context, vehicleId, orderedVisible, hidden);
            },
            child: FloatingActionButton(
              tooltip: l10n.addRecordTitle,
              backgroundColor: DashTokens.of(context).accentGold,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => controller.index == 0
                  ? showAddRecordSheet(
                      context,
                      vehicleId,
                      orderedVisible,
                      hidden,
                    )
                  : showAddRecordForm(
                      context,
                      vehicleId,
                      orderedVisible[controller.index - 1],
                    ),
              child: const Icon(Icons.add),
            ).tagged('vehicle.add'),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _VehicleHeader(vehicle: vehicle),
              // Both header and tab strip stay put. The strip used to collapse,
              // carried by a floating+snap SliverAppBar inside a
              // NestedScrollView — and that cost 27-74ms of the UI thread on
              // every frame of a scroll (measured on a Kirin 950, budget 16ms),
              // because a scrollable TabBar re-measures all of its tabs and its
              // indicator geometry each time the header moves. Holding the
              // strip's widget instance across those rebuilds did not help: the
              // cost is the layout, not the build. Static, the same scroll
              // spends 5-6ms. The design asked for a collapsing strip; this is
              // a deliberate trade, so do not restore it without measuring.
              _VehicleTabBar(tabs: _tabs, controller: controller),
              Expanded(
                // One surface per tab, in the loop that already builds them:
                // every control and every empty or error view inside a tab is
                // named by the tab it is in.
                child: TabBarView(
                  controller: controller,
                  children: [
                    for (final t in _tabs)
                      logSurface('vehicle.${t.id}', t.content),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the [_VehicleTab] (label, icon, content, background-refresh) for a
  /// single record [tab].
  _VehicleTab _recordTab(VehicleTab tab, AppLocalizations l10n, int vehicleId) {
    final (Widget content, void Function(WidgetRef) refresh) = switch (tab) {
      VehicleTab.odometer => (
        OdometerTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(odometerRecordsProvider(vehicleId)),
      ),
      VehicleTab.service => _genericTab(vehicleId, RecordKind.service),
      VehicleTab.repair => _genericTab(vehicleId, RecordKind.repair),
      VehicleTab.upgrade => _genericTab(vehicleId, RecordKind.upgrade),
      VehicleTab.fuel => (
        FuelTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(gasRecordsProvider(vehicleId)),
      ),
      VehicleTab.tax => _genericTab(vehicleId, RecordKind.tax),
      VehicleTab.supply => (
        SupplyTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(supplyRecordsProvider(vehicleId)),
      ),
      VehicleTab.plan => (
        PlanTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(planRecordsProvider(vehicleId)),
      ),
      VehicleTab.reminder => (
        ReminderTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(remindersProvider(vehicleId)),
      ),
      VehicleTab.note => (
        NoteTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(notesProvider(vehicleId)),
      ),
      VehicleTab.equipment => (
        EquipmentTab(vehicleId: vehicleId),
        (ref) => ref.invalidate(equipmentRecordsProvider(vehicleId)),
      ),
    };
    return _VehicleTab(tab.name, tab.label(l10n), tab.icon, content, refresh);
  }

  /// The generic (date + cost) record tab + its refresh, shared by
  /// service / repair / upgrade / tax.
  (Widget, void Function(WidgetRef)) _genericTab(
    int vehicleId,
    RecordKind kind,
  ) => (
    GenericRecordsTab(vehicleId: vehicleId, kind: kind),
    (ref) => ref.invalidate(
      vehicleRecordsProvider((vehicleId: vehicleId, kind: kind)),
    ),
  );
}

/// A tab's label, icon, content pane, and the quiet background-refresh it
/// triggers when the user switches to it.
class _VehicleTab {
  const _VehicleTab(this.id, this.label, this.icon, this.content, this.refresh);

  /// Stable, unlocalized name for the log — the enum's own, `dashboard` for the
  /// one tab that is not a record type.
  final String id;

  final String label;
  final IconData icon;
  final Widget content;
  final void Function(WidgetRef ref) refresh;
}

/// Back button + circular photo + name/plate row, with a hairline underline
/// (design #4/#5 vheader). Shared across all tabs.
class _VehicleHeader extends ConsumerWidget {
  const _VehicleHeader({required this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DashTokens.of(context);
    final baseUrl = ref.watch(serverProfileProvider)?.baseUrl ?? '';
    final apiKey = ref.watch(apiKeyProvider).value;
    final name = vehicle == null
        ? ''
        : [
            if (vehicle!.year > 0) '${vehicle!.year}',
            vehicle!.makeModel,
          ].where((s) => s.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DashSpace.xs,
        DashSpace.sm,
        DashSpace.lg,
        DashSpace.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ).tagged('vehicle.back'),
          _Avatar(vehicle: vehicle, baseUrl: baseUrl, apiKey: apiKey),
          const SizedBox(width: DashSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                if (vehicle != null && vehicle!.licensePlate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: DashSpace.xs),
                    child: Text(
                      '(${vehicle!.licensePlate})',
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.vehicle, required this.baseUrl, this.apiKey});

  final Vehicle? vehicle;
  final String baseUrl;
  final String? apiKey;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final placeholder = Icon(
      Icons.directions_car,
      size: 22,
      color: t.textTertiary,
    );
    final image = vehicle?.imageLocation ?? '';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: t.subCard,
        shape: BoxShape.circle,
        border: Border.all(color: t.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isEmpty
          ? Center(child: placeholder)
          : Image(
              image: vehicleImageProvider(
                imageLocation: image,
                baseUrl: baseUrl,
                apiKey: apiKey,
                cacheWidth: (44 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
              ),
              fit: BoxFit.cover,
              errorBuilder: ImageProbe.errorBuilder(Center(child: placeholder)),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
    );
  }
}

/// Scrollable tab strip: each tab is an icon + label; the selected tab gets a
/// rounded gold pill (design's active-accent language).
class _VehicleTabBar extends StatelessWidget {
  const _VehicleTabBar({required this.tabs, required this.controller});

  final List<_VehicleTab> tabs;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStatePropertyAll(
          t.accentGold.withValues(alpha: 0.06),
        ),
        indicator: BoxDecoration(
          color: t.accentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.accentGold.withValues(alpha: 0.5)),
        ),
        labelColor: t.accentGoldInk,
        unselectedLabelColor: t.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: DashSpace.sm),
        labelStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          for (final tab in tabs)
            logTag(
              'vehicle.tabbar.${tab.id}',
              Tab(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DashSpace.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 17),
                      const SizedBox(width: DashSpace.sm),
                      Text(tab.label),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
