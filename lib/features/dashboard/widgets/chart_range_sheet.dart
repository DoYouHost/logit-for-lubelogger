import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/format/chart_range.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';

String chartPresetLabel(ChartRangePreset preset, AppLocalizations l10n) =>
    switch (preset) {
      ChartRangePreset.oneMonth => l10n.chartRangeOneMonth,
      ChartRangePreset.threeMonths => l10n.chartRangeThreeMonths,
      ChartRangePreset.sixMonths => l10n.chartRangeSixMonths,
      ChartRangePreset.year => l10n.chartRangeYear,
    };

/// The label on a chart's range button: a short preset name, or the two dates
/// of a custom range, with the year said once when both share it and left out
/// when that is the current one.
String chartRangeChipLabel(
  ChartRange range,
  AppLocalizations l10n,
  DateTime now,
) => switch (range) {
  PresetRange(:final preset) => switch (preset) {
    ChartRangePreset.oneMonth => l10n.chartRangeOneMonthShort,
    ChartRangePreset.threeMonths => l10n.chartRangeThreeMonthsShort,
    ChartRangePreset.sixMonths => l10n.chartRangeSixMonthsShort,
    ChartRangePreset.year => l10n.chartRangeYearShort,
  },
  CustomRange(:final start, :final end) => () {
    final dayMonth = DateFormat.MMMd(l10n.localeName);
    final full = DateFormat.yMMMd(l10n.localeName);
    if (start.year != end.year) {
      return '${full.format(start)} – ${full.format(end)}';
    }
    final last = end.year == now.year ? dayMonth : full;
    return '${dayMonth.format(start)} – ${last.format(end)}';
  }(),
};

/// Lets the user pick the range [chartTitle] is shown over. Resolves to the
/// picked range, or null when dismissed — including a cancelled date picker.
Future<ChartRange?> showChartRangeSheet(
  BuildContext context, {
  required String chartTitle,
  required ChartRange current,
  required ChartRangePreset defaultPreset,
  required ChartWindow currentWindow,
  required String Function(DateTime) formatDate,
}) async {
  final picked = await dashSheet<Object>(
    context,
    builder: (_) => _RangeSheet(
      chartTitle: chartTitle,
      current: current,
      defaultPreset: defaultPreset,
      formatDate: formatDate,
    ),
  );
  if (picked is ChartRange) return picked;
  if (picked != _customRequested || !context.mounted) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final initialEnd = currentWindow.end.isAfter(today)
      ? today
      : currentWindow.end;
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(1900),
    lastDate: today,
    currentDate: today,
    initialDateRange: DateTimeRange(
      start: currentWindow.start.isAfter(initialEnd)
          ? initialEnd
          : currentWindow.start,
      end: initialEnd,
    ),
  );
  return range == null ? null : CustomRange(range.start, range.end);
}

/// Popped by the sheet's custom option, which opens the date picker only once
/// the sheet is gone.
const _customRequested = #customRange;

class _RangeSheet extends StatelessWidget {
  const _RangeSheet({
    required this.chartTitle,
    required this.current,
    required this.defaultPreset,
    required this.formatDate,
  });

  final String chartTitle;
  final ChartRange current;
  final ChartRangePreset defaultPreset;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final range = current;
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DashSpace.lg,
          0,
          DashSpace.lg,
          DashSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DashSpace.xs,
                0,
                DashSpace.xs,
                DashSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chartRangeTitle,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DashSpace.xs),
                  Text(
                    chartTitle,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: t.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            for (final preset in ChartRangePreset.values)
              _Option(
                id: 'chartRange.preset',
                label: chartPresetLabel(preset, l10n),
                selected: range is PresetRange && range.preset == preset,
                badge: preset == defaultPreset ? l10n.chartRangeDefault : null,
                onTap: () => Navigator.pop(context, PresetRange(preset)),
              ),
            _Option(
              id: 'chartRange.custom',
              label: l10n.chartRangeCustom,
              selected: range is CustomRange,
              detail: range is CustomRange
                  ? '${formatDate(range.start)} – ${formatDate(range.end)}'
                  : null,
              trailing: Icons.calendar_month_outlined,
              onTap: () => Navigator.pop(context, _customRequested),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DashSpace.xs,
                DashSpace.md,
                DashSpace.xs,
                0,
              ),
              child: Text(
                l10n.chartRangeSettingsHint,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 11.5,
                  color: t.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.detail,
    this.trailing,
  });

  /// Log identifier: every preset shares one, the custom range has its own.
  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  /// A second line under the label (a custom range's dates).
  final String? detail;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? t.accent.withValues(alpha: 0.35) : Colors.transparent,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.xs),
      child: Material(
        color: selected ? t.accent.withValues(alpha: 0.10) : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Semantics(
            selected: selected,
            inMutuallyExclusiveGroup: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashSpace.md,
                  vertical: DashSpace.sm,
                ),
                child: Row(
                  children: [
                    _RadioMark(selected: selected),
                    const SizedBox(width: DashSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: DashSpace.sm,
                            runSpacing: DashSpace.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                              if (badge != null)
                                DashPill(
                                  label: badge!,
                                  accent: t.accent,
                                  accentInk: t.accentInk,
                                  dense: true,
                                ),
                            ],
                          ),
                          if (detail != null)
                            Padding(
                              padding: const EdgeInsets.only(top: DashSpace.xs),
                              child: Text(
                                detail!,
                                style: TextStyle(
                                  fontFamily: DashTokens.fontMono,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null)
                      Icon(trailing, size: 20, color: t.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).tagged(id);
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? t.accent : null,
        border: selected ? null : Border.all(color: t.textTertiary, width: 1.5),
      ),
      child: selected ? Icon(Icons.check, size: 14, color: t.onAccent) : null,
    );
  }
}
