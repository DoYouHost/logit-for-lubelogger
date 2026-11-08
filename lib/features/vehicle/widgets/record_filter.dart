import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';

/// LubeLogger stores a record's tags as one space-separated string and splits
/// them on whitespace server-side (`MethodParameter.Tags`); this matches that.
List<String> splitTags(String raw) =>
    raw.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

/// One way to order a record list, as offered in the sort menu.
class RecordSort<T> {
  const RecordSort({
    required this.label,
    required this.compare,
    this.descendingByDefault = true,
  });

  final String label;

  /// Ascending in the key: oldest date, smallest cost, A before Z. The bar
  /// flips it, so the arrow in the UI means what it says regardless of which
  /// direction a given key is normally read in.
  final Comparator<T> compare;

  /// Which way this key is worth reading first — newest, dearest and most
  /// urgent descending; names and progress ascending. Picking a sort resets the
  /// direction to this, so a switch never lands on the useless end of the list.
  final bool descendingByDefault;
}

/// What a record type exposes to searching, tag filtering and sorting. Each tab
/// declares its own, because a note is searched by its body and a supply record
/// by its part number.
class RecordFacets<T> {
  const RecordFacets({
    required this.searchIn,
    required this.tagsOf,
    required this.sorts,
  });

  /// Fields the query is matched against, per record.
  final List<String> Function(T record) searchIn;

  /// The record's raw tag string (space-separated, as stored).
  final String Function(T record) tagsOf;

  /// Offered orders, first one the default — normally the order the tab used
  /// before it could be sorted at all.
  final List<RecordSort<T>> sorts;
}

/// The live filter, handed to a tab's card builder.
///
/// Tabs call [apply] on their records. The fuel tab is the exception: its
/// per-record economy accumulates across the whole chronological sequence, so
/// it builds its rows from every record first, then drops the ones that don't
/// [matches] and orders what is left with [sortStably].
class RecordListControls<T> {
  const RecordListControls({
    required this.matches,
    required this.compare,
    required this.activeTags,
    required this.onTagTap,
    required this.filtering,
  });

  final bool Function(T record) matches;
  final Comparator<T> compare;

  /// Tags currently narrowing the list. A card paints its own tags as selected
  /// when they are in here.
  final Set<String> activeTags;

  /// Adds or removes a tag from the filter — what a tag chip on a card does.
  final void Function(String tag) onTagTap;

  /// Whether a query or a tag is currently hiding anything, which is what makes
  /// an empty list mean "nothing matched" instead of "nothing recorded".
  final bool filtering;

  /// Filtered and sorted — what a tab normally calls.
  List<T> apply(List<T> records) => sortStably([
    for (final r in records)
      if (matches(r)) r,
  ], (r) => r);

  /// The active sort, preserving the incoming order between entries it
  /// considers equal (`List.sort` alone is not stable, and the note tab's
  /// "pinned first, otherwise as the server sent them" depends on it).
  ///
  /// Takes the record out of [item] rather than sorting records directly, so a
  /// tab that had to build and filter its own list first still gets the same
  /// ordering — the fuel tab sorts rows whose economy was computed over the
  /// full sequence, not the records themselves.
  List<R> sortStably<R>(List<R> items, T Function(R item) recordOf) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final byKey = compare(recordOf(a.$2), recordOf(b.$2));
      return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}

/// Search field + sort menu + the tags currently filtering, above a record list.
///
/// Scrolls away with the list rather than pinning: a header that stays put has
/// to be re-laid-out on every scroll frame, which is what the sliver work in
/// this app has repeatedly had to undo.
class RecordFilterBar extends StatelessWidget {
  const RecordFilterBar({
    super.key,
    required this.controller,
    required this.sortLabels,
    required this.sortIndex,
    required this.descending,
    required this.onSortSelected,
    required this.onDirectionToggled,
    required this.activeTags,
    required this.onTagTap,
  });

  final TextEditingController controller;
  final List<String> sortLabels;
  final int sortIndex;
  final bool descending;
  final ValueChanged<int> onSortSelected;
  final VoidCallback onDirectionToggled;
  final Set<String> activeTags;
  final void Function(String tag) onTagTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 13.5,
                    color: t.textPrimary,
                  ),
                  decoration: dashFieldDecoration(
                    t,
                    hintText: l10n.recordsSearchHint,
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: t.textTertiary,
                    ),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: controller.clear,
                            tooltip: l10n.recordsSearchClear,
                          ).tagged('records.search.clear'),
                  ),
                ).tagged('records.search'),
              ),
              const SizedBox(width: DashSpace.sm),
              PopupMenuButton<int>(
                tooltip: l10n.recordsSortBy,
                icon: Icon(Icons.sort, color: t.textSecondary),
                onSelected: onSortSelected,
                itemBuilder: (_) => [
                  for (var i = 0; i < sortLabels.length; i++)
                    CheckedPopupMenuItem<int>(
                      value: i,
                      checked: i == sortIndex,
                      child: logTag('records.sort.option', Text(sortLabels[i])),
                    ),
                ],
              ).tagged('records.sort'),
              IconButton(
                icon: Icon(
                  descending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                  color: t.textSecondary,
                ),
                tooltip: descending
                    ? l10n.recordsSortDescending
                    : l10n.recordsSortAscending,
                onPressed: onDirectionToggled,
              ).tagged('records.sort.direction'),
            ],
          ),
          if (activeTags.isNotEmpty) ...[
            const SizedBox(height: DashSpace.sm),
            Wrap(
              spacing: DashSpace.sm,
              runSpacing: DashSpace.sm,
              children: [
                for (final tag in activeTags)
                  RecordTagChip(
                    tag: tag,
                    selected: true,
                    onTap: () => onTagTap(tag),
                  ).tagged('records.tag'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A record's tag, on a card or in the filter bar. Tapping one narrows the list
/// to it; tapping it again lets it go — the tags were stored and editable all
/// along, just never shown anywhere.
class RecordTagChip extends StatelessWidget {
  const RecordTagChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final String tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final accent = t.accentBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DashSpace.sm,
          vertical: DashSpace.xs,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: selected ? 0.22 : 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: selected ? 0.6 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: DashSpace.xs),
              Icon(Icons.close, size: 12, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}
