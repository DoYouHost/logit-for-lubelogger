import 'package:material_ui/material_ui.dart'
    show FloatingActionButton, kFloatingActionButtonMargin;
import 'package:flutter/widgets.dart';

/// Layout helpers for adapting the (single-column, portrait-first) design to
/// wider viewports — phone landscape and tablets — so horizontal space is used
/// instead of stretching one column edge-to-edge.

/// Max width for a centered full-screen content column (e.g. Settings), so its
/// rows stay readable in landscape instead of running the whole width.
const double kContentMaxWidth = 760;

/// Bottom padding for a scroll view under a floating action button, so its last
/// card can scroll fully above the button instead of ending behind it.
double fabScrollClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom +
    _fabSize +
    kFloatingActionButtonMargin +
    16;

/// A regular [FloatingActionButton]'s diameter; Material exports no constant.
const double _fabSize = 56;

/// First width at which a second column of cards fits.
const double _wideBreakpoint = 600;

/// Width at which a third column fits (large tablets / desktop).
const double _extraWideBreakpoint = 1100;

/// Column count for a card grid at [width].
int responsiveColumns(double width) => width >= _extraWideBreakpoint
    ? 3
    : width >= _wideBreakpoint
    ? 2
    : 1;

extension ResponsiveContext on BuildContext {
  /// True once there's room for a multi-column layout (phone landscape and up).
  bool get isWideLayout => MediaQuery.sizeOf(this).width >= _wideBreakpoint;
}

/// Lays cards out in a responsive number of equal-width columns based on the
/// available width: one column when narrow (portrait phones), two or three side
/// by side when there's room. Cells hug their content height, so cards of
/// differing heights sit top-aligned within a row.
///
/// A sliver rather than a box, because the cells are built on demand: the whole
/// grid used to be one box inside the scroll view, which the viewport can
/// neither skip nor cull, so a few hundred records were laid out and painted on
/// every frame they scrolled past.
class SliverResponsiveCards extends StatelessWidget {
  const SliverResponsiveCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.runSpacing = 0,
    this.maxColumns,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Horizontal gap between columns.
  final double spacing;

  /// Vertical gap between rows. Leave at 0 for children that already carry
  /// their own bottom margin (e.g. record cards).
  final double runSpacing;

  /// Caps the computed column count.
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    // The column count comes from the screen and not from a SliverLayoutBuilder.
    // Sliver constraints carry the scroll offset, so a layout callback here runs
    // on every frame of a scroll, and each run hands the list a fresh delegate —
    // whose shouldRebuild is unconditionally true, so every card on screen is
    // rebuilt every frame. That cost lands on the UI thread and is felt as
    // stutter. Cell widths still come from the real constraints, via Expanded;
    // only the count is decided here.
    var columns = responsiveColumns(MediaQuery.sizeOf(context).width);
    final cap = maxColumns;
    if (cap != null && columns > cap) columns = cap;
    final rows = (itemCount + columns - 1) ~/ columns;
    return SliverList.builder(
      itemCount: rows,
      itemBuilder: (context, row) => Padding(
        // Like the wrap's runSpacing: between rows only, never trailing.
        padding: row == rows - 1
            ? EdgeInsets.zero
            : EdgeInsets.only(bottom: runSpacing),
        child: columns == 1
            ? itemBuilder(context, row)
            : _row(context, row, columns),
      ),
    );
  }

  /// One row of [columns] equal-width cells, top-aligned so cards of differing
  /// heights sit flush at the top. The tail of the last row is filled with empty
  /// cells so the ones before it keep their width.
  Widget _row(BuildContext context, int row, int columns) {
    final first = row * columns;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < columns; column++) ...[
          if (column > 0) SizedBox(width: spacing),
          Expanded(
            child: first + column < itemCount
                ? itemBuilder(context, first + column)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
