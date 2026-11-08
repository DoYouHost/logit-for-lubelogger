import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/vehicle_record.dart';
import '../../core/models/vehicle_tab.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../common/vehicle_tab_ui.dart';
import 'forms/add_equipment_form.dart';
import 'forms/add_fuel_form.dart';
import 'forms/add_generic_record_form.dart';
import 'forms/add_note_form.dart';
import 'forms/add_odometer_form.dart';
import 'forms/add_plan_form.dart';
import 'forms/add_reminder_form.dart';
import 'forms/add_supply_form.dart';

/// FAB picker: choose a record type to add, then open its form. [tabs] is the
/// vehicle's visible record tabs in the user's chosen order (see
/// [tabOrderProvider]); [hiddenTabs] sit in a collapsed section below them, so
/// hiding a tab never makes its records impossible to add.
Future<void> showAddRecordSheet(
  BuildContext context,
  int vehicleId,
  List<VehicleTab> tabs,
  List<VehicleTab> hiddenTabs,
) async {
  if (tabs.isEmpty && hiddenTabs.isEmpty) return;

  final picked = await dashSheet<VehicleTab>(
    context,
    scrollControlled: false,
    builder: (_) => _AddRecordGrid(options: tabs, hidden: hiddenTabs),
  );
  if (picked == null || !context.mounted) return;
  await showAddRecordForm(context, vehicleId, picked);
}

/// Opens the add form for [tab]'s record type. A tab with no form falls back to
/// a "coming soon" notice.
Future<void> showAddRecordForm(
  BuildContext context,
  int vehicleId,
  VehicleTab tab,
) async {
  final kind = _recordKindForTab(tab);
  if (kind != null) {
    await showGenericRecordForm(context, vehicleId, kind);
    return;
  }
  switch (tab) {
    case VehicleTab.fuel:
      await showAddFuelForm(context, vehicleId);
    case VehicleTab.odometer:
      await showAddOdometerForm(context, vehicleId);
    case VehicleTab.supply:
      await showAddSupplyForm(context, vehicleId);
    case VehicleTab.plan:
      await showAddPlanForm(context, vehicleId);
    case VehicleTab.reminder:
      await showAddReminderForm(context, vehicleId);
    case VehicleTab.note:
      await showAddNoteForm(context, vehicleId);
    case VehicleTab.equipment:
      await showAddEquipmentForm(context, vehicleId);
    case VehicleTab.service ||
        VehicleTab.repair ||
        VehicleTab.upgrade ||
        VehicleTab.tax:
      // Handled by the generic-record branch above; unreachable here.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
      );
  }
}

/// The generic (date + cost) record kind a tab maps to, or null for tabs with
/// their own bespoke form (fuel/odometer/supply/plan/reminder/note/equipment).
RecordKind? _recordKindForTab(VehicleTab tab) => switch (tab) {
  VehicleTab.service => RecordKind.service,
  VehicleTab.repair => RecordKind.repair,
  VehicleTab.upgrade => RecordKind.upgrade,
  VehicleTab.tax => RecordKind.tax,
  _ => null,
};

/// The record types as a scrollable two-column grid of tiles, with the hidden
/// tabs' types in a collapsed section underneath.
class _AddRecordGrid extends StatefulWidget {
  const _AddRecordGrid({required this.options, required this.hidden});

  final List<VehicleTab> options;
  final List<VehicleTab> hidden;

  @override
  State<_AddRecordGrid> createState() => _AddRecordGridState();
}

class _AddRecordGridState extends State<_AddRecordGrid> {
  bool _showHidden = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    // Only the bottom inset (gesture bar) matters here: the sheet is centered
    // via its width constraint, so applying the landscape display-cutout inset
    // on the notch side would shove the grid off-centre.
    return logSurface(
      'add_sheet',
      SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DashSpace.xl,
                0,
                DashSpace.xl,
                DashSpace.md,
              ),
              child: Text(
                l10n.addRecordTitle,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ),
            // Scrolls when the content is taller than the sheet's max height.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  DashSpace.lg,
                  0,
                  DashSpace.lg,
                  DashSpace.sm,
                ),
                children: [
                  _tileGrid(widget.options),
                  if (widget.hidden.isNotEmpty) ...[
                    _HiddenToggle(
                      count: widget.hidden.length,
                      expanded: _showHidden,
                      onTap: () => setState(() => _showHidden = !_showHidden),
                    ).tagged('add_sheet.hidden'),
                    if (_showHidden) _tileGrid(widget.hidden),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileGrid(List<VehicleTab> tabs) => GridView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: DashSpace.md,
      crossAxisSpacing: DashSpace.md,
      mainAxisExtent: 60,
    ),
    children: [
      for (final tab in tabs)
        _RecordTypeTile(
          tab: tab,
          onTap: () => Navigator.pop(context, tab),
        ).tagged('add_sheet.${tab.name}'),
    ],
  );
}

/// The "Hidden records (n)" header that expands the hidden tabs' grid.
class _HiddenToggle extends StatelessWidget {
  const _HiddenToggle({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DashSpace.sm,
          vertical: DashSpace.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).addRecordHidden(count),
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.textSecondary,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: t.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// One record-type cell: gold icon chip + label, styled like a subcard.
class _RecordTypeTile extends StatelessWidget {
  const _RecordTypeTile({required this.tab, required this.onTap});

  final VehicleTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final radius = BorderRadius.circular(14);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.subCard,
        borderRadius: radius,
        border: Border.all(color: t.subCardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DashSpace.md,
            vertical: DashSpace.sm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: t.accentGold.withValues(alpha: 0.16),
                foregroundColor: t.accentGoldInk,
                child: Icon(tab.icon, size: 18),
              ),
              const SizedBox(width: DashSpace.md),
              Expanded(
                child: Text(
                  tab.label(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
