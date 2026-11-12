import 'package:material_ui/material_ui.dart';

import '../../../core/format/expense_timeline.dart';
import '../../../core/theme/dash_theme.dart';

/// The order categories are stacked, segmented and listed in. The palette below
/// was checked for colour-blind separation between neighbours in this order, so
/// reordering it undoes that check.
const chartCategoryOrder = [
  ExpenseCategory.fuel,
  ExpenseCategory.service,
  ExpenseCategory.upgrade,
  ExpenseCategory.tax,
  ExpenseCategory.repair,
];

/// Category swatches, stepped separately for each theme's surface. None of them
/// is a status colour: tax used to borrow `danger`, which also read as an error.
Color categoryColor(ExpenseCategory category, DashTokens t) =>
    switch ((category, t.isDark)) {
      (ExpenseCategory.fuel, true) => const Color(0xFFBF881E),
      (ExpenseCategory.fuel, false) => const Color(0xFFD49824),
      (ExpenseCategory.service, true) => const Color(0xFF3A84CA),
      (ExpenseCategory.service, false) => const Color(0xFF116BB5),
      (ExpenseCategory.upgrade, true) => const Color(0xFFA83876),
      (ExpenseCategory.upgrade, false) => const Color(0xFFA02262),
      (ExpenseCategory.tax, true) => const Color(0xFF2BA996),
      (ExpenseCategory.tax, false) => const Color(0xFF29A895),
      (ExpenseCategory.repair, true) => const Color(0xFF7860B5),
      (ExpenseCategory.repair, false) => const Color(0xFF5D4099),
    };

/// The brand gold is too pale for a 2 px line on the light card.
Color economyLineColor(DashTokens t) =>
    t.isDark ? t.accent : const Color(0xFFB8820F);

/// "Not urgent" — the one status the shared tokens have no colour for.
Color okStatusColor(DashTokens t) =>
    t.isDark ? const Color(0xFF4CAF6E) : const Color(0xFF3E9A5E);
