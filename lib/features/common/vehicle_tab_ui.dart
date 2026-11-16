import 'package:material_ui/material_ui.dart';

import '../../core/models/vehicle_tab.dart';
import '../../l10n/app_localizations.dart';

/// Presentation for [VehicleTab]: the icon and localized label shared by the
/// tab bar, the FAB add sheet, and the visible-tabs setting. Kept out of the
/// pure model so the enum carries no Flutter/l10n dependency.
extension VehicleTabUi on VehicleTab {
  IconData get icon => switch (this) {
    VehicleTab.odometer => Icons.speed,
    VehicleTab.service => Icons.build_circle_outlined,
    VehicleTab.repair => Icons.report_outlined,
    VehicleTab.upgrade => Icons.upgrade,
    VehicleTab.fuel => Icons.local_gas_station,
    VehicleTab.tax => Icons.request_quote_outlined,
    VehicleTab.supply => Icons.inventory_2_outlined,
    VehicleTab.plan => Icons.checklist_rtl,
    VehicleTab.reminder => Icons.notifications_active_outlined,
    VehicleTab.note => Icons.sticky_note_2_outlined,
    VehicleTab.equipment => Icons.handyman_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    VehicleTab.odometer => l10n.tabOdometer,
    VehicleTab.service => l10n.catService,
    VehicleTab.repair => l10n.catRepairs,
    VehicleTab.upgrade => l10n.catUpgrades,
    VehicleTab.fuel => l10n.catFuel,
    VehicleTab.tax => l10n.catTax,
    VehicleTab.supply => l10n.catSupply,
    VehicleTab.plan => l10n.catPlan,
    VehicleTab.reminder => l10n.catReminder,
    VehicleTab.note => l10n.catNote,
    VehicleTab.equipment => l10n.catEquipment,
  };
}
