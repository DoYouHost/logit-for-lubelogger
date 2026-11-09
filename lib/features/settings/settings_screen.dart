import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_ui/app_report_ui.dart' show bugReportRoute;
import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/chart_range.dart';
import '../../core/format/fuel_entry_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/settings/units_settings.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../common/vehicle_tab_ui.dart';
import '../dashboard/widgets/chart_range_sheet.dart';

/// Basic settings: display units (currency / distance / fuel economy) and the
/// server connection (with log out).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(unitsSettingsProvider);
    final unitsCtl = ref.read(unitsSettingsProvider.notifier);
    final visibleTabs = ref.watch(visibleTabsProvider);
    final visibleTabsCtl = ref.read(visibleTabsProvider.notifier);
    final tabOrder = ref.watch(tabOrderProvider);
    final tabOrderCtl = ref.read(tabOrderProvider.notifier);
    final remindersOn = ref.watch(reminderNotificationsProvider);
    final remindersCtl = ref.read(reminderNotificationsProvider.notifier);
    final backgroundRefresh = ref.watch(backgroundRefreshProvider);
    final chartRange = ref.watch(chartDefaultRangeProvider);
    final cacheBytes = ref.watch(cacheSizeProvider).value;
    final serverSymbol =
        ref.watch(serverInfoProvider).value?.currencySymbol ?? r'$';
    final profile = ref.watch(serverProfileProvider);
    final packageInfo = ref.watch(packageInfoProvider).value;
    final who = ref.watch(whoAmIProvider).value;
    final serverVersion = ref.watch(serverVersionProvider).value;

    return DashBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: dashAppBar(context, title: l10n.settingsTitle),
        body: MaxContentWidth(
          maxWidth: kContentMaxWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DashSpace.lg,
              DashSpace.sm,
              DashSpace.lg,
              DashSpace.xxl,
            ),
            children: [
              _Section(
                id: 'units',
                title: l10n.settingsUnits,
                footnote: l10n.settingsUnitsMetricNote,
                children: [
                  _SettingRow(
                    label: l10n.settingsStorageBase,
                    control: _Dropdown<MeasurementSystem>(
                      label: l10n.settingsStorageBase,
                      id: 'settings.storageBase',
                      value: units.base,
                      items: MeasurementSystem.values,
                      labelOf: (s) => switch (s) {
                        MeasurementSystem.metric => l10n.baseMetric,
                        MeasurementSystem.imperial => l10n.baseImperial,
                        MeasurementSystem.imperialUk => l10n.baseImperialUk,
                      },
                      onChanged: unitsCtl.setBase,
                    ),
                  ),
                  _divider(t),
                  _SettingRow(
                    label: l10n.settingsCurrency,
                    control: _Dropdown<CurrencyOption>(
                      label: l10n.settingsCurrency,
                      id: 'settings.currency',
                      value: units.currency,
                      items: CurrencyOption.values,
                      labelOf: (c) => c.fixedSymbol == null
                          ? l10n.currencyAuto(serverSymbol)
                          : '${c.fixedSymbol} (${c.name.toUpperCase()})',
                      onChanged: unitsCtl.setCurrency,
                    ),
                  ),
                  _divider(t),
                  _SettingRow(
                    label: l10n.settingsDistance,
                    control: SegmentedButton<DistanceUnit>(
                      showSelectedIcon: false,
                      segments: [
                        for (final u in DistanceUnit.values)
                          ButtonSegment(value: u, label: Text(u.label)),
                      ],
                      selected: {units.distance},
                      onSelectionChanged: (s) => unitsCtl.setDistance(s.first),
                    ).tagged('settings.distance'),
                  ),
                  _divider(t),
                  _SettingRow(
                    label: l10n.settingsFuelEconomy,
                    control: _Dropdown<FuelEconomyUnit>(
                      label: l10n.settingsFuelEconomy,
                      id: 'settings.fuelEconomy',
                      value: units.economy,
                      items: FuelEconomyUnit.values,
                      labelOf: (e) => e.label,
                      onChanged: unitsCtl.setEconomy,
                    ),
                  ),
                  _divider(t),
                  _SettingRow(
                    label: l10n.settingsDateFormat,
                    control: _Dropdown<DateOrder>(
                      label: l10n.settingsDateFormat,
                      id: 'settings.dateFormat',
                      value: units.dateOrder,
                      items: DateOrder.values,
                      labelOf: (o) => o.labelWith(units.dateSeparator),
                      onChanged: unitsCtl.setDateOrder,
                    ),
                  ),
                  _divider(t),
                  _SettingRow(
                    label: l10n.settingsDateSeparator,
                    control: _Dropdown<DateSeparator>(
                      label: l10n.settingsDateSeparator,
                      id: 'settings.dateSeparator',
                      value: units.dateSeparator,
                      items: DateSeparator.values,
                      labelOf: (s) => units.dateOrder.labelWith(s),
                      onChanged: unitsCtl.setDateSeparator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'tabs',
                title: l10n.settingsVisibleTabs,
                footnote: l10n.settingsVisibleTabsNote,
                children: [
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Drag only from the explicit handle so the row's switch and
                    // tap-to-toggle keep working.
                    buildDefaultDragHandles: false,
                    itemCount: tabOrder.length,
                    onReorderItem: tabOrderCtl.move,
                    itemBuilder: (context, i) {
                      final tab = tabOrder[i];
                      return _TabOrderRow(
                        key: ValueKey(tab),
                        index: i,
                        icon: tab.icon,
                        label: tab.label(l10n),
                        value: visibleTabs.contains(tab),
                        onChanged: (v) => visibleTabsCtl.setVisible(tab, v),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'charts',
                title: l10n.settingsCharts,
                footnote: l10n.settingsChartsNote,
                children: [
                  _SettingRow(
                    label: l10n.settingsChartDefaultRange,
                    control: _Dropdown<ChartRangePreset>(
                      label: l10n.settingsChartDefaultRange,
                      id: 'settings.chartRange',
                      value: chartRange,
                      items: ChartRangePreset.values,
                      labelOf: (p) => chartPresetLabel(p, l10n),
                      onChanged: ref
                          .read(chartDefaultRangeProvider.notifier)
                          .set,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'fuel',
                title: l10n.settingsFuelForm,
                footnote: l10n.settingsFuelFormNote,
                children: [
                  _SettingRow(
                    label: l10n.settingsFuelCalculated,
                    // Named after the typed pair, shown as the calculated one.
                    control: _Dropdown<FuelEntryMode>(
                      id: 'settings.fuelCalculated',
                      label: l10n.settingsFuelCalculated,
                      value: ref.watch(fuelEntryModeProvider),
                      items: FuelEntryMode.values,
                      labelOf: (m) => switch (m) {
                        FuelEntryMode.costAndFuel => l10n.fuelCalculatedPrice,
                        FuelEntryMode.priceAndCost => l10n.fuelCalculatedAmount,
                        FuelEntryMode.priceAndFuel => l10n.fuelCalculatedCost,
                      },
                      onChanged: ref.read(fuelEntryModeProvider.notifier).set,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'notifications',
                title: l10n.settingsNotifications,
                footnote: l10n.settingsNotificationsNote,
                children: [
                  _ToggleRow(
                    id: 'settings.reminders',
                    icon: Icons.notifications_active_outlined,
                    label: l10n.notifRemindersToggle,
                    value: remindersOn,
                    onChanged: (v) async {
                      final ok = await remindersCtl.setEnabled(v);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.notifPermissionDenied)),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'offline',
                title: l10n.settingsOfflineSection,
                footnote: l10n.settingsBackgroundRefreshSub,
                children: [
                  _ToggleRow(
                    id: 'settings.backgroundRefresh',
                    icon: Icons.cloud_sync_outlined,
                    label: l10n.settingsBackgroundRefresh,
                    value: backgroundRefresh,
                    onChanged: ref
                        .read(backgroundRefreshProvider.notifier)
                        .setEnabled,
                  ),
                  _SettingRow(
                    label: l10n.settingsStoredData,
                    control: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.settingsStoredDataSize(
                            formatBytes(cacheBytes ?? 0),
                          ),
                          style: TextStyle(
                            fontFamily: DashTokens.fontUi,
                            fontSize: 13,
                            color: t.textTertiary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _clearStoredData(context, ref),
                          child: Text(l10n.settingsClearStoredData),
                        ).tagged('settings.clearCache'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'diagnostics',
                title: l10n.settingsDiagnostics,
                footnote: l10n.settingsDiagnosticsNote,
                children: [
                  _LinkRow(
                    id: 'settings.bugReport',
                    label: l10n.bugReportTitle,
                    onTap: () => context.push(bugReportRoute),
                  ),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'server',
                title: l10n.settingsServer,
                children: [
                  if (who?.displayName.isNotEmpty ?? profile?.label != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DashSpace.xs),
                      child: Text(
                        l10n.signedInAs(who?.displayName ?? profile!.label!),
                        style: TextStyle(
                          fontFamily: DashTokens.fontUi,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  if (who != null && who.emailAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DashSpace.sm),
                      child: Text(
                        who.emailAddress,
                        style: TextStyle(
                          fontFamily: DashTokens.fontUi,
                          fontSize: 12.5,
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  if (who != null && (who.isRoot || who.isAdmin))
                    Padding(
                      padding: const EdgeInsets.only(bottom: DashSpace.sm),
                      child: Wrap(
                        spacing: DashSpace.sm,
                        runSpacing: DashSpace.sm,
                        children: [
                          if (who.isRoot) _roleChip(t, l10n.roleRoot),
                          if (who.isAdmin) _roleChip(t, l10n.roleAdmin),
                        ],
                      ),
                    ),
                  Text(
                    profile?.baseUrl ?? '',
                    style: TextStyle(
                      fontFamily: DashTokens.fontMono,
                      fontSize: 12,
                      color: t.textTertiary,
                    ),
                  ),
                  if (who?.isRoot ?? false) ...[
                    const SizedBox(height: DashSpace.lg),
                    const _BackupButton(),
                  ],
                  const SizedBox(height: DashSpace.lg),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.dangerInk,
                      side: BorderSide(color: t.danger.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.logout),
                    onPressed: () =>
                        ref.read(serverProfileProvider.notifier).clear(),
                  ).tagged('settings.logout'),
                ],
              ),
              const SizedBox(height: DashSpace.lg),
              _Section(
                id: 'about',
                title: l10n.settingsAbout,
                children: [
                  Text(
                    packageInfo?.appName ?? l10n.appTitle,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  if (packageInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: DashSpace.xs),
                      child: Text(
                        l10n.appVersion(
                          packageInfo.version,
                          packageInfo.buildNumber,
                        ),
                        style: TextStyle(
                          fontFamily: DashTokens.fontMono,
                          fontSize: 12,
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                  if (serverVersion != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: DashSpace.xs),
                      child: Text(
                        l10n.serverVersionLabel(serverVersion.currentVersion),
                        style: TextStyle(
                          fontFamily: DashTokens.fontMono,
                          fontSize: 12,
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                    if (serverVersion.updateAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: DashSpace.sm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.system_update_alt,
                              size: 15,
                              color: t.accentGold,
                            ),
                            const SizedBox(width: DashSpace.sm),
                            Flexible(
                              child: Text(
                                l10n.updateAvailable(
                                  serverVersion.latestVersion,
                                ),
                                style: TextStyle(
                                  fontFamily: DashTokens.fontUi,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: t.accentGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  _divider(t),
                  _LinkRow(
                    id: 'settings.licenses',
                    label: l10n.openSourceLicenses,
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: packageInfo?.appName ?? l10n.appTitle,
                      applicationVersion: packageInfo?.version,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(DashTokens t) =>
      Divider(height: 20, thickness: 1, color: t.hairline);

  /// Drops the offline copy and everything derived from it, so the next screen
  /// re-reads from the server. The write queue is untouched — those are the
  /// user's unsent changes, not a copy of anything.
  Future<void> _clearStoredData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(apiClientProvider).cache.clear();
    invalidateAllData(ref.invalidate);
    ref.invalidate(cacheSizeProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsStoredDataCleared)),
    );
  }

  /// A small pill labelling an account role (Admin / Root).
  Widget _roleChip(DashTokens t, String label) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DashSpace.sm,
      vertical: DashSpace.xs,
    ),
    decoration: BoxDecoration(
      color: t.accentGold.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: t.accentGold.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: t.accentGoldInk,
      ),
    ),
  );
}

/// Root-only "create backup" button that triggers a server-side backup and
/// reports the result, showing a spinner while the request is in flight.
class _BackupButton extends ConsumerStatefulWidget {
  const _BackupButton();

  @override
  ConsumerState<_BackupButton> createState() => _BackupButtonState();
}

class _BackupButtonState extends ConsumerState<_BackupButton> {
  bool _busy = false;

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(vehiclesRepositoryProvider).makeBackup();
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupCreated)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.backup_outlined, size: 18),
      label: Text(l10n.settingsBackup),
    ).tagged('settings.backup');
  }
}

/// A titled card grouping related settings, with an optional footnote caption.
class _Section extends StatelessWidget {
  const _Section({
    required this.id,
    required this.title,
    this.footnote,
    required this.children,
  });

  /// Unlocalized name for the log; the title is user-facing text. One surface
  /// per section is what names every control inside it without tagging each.
  final String id;

  final String title;
  final List<Widget> children;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return logSurface(
      'settings.$id',
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DashSpace.lg),
        decoration: BoxDecoration(
          gradient: t.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: DashSpace.md),
            ...children,
            if (footnote != null) ...[
              const SizedBox(height: DashSpace.md),
              Text(
                footnote!,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 11.5,
                  color: t.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tappable row that navigates elsewhere (e.g. the licenses page): label on
/// the left, chevron on the right.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.id, required this.label, required this.onTap});

  /// Log identifier of the row.
  final String id;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return logTag(
      id,
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DashSpace.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: t.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A label on the left with its control right-aligned.
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    // A Wrap, not a Row: when the control is too wide to share the line (narrow
    // phone, large text), it drops below the label instead of squeezing the
    // label into a column of single letters. Full width so spaceBetween can
    // push a control that shares the line to the right edge.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DashSpace.md,
        runSpacing: DashSpace.sm,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          control,
        ],
      ),
    );
  }
}

/// An icon + label with a trailing switch; the whole row is tappable. Used for
/// the visible-tabs toggles.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Log identifier of the row; the switch in it inherits it.
  final String id;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return logTag(
      id,
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DashSpace.xs),
          child: Row(
            children: [
              Icon(icon, size: 18, color: t.textTertiary),
              const SizedBox(width: DashSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              Semantics(
                label: label,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: t.accentGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A visible-tabs row that is both reorderable and toggleable: a drag handle
/// (starts the reorder), the tab icon + label (tap toggles), and a trailing
/// switch. [index] is the row's position for [ReorderableDragStartListener].
class _TabOrderRow extends StatelessWidget {
  const _TabOrderRow({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final int index;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DashSpace.xs),
      child: Row(
        children: [
          logTag(
            'settings.tabOrder.drag',
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: DashSpace.sm),
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: t.textTertiary,
                ),
              ),
            ),
          ),
          Expanded(
            child: logTag(
              'settings.tabOrder.row',
              Semantics(
                label: label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(!value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: kMinInteractiveDimension,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: t.textTertiary),
                        const SizedBox(width: DashSpace.md),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: DashTokens.fontUi,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: label,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: t.accentGold,
            ),
          ).tagged('settings.tabOrder.toggle'),
        ],
      ),
    );
  }
}

/// Themed dropdown for an enum-backed setting.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.id,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  /// Log identifier of the select; each row carries `<id>.option`, since the
  /// menu opens in a route the select's tag does not reach.
  final String id;

  /// The setting's name. It goes **inside** the tag: a tag is a node of its own and
  /// does not take the label of a `Semantics` around it, so there it would never
  /// reach the node that holds the tap.
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    // As wide as its longest option, like a plain DropdownButton, but no wider
    // than the row: at large text sizes the option wraps instead of running off
    // the screen edge. isExpanded lets it wrap, and itemHeight: null lets the
    // button grow to show the second line (the default clips it at 48).
    return IntrinsicWidth(
      child: DropdownButtonHideUnderline(
        child: Semantics(
          label: label,
          child: DropdownButton<T>(
            isExpanded: true,
            itemHeight: null,
            value: value,
            borderRadius: BorderRadius.circular(14),
            dropdownColor: t.overlaySurface,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
            icon: Icon(Icons.arrow_drop_down, color: t.textSecondary),
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item,
                  // The button an option is takes its name from here; the tag below
                  // names the option for the log and is not tappable itself.
                  child: Semantics(
                    label: labelOf(item),
                    child: logTag(
                      '$id.option',
                      ExcludeSemantics(child: Text(labelOf(item))),
                    ),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ).tagged(id),
      ),
    );
  }
}
