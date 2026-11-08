import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format/chart_range.dart';
import '../../core/format/expense_timeline.dart';
import '../../core/format/formatters.dart';
import '../../core/format/gas_stats.dart';
import '../../core/layout/responsive.dart';
import '../../core/models/vehicle_info.dart';
import '../../core/format/vehicle_units.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import 'widgets/chart_palette.dart';
import 'widgets/chart_range_sheet.dart';
import 'widgets/dashboard_charts.dart';

String _categoryLabel(ExpenseCategory category, AppLocalizations l10n) =>
    switch (category) {
      ExpenseCategory.service => l10n.catService,
      ExpenseCategory.repair => l10n.catRepairs,
      ExpenseCategory.upgrade => l10n.catUpgrades,
      ExpenseCategory.fuel => l10n.catFuel,
      ExpenseCategory.tax => l10n.catTax,
    };

/// Vehicle dashboard (design screen #5): at-a-glance stats plus expense,
/// reminder, and fuel-mileage charts for one vehicle. Rendered as the first tab
/// of [VehicleScreen], which supplies the surrounding chrome and vehicle header.
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final infoAsync = ref.watch(vehicleInfoProvider(vehicleId));

    Future<void> refresh() async {
      invalidateVehicleData(ref.invalidate, vehicleId);
      await ref.read(vehicleInfoProvider(vehicleId).future);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          // Its own scroll view, so the enclosing RefreshIndicator still
          // has something to pull.
          scrollable: true,
          message: l10n.dashLoadError,
          onRetry: refresh,
          retryLabel: l10n.retry,
        ),
        data: (info) => _DashboardBody(vehicleId: vehicleId, info: info),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.vehicleId, required this.info});

  final int vehicleId;
  final VehicleInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final stats = ref.watch(gasStatsProvider(vehicleId)).value;
    final timeline = ref.watch(expenseTimelineProvider(vehicleId)).value;
    final t = DashTokens.of(context);
    final now = DateTime.now();
    // MaterialLocalizations counts from Sunday = 0; DateTime from Monday = 1.
    final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstDayOfWeek = firstDayIndex == 0 ? DateTime.sunday : firstDayIndex;

    ({ChartRange range, ChartWindow window, Widget chip}) rangeOf(
      DashboardChart chart,
      String title,
    ) {
      final key = (vehicleId: vehicleId, chart: chart);
      final range = ref.watch(chartRangeProvider(key));
      final window = range.resolve(now, firstDayOfWeek: firstDayOfWeek);
      final label = chartRangeChipLabel(range, l10n, now);
      return (
        range: range,
        window: window,
        chip: ChartRangeChip(
          label: label,
          semanticLabel: l10n.chartRangeButton(label),
          custom: range is CustomRange,
          onTap: () async {
            final picked = await showChartRangeSheet(
              context,
              chartTitle: title,
              current: range,
              defaultPreset: ref.read(chartDefaultRangeProvider),
              currentWindow: window,
              formatDate: units.formatDate,
            );
            if (picked != null && context.mounted) {
              ref.read(chartRangeOverridesProvider.notifier).set(key, picked);
            }
          },
        ).tagged('dashboard.chartRange'),
      );
    }

    final byTypeTitle = l10n.chartExpensesByType;
    final byType = rangeOf(DashboardChart.expensesByType, byTypeTitle);
    final byTypeTotals = timeline?.totalsIn(byType.window) ?? const {};

    final expensesTitle = l10n.chartExpensesDistance;
    final expenses = rangeOf(DashboardChart.expensesDistance, expensesTitle);
    final expenseBuckets = timeline?.bucketed(expenses.window);

    final economyTitle =
        '${units.isElectric ? l10n.chartConsumption : l10n.chartFuelMileage}'
        ' (${units.economyLabel})';
    final economy = rangeOf(DashboardChart.economy, economyTitle);

    double? toEconomy(double? raw) =>
        raw == null ? null : units.economyValue(raw, 1);

    final categoryLabels = {
      for (final c in ExpenseCategory.values) c: _categoryLabel(c, l10n),
    };
    final today = dateOnly(now);

    // Charts flow two-up on wider (landscape) screens, single column on
    // portrait phones. Off-screen ones are left unbuilt: a chart is expensive to
    // lay out and paint, and on a phone at most two are ever in view.
    final charts = <Widget>[
      ChartCard(
        title: byTypeTitle,
        trailing: byType.chip,
        child: CategoryShareChart(
          emptyLabel: l10n.chartNoDataInRange,
          items: [
            for (final c in chartCategoryOrder)
              ShareItem(
                label: categoryLabels[c]!,
                value: byTypeTotals[c] ?? 0,
                color: categoryColor(c, t),
                valueLabel: Formatters.currency(byTypeTotals[c] ?? 0, symbol),
              ),
          ],
        ),
      ),
      ChartCard(
        title: expensesTitle,
        trailing: expenses.chip,
        child: ExpenseDistanceChart(
          slots: _slots(expenses.window, l10n),
          data: [
            for (final b in expenseBuckets ?? const <ExpenseBucket>[])
              ExpenseSlot(
                costs: b.byCategory,
                distance: units.toDisplayDistance(b.distance),
              ),
            if (expenseBuckets == null)
              for (final _ in expenses.window.bucketStarts)
                const ExpenseSlot(costs: {}, distance: 0),
          ],
          categoryLabels: categoryLabels,
          currencySymbol: symbol,
          expensesLabel: l10n.legendExpenses,
          distanceLabel: l10n.legendDistance,
          distanceUnit: units.distanceLabel,
          totalLabel: l10n.chartTotal,
          emptyLabel: l10n.chartNoDataInRange,
          emphasizeLast: expenses.window.end == today,
        ),
      ),
      ChartCard(
        title: l10n.chartRemindersByUrgency,
        trailing: Text(
          l10n.chartRemindersTotal(
            info.pastDueReminderCount +
                info.veryUrgentReminderCount +
                info.urgentReminderCount +
                info.notUrgentReminderCount,
          ),
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: t.textTertiary,
          ),
        ),
        child: UrgencyChart(
          emptyLabel: l10n.chartNoReminders,
          items: [
            UrgencyItem(
              label: l10n.urgencyPastDue,
              count: info.pastDueReminderCount,
              color: t.danger,
            ),
            UrgencyItem(
              label: l10n.urgencyVeryUrgent,
              count: info.veryUrgentReminderCount,
              color: t.accentOrange,
            ),
            UrgencyItem(
              label: l10n.urgencyUrgent,
              count: info.urgentReminderCount,
              color: t.warning,
            ),
            UrgencyItem(
              label: l10n.urgencyNotUrgent,
              count: info.notUrgentReminderCount,
              color: okStatusColor(t),
            ),
          ],
        ),
      ),
      ChartCard(
        title: economyTitle,
        trailing: economy.chip,
        child: EconomyChart(
          slots: _slots(economy.window, l10n),
          values: [
            for (final raw
                in stats?.economyByBucket(economy.window) ??
                    List<double?>.filled(
                      economy.window.bucketStarts.length,
                      null,
                    ))
              toEconomy(raw),
          ],
          average: toEconomy(stats?.averageRatioIn(economy.window)),
          unitLabel: units.economyLabel,
          averageLabel: l10n.chartAverage,
          emptyLabel: l10n.chartNoDataInRange,
          emphasizeLast: economy.window.end == today,
        ),
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            DashSpace.lg,
            DashSpace.lg,
            DashSpace.lg,
            DashSpace.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: _StatBlock(
              info: info,
              stats: stats,
              units: units,
              symbol: symbol,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, fabScrollClearance(context)),
          sliver: SliverResponsiveCards(
            maxColumns: 2,
            spacing: DashSpace.lg,
            runSpacing: DashSpace.lg,
            itemCount: charts.length,
            itemBuilder: (context, index) => charts[index],
          ),
        ),
      ],
    );
  }

  /// Axis and tooltip names for every slot of [window]. Week slots carry the
  /// year in their tooltip only.
  List<TimeSlot> _slots(ChartWindow window, AppLocalizations l10n) {
    final locale = l10n.localeName;
    final starts = window.bucketStarts;
    return [
      for (final start in starts)
        switch (window.bucket) {
          ChartBucket.week => () {
            final days = window.daysOf(start);
            return TimeSlot(
              axisLabel: DateFormat.Md(locale).format(days.first),
              title: days.first == days.last
                  ? DateFormat.yMMMd(locale).format(days.first)
                  : '${DateFormat.MMMd(locale).format(days.first)} – '
                        '${DateFormat.yMMMd(locale).format(days.last)}',
            );
          }(),
          ChartBucket.month => TimeSlot(
            axisLabel: DateFormat.LLL(locale).format(start),
            year: start.year,
            title: DateFormat.yMMMM(locale).format(start),
          ),
          ChartBucket.quarter => () {
            final quarter = (start.month - 1) ~/ 3 + 1;
            return TimeSlot(
              axisLabel: l10n.chartQuarter(quarter),
              year: start.year,
              title: '${l10n.chartQuarter(quarter)} ${start.year}',
            );
          }(),
        },
    ];
  }
}

/// The four headline stats — odometer, distance, total cost, avg economy — as
/// rows of one card: stacked in portrait, two columns side by side when wide.
class _StatBlock extends ConsumerWidget {
  const _StatBlock({
    required this.info,
    required this.stats,
    required this.units,
    required this.symbol,
  });

  final VehicleInfo info;
  final GasStats? stats;
  final VehicleUnits units;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    final lastOdometerDate = ref
        .watch(lastOdometerDateProvider(info.vehicle.id))
        .value;

    final rows = [
      _StatRow(
        icon: Icons.speed_outlined,
        label: l10n.colOdometer,
        value: units.distance(info.lastReportedOdometer),
        secondary: lastOdometerDate == null
            ? null
            : units.formatDate(lastOdometerDate),
      ),
      _StatRow(
        icon: Icons.route_outlined,
        label: l10n.statDistanceTraveled,
        value: stats == null ? '—' : units.distance(stats!.distanceSpan),
      ),
      _StatRow(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.statTotalCost,
        value: Formatters.currency(info.totalCost, symbol),
      ),
      _StatRow(
        icon: units.isElectric
            ? Icons.ev_station_outlined
            : Icons.local_gas_station_outlined,
        label: units.isElectric ? l10n.statAvgConsumption : l10n.statAvgEconomy,
        value: stats == null
            ? '—'
            : units.economy(stats!.totalRawDistance, stats!.totalRawVolume),
      ),
    ];

    final divider = Padding(
      padding: const EdgeInsets.only(left: _StatRow.textInset),
      child: Divider(height: 1, thickness: 1, color: t.hairline),
    );

    // Two columns only once each has room for a long label beside a long
    // value; lines are paired so both cells of a line share its height and
    // the dividers meet.
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final lines = constraints.maxWidth >= 2 * _StatRow.minWidth + 16
            ? [for (var i = 0; i < rows.length; i += 2) rows.sublist(i, i + 2)]
            : [
                for (final row in rows) [row],
              ];
        return Column(
          children: [
            for (final (i, line) in lines.indexed) ...[
              if (i > 0)
                Row(
                  children: [
                    for (final (j, _) in line.indexed) ...[
                      if (j > 0) const SizedBox(width: DashSpace.lg),
                      Expanded(child: divider),
                    ],
                  ],
                ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (j, row) in line.indexed) ...[
                      if (j > 0) const SizedBox(width: DashSpace.lg),
                      Expanded(child: row),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );

    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: t.cardGradient,
        borderRadius: radius,
        border: Border.all(color: t.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.3,
                    stops: const [0, 0.6],
                    colors: [
                      t.accent.withValues(alpha: t.isDark ? 0.16 : 0.12),
                      t.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 24,
              right: 24,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      t.accent.withValues(alpha: 0),
                      t.accent.withValues(alpha: 0.55),
                      t.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DashSpace.lg,
                vertical: DashSpace.sm,
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.secondary,
  });

  /// Where the label starts, past the icon chip; row dividers start here too.
  static const double textInset = _chipSize + 12;

  /// Narrowest a row gets side by side with another.
  static const double minWidth = 330;
  static const double _chipSize = 30;

  final IconData icon;
  final String label;
  final String value;

  /// A small line under the label (the date of the odometer reading).
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Container(
              width: _chipSize,
              height: _chipSize,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: t.isDark ? 0.12 : 0.14),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: t.accent.withValues(alpha: 0.22)),
              ),
              child: Icon(icon, size: 17, color: t.accentInk),
            ),
            const SizedBox(width: DashSpace.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: DashSpace.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textSecondary,
                      ),
                    ),
                    if (secondary != null)
                      Text(
                        secondary!,
                        style: TextStyle(
                          fontFamily: DashTokens.fontMono,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: t.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: DashSpace.md),
            Text(
              value,
              style: TextStyle(
                fontFamily: DashTokens.fontMono,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
