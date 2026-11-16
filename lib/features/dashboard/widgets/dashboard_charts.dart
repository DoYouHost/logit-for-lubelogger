import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/format/expense_timeline.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/dash_theme.dart';
import 'chart_palette.dart';

/// Card chrome shared by every chart block: translucent card gradient, hairline
/// border, the title with an optional [trailing] control, then the [child].
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DashSpace.lg),
      decoration: BoxDecoration(
        gradient: t.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: DashSpace.md),
                  trailing!,
                ],
              ],
            ),
          ),
          const SizedBox(height: DashSpace.lg),
          child,
        ],
      ),
    );
  }
}

/// The pill in a card header naming the chart's range; tapping it opens the
/// range sheet.
class ChartRangeChip extends StatelessWidget {
  const ChartRangeChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.custom = false,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  /// A custom range carries a calendar mark, telling it apart from a preset.
  final bool custom;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: t.subCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.subCardBorder),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DashSpace.md,
                DashSpace.xs,
                DashSpace.sm,
                DashSpace.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (custom) ...[
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 13,
                      color: t.textSecondary,
                    ),
                    const SizedBox(width: DashSpace.xs),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: t.textSecondary,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: t.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One category of a [CategoryShareChart].
class ShareItem {
  const ShareItem({
    required this.label,
    required this.value,
    required this.color,
    required this.valueLabel,
  });

  final String label;
  final double value;
  final Color color;
  final String valueLabel;
}

/// Part-to-whole as one 100% bar plus a row per category with its amount and
/// share. Categories at zero stay listed, muted, so rows don't jump as the
/// range changes.
class CategoryShareChart extends StatelessWidget {
  const CategoryShareChart({
    super.key,
    required this.items,
    required this.emptyLabel,
  });

  final List<ShareItem> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final total = items.fold<double>(0, (sum, i) => sum + i.value);
    if (total <= 0) return _NoData(label: emptyLabel, height: 96);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SegmentBar(
          height: 12,
          segments: [for (final i in items) (color: i.color, value: i.value)],
        ),
        const SizedBox(height: DashSpace.lg),
        for (final item in items)
          _ShareRow(
            item: item,
            share: total > 0 && item.value > 0
                ? '${Formatters.number(item.value / total * 100, decimals: 1)}%'
                : null,
            t: t,
          ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.item, required this.share, required this.t});

  final ShareItem item;

  /// Null for a category with nothing spent.
  final String? share;
  final DashTokens t;

  @override
  Widget build(BuildContext context) {
    final muted = share == null;
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.hairline)),
      ),
      child: Row(
        children: [
          _Swatch(color: item.color, size: 10, radius: 3, hollow: muted),
          const SizedBox(width: DashSpace.md),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted ? t.textTertiary : t.textSecondary,
              ),
            ),
          ),
          Text(
            item.valueLabel,
            style: TextStyle(
              fontFamily: DashTokens.fontMono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: muted ? t.textTertiary : t.textPrimary,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              share ?? '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: DashTokens.fontMono,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: t.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One urgency level of an [UrgencyChart].
class UrgencyItem {
  const UrgencyItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

/// Reminder counts by urgency: a proportion bar over one tile per level, most
/// urgent first.
class UrgencyChart extends StatelessWidget {
  const UrgencyChart({
    super.key,
    required this.items,
    required this.emptyLabel,
  });

  final List<UrgencyItem> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    if (items.every((i) => i.count == 0)) {
      return _NoData(label: emptyLabel, height: 96);
    }
    Widget tile(UrgencyItem item) => Container(
      padding: const EdgeInsets.fromLTRB(
        DashSpace.md,
        DashSpace.md,
        DashSpace.md,
        DashSpace.sm,
      ),
      decoration: BoxDecoration(
        color: t.subCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.subCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Swatch(color: item.color, size: 8, radius: 4),
              const SizedBox(width: DashSpace.sm),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DashSpace.xs),
          Text(
            '${item.count}',
            style: TextStyle(
              fontFamily: DashTokens.fontMono,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: item.count == 0 ? t.textTertiary : t.textPrimary,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SegmentBar(
          height: 10,
          segments: [
            for (final i in items) (color: i.color, value: i.count.toDouble()),
          ],
        ),
        const SizedBox(height: DashSpace.lg),
        for (var row = 0; row < items.length; row += 2) ...[
          if (row > 0) const SizedBox(height: DashSpace.sm),
          Row(
            children: [
              Expanded(child: tile(items[row])),
              const SizedBox(width: DashSpace.sm),
              Expanded(
                child: row + 1 < items.length
                    ? tile(items[row + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One slot on a chart's time axis.
class TimeSlot {
  const TimeSlot({required this.axisLabel, required this.title, this.year});

  /// Short label under the slot (`15.06`, `Sep`, `Q3`); thinned out when they
  /// don't all fit.
  final String axisLabel;

  /// Printed under the first visible label of each year; null for slots whose
  /// label already pins the date down.
  final int? year;

  /// Full name of the slot for its tooltip (`20 – 26 Jul 2026`).
  final String title;
}

/// One slot of an [ExpenseDistanceChart]: spend per category and distance, both
/// already in display units.
class ExpenseSlot {
  const ExpenseSlot({required this.costs, required this.distance});

  final Map<ExpenseCategory, double> costs;
  final double distance;

  double get totalCost => costs.values.fold<double>(0, (sum, c) => sum + c);
}

/// Expenses stacked by category over a distance panel, sharing one time axis
/// but not one value axis. Tapping a slot highlights it and shows its
/// breakdown. The distance panel is left out when the range has no distance.
class ExpenseDistanceChart extends StatefulWidget {
  const ExpenseDistanceChart({
    super.key,
    required this.slots,
    required this.data,
    required this.categoryLabels,
    required this.currencySymbol,
    required this.expensesLabel,
    required this.distanceLabel,
    required this.distanceUnit,
    required this.totalLabel,
    required this.emptyLabel,
    this.emphasizeLast = true,
  });

  final List<TimeSlot> slots;
  final List<ExpenseSlot> data;
  final Map<ExpenseCategory, String> categoryLabels;
  final String currencySymbol;
  final String expensesLabel;

  final String distanceLabel;
  final String distanceUnit;
  final String totalLabel;
  final String emptyLabel;

  /// Bolds the last axis label, for a range that ends today.
  final bool emphasizeLast;

  @override
  State<ExpenseDistanceChart> createState() => _ExpenseDistanceChartState();
}

class _ExpenseDistanceChartState extends State<ExpenseDistanceChart> {
  int? _selected;

  @override
  void didUpdateWidget(ExpenseDistanceChart old) {
    super.didUpdateWidget(old);
    if (!_sameAxis(old.slots, widget.slots)) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final data = widget.data;
    final totalCost = data.fold<double>(0, (s, d) => s + d.totalCost);
    final totalDistance = data.fold<double>(0, (s, d) => s + d.distance);
    final hasDistance = totalDistance > 0;
    final present = {
      for (final d in data)
        for (final e in d.costs.entries)
          if (e.value > 0) e.key,
    };
    final hasYear = widget.slots.any((s) => s.year != null);
    final selected = _isFilled(_selected) ? _selected : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: DashSpace.xxl,
          runSpacing: DashSpace.sm,
          children: [
            _Figure(
              label: widget.expensesLabel,
              value: Formatters.currencyRounded(
                totalCost,
                widget.currencySymbol,
              ),
            ),
            if (hasDistance)
              _Figure(
                label: widget.distanceLabel,
                value:
                    '${Formatters.odometer(totalDistance)} ${widget.distanceUnit}',
              ),
          ],
        ),
        const SizedBox(height: DashSpace.lg),
        if (totalCost <= 0 && !hasDistance)
          _NoData(
            label: widget.emptyLabel,
            height: _ExpensePainter.heightFor(
              hasDistance: true,
              hasYear: false,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final painter = _ExpensePainter(
                t: t,
                slots: widget.slots,
                data: data,
                selected: selected,
                hasDistance: hasDistance,
                hasYear: hasYear,
                emphasizeLast: widget.emphasizeLast,
                distanceLabel:
                    '${widget.distanceLabel} (${widget.distanceUnit})',
                textScaler: MediaQuery.textScalerOf(context),
              );
              final width = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Semantics(
                    label: _semanticsLabel(hasDistance),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // On release, so a scroll that starts on the chart
                      // doesn't flash a tooltip.
                      onTapUp: (d) {
                        final i = painter.slotAt(d.localPosition.dx, width);
                        setState(() {
                          _selected = i == selected || !_isFilled(i) ? null : i;
                        });
                      },
                      child: CustomPaint(
                        size: Size(
                          width,
                          _ExpensePainter.heightFor(
                            hasDistance: hasDistance,
                            hasYear: hasYear,
                          ),
                        ),
                        painter: painter,
                      ),
                    ),
                  ),
                  if (selected != null)
                    _tooltipFor(t, selected, painter, width, hasDistance),
                ],
              );
            },
          ),
        const SizedBox(height: DashSpace.md),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 18),
          child: Wrap(
            spacing: DashSpace.lg,
            runSpacing: DashSpace.sm,
            children: [
              for (final c in chartCategoryOrder)
                if (present.contains(c))
                  _LegendItem(
                    color: categoryColor(c, t),
                    label: widget.categoryLabels[c] ?? c.name,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  /// Whether slot [index] exists and has anything to show; a refresh can empty
  /// the slot a selection points at.
  bool _isFilled(int? index) =>
      index != null &&
      index < widget.data.length &&
      (widget.data[index].totalCost > 0 || widget.data[index].distance > 0);

  String _semanticsLabel(bool hasDistance) => [
    for (final (i, slot) in widget.data.indexed)
      if (_isFilled(i))
        '${widget.slots[i].title}: '
            '${Formatters.currencyRounded(slot.totalCost, widget.currencySymbol)}'
            '${hasDistance ? ', ${Formatters.odometer(slot.distance)} ${widget.distanceUnit}' : ''}',
  ].join('\n');

  Widget _tooltipFor(
    DashTokens t,
    int index,
    _ExpensePainter painter,
    double width,
    bool hasDistance,
  ) {
    final slot = widget.data[index];
    final rows = [
      for (final c in chartCategoryOrder)
        if ((slot.costs[c] ?? 0) > 0) c,
    ]..sort((a, b) => slot.costs[b]!.compareTo(slot.costs[a]!));
    // Without the distance panel the plot is too short for a full breakdown;
    // the total still covers the rest.
    if (!hasDistance && rows.length > 3) rows.length = 3;
    final money = widget.currencySymbol;
    // Opposite the tapped slot, so the tooltip never covers what it describes.
    final onRight = painter.slotCenter(index, width) < width / 2;
    return Positioned(
      top: 0,
      right: onRight ? 0 : null,
      left: onRight ? null : painter.gutter(),
      child: _Tooltip(
        title: widget.slots[index].title,
        rows: [
          for (final c in rows)
            _TooltipRow(
              swatch: categoryColor(c, t),
              label: widget.categoryLabels[c] ?? c.name,
              value: Formatters.currencyRounded(slot.costs[c]!, money),
            ),
          if (rows.isNotEmpty) null,
          _TooltipRow(
            label: widget.totalLabel,
            value: Formatters.currencyRounded(slot.totalCost, money),
          ),
          if (hasDistance)
            _TooltipRow(
              label: widget.distanceLabel,
              value:
                  '${Formatters.odometer(slot.distance)} ${widget.distanceUnit}',
            ),
        ],
      ),
    );
  }
}

class _ExpensePainter extends CustomPainter {
  _ExpensePainter({
    required this.t,
    required this.slots,
    required this.data,
    required this.selected,
    required this.hasDistance,
    required this.hasYear,
    required this.emphasizeLast,
    required this.distanceLabel,
    required this.textScaler,
  }) {
    final maxCost = data.fold<double>(0, (m, d) => math.max(m, d.totalCost));
    hasCost = maxCost > 0;
    costStep = niceAxisInterval(maxCost, divisions: 3);
    costMax = _roundUp(maxCost, costStep);
    final maxDistance = data.fold<double>(0, (m, d) => math.max(m, d.distance));
    distanceStep = niceAxisInterval(maxDistance, divisions: 2);
    distanceMax = _roundUp(maxDistance, distanceStep);
  }

  static const double _top = 8;
  static const double _costHeight = 132;
  static const double _panelGap = 34;
  static const double _distanceHeight = 56;

  static double heightFor({required bool hasDistance, required bool hasYear}) =>
      _top +
      _costHeight +
      (hasDistance ? _panelGap + _distanceHeight : 0) +
      _axisBand +
      (hasYear ? _yearBand : 0);

  final DashTokens t;
  final List<TimeSlot> slots;
  final List<ExpenseSlot> data;
  final int? selected;
  final bool hasDistance;
  final bool hasYear;
  final bool emphasizeLast;
  final String distanceLabel;
  final TextScaler textScaler;

  late final bool hasCost;
  late final double costStep;
  late final double costMax;
  late final double distanceStep;
  late final double distanceMax;

  /// Width of the value-label column, from the widest label actually drawn.
  double gutter() => _gutter;

  late final double _gutter = () {
    var widest = 0.0;
    if (hasCost) {
      for (var v = costStep; v <= costMax + 1e-9; v += costStep) {
        widest = math.max(widest, _measure(_compact(v)));
      }
    }
    if (hasDistance) widest = math.max(widest, _measure(_compact(distanceMax)));
    return math.max(22.0, widest + 8);
  }();

  double _measure(String text) {
    final p = _label(text, _axisStyle(t), textScaler);
    final w = p.width;
    p.dispose();
    return w;
  }

  double slotWidth(double width) => (width - gutter()) / slots.length;

  double slotCenter(int i, double width) =>
      gutter() + slotWidth(width) * (i + 0.5);

  int slotAt(double dx, double width) =>
      ((dx - gutter()) / slotWidth(width)).floor().clamp(0, slots.length - 1);

  @override
  void paint(Canvas canvas, Size size) {
    final left = gutter();
    final slot = (size.width - left) / slots.length;
    final barWidth = math.min(16.0, slot * 0.56);
    final costBottom = _top + _costHeight;
    double yCost(double v) => costBottom - v / costMax * _costHeight;

    _grid(canvas, size, left, costStep, costMax, yCost, labels: hasCost);

    for (var i = 0; i < data.length; i++) {
      final x = left + slot * (i + 0.5) - barWidth / 2;
      final dim = selected != null && selected != i;
      var base = 0.0;
      final segments = [
        for (final c in chartCategoryOrder)
          if ((data[i].costs[c] ?? 0) > 0) c,
      ];
      if (segments.isEmpty) continue;
      // A spend too small for the scale still shows, as a sliver in the colour
      // of its biggest category.
      if (costBottom - yCost(data[i].totalCost) < _minBar) {
        final biggest = segments.reduce(
          (a, b) => data[i].costs[a]! >= data[i].costs[b]! ? a : b,
        );
        final color = categoryColor(biggest, t);
        canvas.drawRect(
          Rect.fromLTWH(x, costBottom - _minBar, barWidth, _minBar),
          Paint()..color = dim ? color.withValues(alpha: 0.35) : color,
        );
        continue;
      }
      for (final (si, c) in segments.indexed) {
        final value = data[i].costs[c]!;
        // 2 px of surface between stacked segments, none under the first.
        final bottom = yCost(base) - (si == 0 ? 0 : 2);
        final top = yCost(base + value);
        base += value;
        if (bottom - top < 0.5) continue;
        final isTop = si == segments.length - 1;
        final radius = Radius.circular(math.min(4, bottom - top));
        final color = categoryColor(c, t);
        canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            x,
            top,
            x + barWidth,
            bottom,
            topLeft: isTop ? radius : Radius.zero,
            topRight: isTop ? radius : Radius.zero,
          ),
          Paint()..color = dim ? color.withValues(alpha: 0.35) : color,
        );
      }
    }

    var axisTop = costBottom;
    if (hasDistance) {
      final title = _label(
        distanceLabel,
        TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: t.textSecondary,
        ),
        textScaler,
      );
      title.paint(canvas, Offset(left, costBottom + 12));
      title.dispose();

      final panelTop = costBottom + _panelGap;
      final panelBottom = panelTop + _distanceHeight;
      double yDistance(double v) =>
          panelBottom - v / distanceMax * _distanceHeight;
      _grid(
        canvas,
        size,
        left,
        distanceStep,
        distanceMax,
        yDistance,
        labels: true,
        topOnly: true,
      );

      final distanceColor = t.textSecondary;
      final distanceWidth = math.min(10.0, barWidth * 0.7);
      for (var i = 0; i < data.length; i++) {
        if (data[i].distance <= 0) continue;
        final cx = left + slot * (i + 0.5);
        final top = math.min(
          yDistance(data[i].distance),
          panelBottom - _minBar,
        );
        final alpha = selected == null
            ? 0.45
            : selected == i
            ? 0.9
            : 0.18;
        canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            cx - distanceWidth / 2,
            top,
            cx + distanceWidth / 2,
            panelBottom,
            topLeft: Radius.circular(math.min(3, panelBottom - top)),
            topRight: Radius.circular(math.min(3, panelBottom - top)),
          ),
          Paint()..color = distanceColor.withValues(alpha: alpha),
        );
      }
      axisTop = panelBottom;
    }

    _timeAxis(canvas, left, slot, axisTop + 6);
  }

  void _grid(
    Canvas canvas,
    Size size,
    double left,
    double step,
    double max,
    double Function(double) y, {
    required bool labels,
    bool topOnly = false,
  }) {
    final line = Paint()
      ..color = t.hairline
      ..strokeWidth = 1;
    for (var v = 0.0; v <= max + 1e-9; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), line);
      if (v <= 0 || !labels || (topOnly && v < max - 1e-9)) continue;
      final label = _label(_compact(v), _axisStyle(t), textScaler);
      label.paint(canvas, Offset(0, y(v) - label.height / 2));
      label.dispose();
    }
  }

  void _timeAxis(Canvas canvas, double left, double slot, double top) {
    _paintTimeAxis(
      canvas: canvas,
      t: t,
      slots: slots,
      left: left,
      slot: slot,
      top: top,
      emphasizeLast: emphasizeLast,
      textScaler: textScaler,
    );
  }

  @override
  bool shouldRepaint(_ExpensePainter old) =>
      old.data != data ||
      old.slots != slots ||
      old.selected != selected ||
      old.t != t ||
      old.textScaler != textScaler;
}

/// One slot's average economy, in display units, or null without a fill-up.
///
/// A line with dots rather than bars: the axis is cropped to the data so small
/// changes stay visible, and only a line reads honestly off a cropped scale.
class EconomyChart extends StatefulWidget {
  const EconomyChart({
    super.key,
    required this.slots,
    required this.values,
    required this.average,
    required this.unitLabel,
    required this.averageLabel,
    required this.emptyLabel,
    this.emphasizeLast = true,
  });

  final List<TimeSlot> slots;
  final List<double?> values;

  /// The range's average, drawn as a reference line; null hides it.
  final double? average;
  final String unitLabel;

  /// Label for the average line, given the formatted value.
  final String Function(String value) averageLabel;
  final String emptyLabel;
  final bool emphasizeLast;

  @override
  State<EconomyChart> createState() => _EconomyChartState();
}

class _EconomyChartState extends State<EconomyChart> {
  int? _selected;

  @override
  void didUpdateWidget(EconomyChart old) {
    super.didUpdateWidget(old);
    if (!_sameAxis(old.slots, widget.slots)) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final hasYear = widget.slots.any((s) => s.year != null);
    if (widget.values.every((v) => v == null)) {
      return _NoData(
        label: widget.emptyLabel,
        height:
            _EconomyPainter.heightFor(hasYear: false) + _keyGap + _keyHeight,
      );
    }
    final selected = _selected;
    final hasSelection =
        selected != null &&
        selected < widget.values.length &&
        widget.values[selected] != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final painter = _EconomyPainter(
          t: t,
          slots: widget.slots,
          values: widget.values,
          average: widget.average,
          selected: hasSelection ? selected : null,
          hasYear: hasYear,
          emphasizeLast: widget.emphasizeLast,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final chart = Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              label: [
                for (final (i, v) in widget.values.indexed)
                  if (v != null)
                    '${widget.slots[i].title}: '
                        '${Formatters.number(v, decimals: 1)} ${widget.unitLabel}',
              ].join('\n'),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final i = painter.slotAt(d.localPosition.dx, width);
                  setState(() {
                    _selected = i == selected || widget.values[i] == null
                        ? null
                        : i;
                  });
                },
                child: CustomPaint(
                  size: Size(
                    width,
                    _EconomyPainter.heightFor(hasYear: hasYear),
                  ),
                  painter: painter,
                ),
              ),
            ),
            if (hasSelection)
              Positioned(
                top: 0,
                right: painter.slotCenter(selected, width) < width / 2
                    ? 0
                    : null,
                left: painter.slotCenter(selected, width) < width / 2
                    ? null
                    : painter.gutter(),
                child: _Tooltip(
                  title: widget.slots[selected].title,
                  rows: [
                    _TooltipRow(
                      label: widget.unitLabel,
                      value: Formatters.number(
                        widget.values[selected]!,
                        decimals: 1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            chart,
            const SizedBox(height: _keyGap),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _keyHeight),
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.average == null
                    ? null
                    : _LegendItem(
                        color: t.textSecondary,
                        line: true,
                        label: widget.averageLabel(
                          Formatters.number(widget.average!, decimals: 1),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EconomyPainter extends CustomPainter {
  _EconomyPainter({
    required this.t,
    required this.slots,
    required this.values,
    required this.average,
    required this.selected,
    required this.hasYear,
    required this.emphasizeLast,
    required this.textScaler,
  }) {
    final present = values.whereType<double>();
    final minV = present.reduce(math.min);
    final maxV = present.reduce(math.max);
    final span = maxV - minV;
    final pad = span == 0 ? math.max(maxV * 0.1, 0.5) : span * 0.25;
    step = niceAxisInterval(span + 2 * pad, divisions: 3);
    low = math.max(0, ((minV - pad) / step).floorToDouble() * step);
    high = ((maxV + pad) / step).ceilToDouble() * step;
  }

  static const double _top = 8;
  static const double _plotHeight = 132;

  static double heightFor({required bool hasYear}) =>
      _top + _plotHeight + _axisBand + (hasYear ? _yearBand : 0);

  final DashTokens t;
  final List<TimeSlot> slots;
  final List<double?> values;
  final double? average;
  final int? selected;
  final bool hasYear;
  final bool emphasizeLast;
  final TextScaler textScaler;

  late final double step;
  late final double low;
  late final double high;

  int get _decimals => step < 1 ? 1 : 0;

  double gutter() => _gutter;

  late final double _gutter = () {
    var widest = 0.0;
    for (var v = low + step; v <= high + 1e-9; v += step) {
      final p = _label(
        Formatters.number(v, decimals: _decimals),
        _axisStyle(t),
        textScaler,
      );
      widest = math.max(widest, p.width);
      p.dispose();
    }
    return math.max(22.0, widest + 8);
  }();

  double slotCenter(int i, double width) =>
      gutter() + (width - gutter()) / slots.length * (i + 0.5);

  int slotAt(double dx, double width) =>
      ((dx - gutter()) / ((width - gutter()) / slots.length)).floor().clamp(
        0,
        slots.length - 1,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final left = gutter();
    final slot = (size.width - left) / slots.length;
    final bottom = _top + _plotHeight;
    double y(double v) => bottom - (v - low) / (high - low) * _plotHeight;

    final grid = Paint()
      ..color = t.hairline
      ..strokeWidth = 1;
    for (var v = low; v <= high + 1e-9; v += step) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), grid);
      if (v <= low) continue;
      final label = _label(
        Formatters.number(v, decimals: _decimals),
        _axisStyle(t),
        textScaler,
      );
      label.paint(canvas, Offset(0, y(v) - label.height / 2));
      label.dispose();
    }

    final lineColor = economyLineColor(t);
    Offset? point(int i) => values[i] == null
        ? null
        : Offset(left + slot * (i + 0.5), y(values[i]!));

    if (average != null) {
      final ay = y(average!);
      canvas.drawLine(
        Offset(left, ay),
        Offset(size.width, ay),
        Paint()
          ..color = t.textSecondary
          ..strokeWidth = 1,
      );
    }

    // Joined across slots without a fill-up: refuelling every few weeks leaves
    // most week slots empty, and a line broken at each would be only dots.
    final line = Path();
    var penDown = false;
    for (var i = 0; i < values.length; i++) {
      final p = point(i);
      if (p == null) continue;
      penDown ? line.lineTo(p.dx, p.dy) : line.moveTo(p.dx, p.dy);
      penDown = true;
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (selected != null) {
      final cx = left + slot * (selected! + 0.5);
      canvas.drawLine(
        Offset(cx, _top),
        Offset(cx, bottom),
        Paint()
          ..color = t.textTertiary
          ..strokeWidth = 1,
      );
    }
    for (var i = 0; i < values.length; i++) {
      final p = point(i);
      if (p != null) {
        _dot(canvas, p, i == selected ? 5 : 4, lineColor, t.overlaySurface);
      }
    }

    if (selected == null) {
      final last = values.lastIndexWhere((v) => v != null);
      final p = point(last)!;
      final label = _label(
        Formatters.number(values[last]!, decimals: 1),
        TextStyle(
          fontFamily: DashTokens.fontMono,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
        textScaler,
      );
      final dx = (p.dx - label.width / 2).clamp(left, size.width - label.width);
      label.paint(canvas, Offset(dx, p.dy - 10 - label.height));
      label.dispose();
    }

    _paintTimeAxis(
      canvas: canvas,
      t: t,
      slots: slots,
      left: left,
      slot: slot,
      top: bottom + 6,
      emphasizeLast: emphasizeLast,
      textScaler: textScaler,
    );
  }

  @override
  bool shouldRepaint(_EconomyPainter old) =>
      old.values != values ||
      old.slots != slots ||
      old.selected != selected ||
      old.average != average ||
      old.t != t ||
      old.textScaler != textScaler;
}

/// Whether two axes name the same slots, so a selection still points at the
/// slot it was made on.
bool _sameAxis(List<TimeSlot> a, List<TimeSlot> b) =>
    a.length == b.length && (a.isEmpty || a.first.title == b.first.title);

const double _axisBand = 22;
const double _minBar = 2;
const double _keyGap = 8;
const double _keyHeight = 18;
const double _yearBand = 13;

/// Time labels under the slots, thinned to every n-th counted back from the
/// last so the most recent slot is always named, with the year under the first
/// visible label of each one.
void _paintTimeAxis({
  required Canvas canvas,
  required DashTokens t,
  required List<TimeSlot> slots,
  required double left,
  required double slot,
  required double top,
  required bool emphasizeLast,
  required TextScaler textScaler,
}) {
  final style = _axisStyle(t);
  final painters = [
    for (final s in slots) _label(s.axisLabel, style, textScaler),
  ];
  final widest = painters.fold<double>(0, (m, p) => math.max(m, p.width));
  final every = math.max(1, ((widest + 6) / slot).ceil());
  final lastIndex = slots.length - 1;
  int? lastYear;

  for (var i = 0; i < slots.length; i++) {
    final cx = left + slot * (i + 0.5);
    if ((lastIndex - i) % every != 0) continue;
    {
      var label = painters[i];
      if (i == lastIndex && emphasizeLast) {
        label = _label(
          slots[i].axisLabel,
          style.copyWith(fontWeight: FontWeight.w700, color: t.textPrimary),
          textScaler,
        );
        painters[i].dispose();
        painters[i] = label;
      }
      label.paint(canvas, Offset(cx - label.width / 2, top));
    }
    final year = slots[i].year;
    if (year != null && year != lastYear) {
      final label = _label('$year', style.copyWith(fontSize: 9), textScaler);
      label.paint(canvas, Offset(cx - label.width / 2, top + 13));
      label.dispose();
      lastYear = year;
    }
  }
  for (final p in painters) {
    p.dispose();
  }
}

TextPainter _label(String text, TextStyle style, TextScaler scaler) =>
    TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();

/// A marker with a ring of [ring] colour, so it stays legible over a line.
void _dot(Canvas canvas, Offset at, double radius, Color fill, Color ring) {
  canvas.drawCircle(at, radius + 2, Paint()..color = ring);
  canvas.drawCircle(at, radius, Paint()..color = fill);
}

/// A 100% bar of [segments] with 2 px gaps; an all-zero bar is a bare track.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.height, required this.segments});

  final double height;
  final List<({Color color, double value})> segments;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _SegmentPainter(
        segments: segments,
        track: DashTokens.of(context).gaugeTrack,
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  const _SegmentPainter({required this.segments, required this.track});

  final List<({Color color, double value})> segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final shown = segments.where((s) => s.value > 0).toList();
    if (shown.isEmpty) {
      canvas.drawRRect(shape, Paint()..color = track);
      return;
    }
    canvas.clipRRect(shape);
    const gap = 2.0;
    final total = shown.fold<double>(0, (sum, s) => sum + s.value);
    final room = size.width - gap * (shown.length - 1);
    var x = 0.0;
    for (final s in shown) {
      final w = room * s.value / total;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = s.color,
      );
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.segments != segments || old.track != track;
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: t.textTertiary,
          ),
        ),
        const SizedBox(height: DashSpace.xs),
        Text(
          value,
          style: TextStyle(
            fontFamily: DashTokens.fontMono,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// One line of a [_Tooltip]; a null in its row list draws a divider.
class _TooltipRow {
  const _TooltipRow({required this.label, required this.value, this.swatch});

  final String label;
  final String value;
  final Color? swatch;
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.title, required this.rows});

  final String title;
  final List<_TooltipRow?> rows;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return IgnorePointer(
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
        padding: const EdgeInsets.fromLTRB(
          DashSpace.md,
          DashSpace.md,
          DashSpace.md,
          DashSpace.md,
        ),
        decoration: BoxDecoration(
          color: t.overlaySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.overlayBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
            for (final row in rows)
              if (row == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: DashSpace.xs),
                  child: Divider(height: 1, thickness: 1, color: t.hairline),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: DashSpace.xs),
                  child: Row(
                    children: [
                      if (row.swatch != null) ...[
                        _Swatch(color: row.swatch!, size: 8, radius: 2),
                        const SizedBox(width: DashSpace.sm),
                      ],
                      Expanded(
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontFamily: DashTokens.fontUi,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: row.swatch == null
                                ? t.textTertiary
                                : t.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: DashSpace.md),
                      Text(
                        row.value,
                        style: TextStyle(
                          fontFamily: DashTokens.fontMono,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder standing in for a chart with nothing to plot, at the chart's
/// height so the card doesn't jump when data arrives.
class _NoData extends StatelessWidget {
  const _NoData({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.subCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.subCardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: DashTokens.fontUi,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: t.textTertiary,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.line = false,
  });

  final Color color;
  final String label;

  /// A short stroke instead of a square, for a reference line.
  final bool line;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line
            ? Container(width: 14, height: 1.5, color: color)
            : _Swatch(color: color, size: 9, radius: 2),
        const SizedBox(width: DashSpace.sm),
        Text(
          label,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.size,
    required this.radius,
    this.hollow = false,
  });

  final Color color;
  final double size;
  final double radius;

  /// An outline in the muted ink, for a series with nothing to show.
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hollow ? null : color,
        borderRadius: BorderRadius.circular(radius),
        border: hollow
            ? Border.all(color: DashTokens.of(context).textTertiary, width: 1.5)
            : null,
      ),
    );
  }
}

/// A "nice" grid step (1, 2, or 5 × a power of ten) giving roughly [divisions]
/// lines up to [maxY], so axis labels land on round numbers across any unit.
double niceAxisInterval(double maxY, {int divisions = 4}) {
  if (maxY <= 0) return 1;
  final rough = maxY / divisions;
  final magnitude = math
      .pow(10, (math.log(rough) / math.ln10).floor())
      .toDouble();
  final normalized = rough / magnitude;
  final step = normalized < 1.5
      ? 1
      : normalized < 3
      ? 2
      : normalized < 7
      ? 5
      : 10;
  return step * magnitude;
}

TextStyle _axisStyle(DashTokens t) => TextStyle(
  fontFamily: DashTokens.fontMono,
  fontSize: 10,
  fontWeight: FontWeight.w600,
  color: t.textTertiary,
);

/// Compact axis number: `1.2k` / `15k` for thousands, rounded otherwise.
String _compact(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '${Formatters.number(k, decimals: k >= 10 || k == k.roundToDouble() ? 0 : 1)}k';
  }
  return Formatters.number(v, decimals: v < 1 && v > 0 ? 1 : 0);
}

/// [value] rounded up to a whole multiple of [interval]; one step when there
/// is nothing to fit.
double _roundUp(double value, double interval) =>
    value <= 0 ? interval : (value / interval).ceilToDouble() * interval;
