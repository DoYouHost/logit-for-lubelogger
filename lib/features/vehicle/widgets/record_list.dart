import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'record_filter.dart';

/// One icon + value pair in a [RecordCard]'s meta row (design: odometer,
/// distance-since-last, economy, price/volume — JetBrains Mono, tertiary).
class RecordMetaItem {
  const RecordMetaItem(this.icon, this.value, {this.tooltip});

  /// An item that is only its icon — a flag ("this record has a note"), where
  /// the icon is the whole message and a value beside it would just repeat it.
  /// [tooltip] is what says so out loud, for a long press and for a screen
  /// reader.
  const RecordMetaItem.flag(this.icon, {required String this.tooltip})
    : value = '';

  final IconData icon;
  final String value;

  /// Long-press text, and the item's semantics label.
  final String? tooltip;
}

/// One record entry, styled as a card (design handoff: subcard fill + hairline
/// border, 14px radius, 8px stacking gap). Top row is the date (left) and a
/// right-aligned headline value — the cost for money-bearing records, or the
/// primary reading when there's no cost (e.g. an odometer entry); an optional
/// description sits below it; an optional meta row of small icon+value stats
/// (JetBrains Mono, tertiary) sits at the bottom.
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.date,
    required this.headline,
    this.headlineColor,
    this.description,
    this.meta = const [],
    this.tags = const [],
    this.activeTags = const {},
    this.onTagTap,
    this.onTap,
  });

  final String date;
  final String headline;
  final Color? headlineColor;
  final String? description;
  final List<RecordMetaItem> meta;

  /// The record's tags, shown as chips below the meta row. Stored and editable
  /// since the first release, and until now printed nowhere.
  final List<String> tags;

  /// Which of [tags] are currently filtering the list, so a card can show that
  /// one of its own tags is what the list is narrowed to.
  final Set<String> activeTags;
  final void Function(String tag)? onTagTap;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.subCard,
          borderRadius: radius,
          border: Border.all(color: t.subCardBorder),
        ),
        // Named here rather than by each tab: a row is a row in every tab, and
        // the enclosing tab surface already says which list it belongs to.
        child: logTag(
          'record.card',
          InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DashSpace.md,
                    vertical: DashSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: DashTokens.fontUi,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: DashSpace.sm),
                          Text(
                            headline,
                            style: TextStyle(
                              fontFamily: DashTokens.fontMono,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: headlineColor ?? t.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (description != null) ...[
                        const SizedBox(height: DashSpace.xs),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: DashTokens.fontUi,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: DashSpace.sm),
                        Wrap(
                          spacing: DashSpace.lg,
                          runSpacing: DashSpace.xs,
                          children: [for (final m in meta) _MetaItem(item: m)],
                        ),
                      ],
                      if (tags.isNotEmpty && onTagTap != null) ...[
                        const SizedBox(height: DashSpace.sm),
                        Wrap(
                          spacing: DashSpace.sm,
                          runSpacing: DashSpace.xs,
                          children: [
                            for (final tag in tags)
                              RecordTagChip(
                                tag: tag,
                                selected: activeTags.contains(tag),
                                onTap: () => onTagTap!(tag),
                              ).tagged('records.tag'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One entry of a card's meta row. A [RecordMetaItem.flag] renders as the bare
/// icon; anything else keeps its mono value beside it.
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.item});

  final RecordMetaItem item;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 14, color: t.textTertiary),
        if (item.value.isNotEmpty) ...[
          const SizedBox(width: DashSpace.xs),
          Text(
            item.value,
            style: TextStyle(
              fontFamily: DashTokens.fontMono,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: t.textTertiary,
            ),
          ),
        ],
      ],
    );
    final tooltip = item.tooltip;
    return tooltip == null ? row : Tooltip(message: tooltip, child: row);
  }
}

/// What a record tab shows once its records have loaded: the cards, built one at
/// a time by index, plus an optional header above them (the fuel tab's summary
/// pills).
///
/// Cards are handed over as a builder rather than a list so the tab body can
/// keep them lazy — see [SliverResponsiveCards].
class RecordsContent {
  const RecordsContent({required this.count, required this.card, this.header});

  final int count;
  final IndexedWidgetBuilder card;
  final Widget? header;
}

/// Shared record-tab body: pull-to-refresh + loading / error / empty / content
/// switching over an [AsyncValue] list. [onRefresh] both invalidates and awaits
/// the provider so the spinner reflects the real reload.
///
/// With [facets] it also carries the search field, the sort menu and the tag
/// filter, and hands the tab a [RecordListControls] to apply them. The state is
/// this widget's own, so leaving the tab clears it — a filter nobody can see
/// from another screen must not still be hiding records when you come back.
class RecordsTabBody<T> extends StatefulWidget {
  const RecordsTabBody({
    super.key,
    required this.async,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.builder,
    this.facets,
  });

  final AsyncValue<List<T>> async;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyLabel;
  final RecordsContent Function(List<T> records, RecordListControls<T> filter)
  builder;
  final RecordFacets<T>? facets;

  @override
  State<RecordsTabBody<T>> createState() => _RecordsTabBodyState<T>();
}

class _RecordsTabBodyState<T> extends State<RecordsTabBody<T>> {
  final _query = TextEditingController();
  final _tags = <String>{};
  int _sortIndex = 0;
  bool _descending = true;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _descending = widget.facets?.sorts.first.descendingByDefault ?? true;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) => setState(() {
    if (!_tags.remove(tag)) _tags.add(tag);
  });

  void _clearFilters() => setState(() {
    _tags.clear();
    _query.clear();
  });

  RecordListControls<T> _controls(RecordFacets<T> facets) {
    final needles = _query.text.trim().toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((n) => n.isEmpty);
    final sort = facets.sorts[_sortIndex.clamp(0, facets.sorts.length - 1)];
    return RecordListControls<T>(
      activeTags: _tags,
      onTagTap: _toggleTag,
      filtering: needles.isNotEmpty || _tags.isNotEmpty,
      compare: _descending ? (a, b) => sort.compare(b, a) : sort.compare,
      matches: (record) {
        final recordTags = splitTags(facets.tagsOf(record));
        // Every selected tag must be on the record: the chips accumulate, so
        // each one is expected to narrow rather than widen. (LubeLogger's own
        // `?tags=` query does the opposite, but that one is typed, not tapped.)
        if (!_tags.every(recordTags.contains)) return false;
        if (needles.isEmpty) return true;
        final haystack = [
          ...facets.searchIn(record),
          ...recordTags,
        ].join(' ').toLowerCase();
        // All words must appear, in any order or field — typing two words to
        // narrow is the reflex, and requiring them adjacent breaks it.
        return needles.every(haystack.contains);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: widget.async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AsyncErrorView(
          // Its own scroll view, so the enclosing RefreshIndicator still
          // has something to pull.
          scrollable: true,
          message: l10n.dashLoadError,
          onRetry: widget.onRefresh,
          retryLabel: l10n.retry,
        ),
        data: _data,
      ),
    );
  }

  Widget _data(List<T> records) {
    final l10n = AppLocalizations.of(context);
    final facets = widget.facets;
    // Nothing recorded at all: the bar would offer to search an empty list.
    if (records.isEmpty || facets == null) {
      return records.isEmpty
          ? EmptyStateView(message: widget.emptyLabel, icon: widget.emptyIcon)
          : _content(
              widget.builder(
                records,
                RecordListControls<T>(
                  matches: (_) => true,
                  compare: (_, _) => 0,
                  activeTags: const {},
                  onTagTap: (_) {},
                  filtering: false,
                ),
              ),
              null,
            );
    }

    final controls = _controls(facets);
    final content = widget.builder(records, controls);
    final bar = RecordFilterBar(
      controller: _query,
      sortLabels: [for (final s in facets.sorts) s.label],
      sortIndex: _sortIndex,
      descending: _descending,
      onSortSelected: (i) => setState(() {
        _sortIndex = i;
        _descending = facets.sorts[i].descendingByDefault;
      }),
      onDirectionToggled: () => setState(() => _descending = !_descending),
      activeTags: _tags,
      onTagTap: _toggleTag,
    );
    if (content.count == 0) {
      return _content(
        RecordsContent(
          count: 0,
          card: (_, _) => const SizedBox.shrink(),
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bar,
              const SizedBox(height: DashSpace.xl),
              EmptyStateView(
                message: controls.filtering
                    ? l10n.recordsNoMatches
                    : widget.emptyLabel,
                icon: widget.emptyIcon,
                scrollable: false,
              ),
              if (controls.filtering)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(l10n.recordsClearFilters),
                ).tagged('records.clearFilters'),
            ],
          ),
        ),
        null,
      );
    }
    return _content(content, bar);
  }

  Widget _content(RecordsContent content, Widget? bar) {
    final header = content.header;
    final top = bar == null
        ? header
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [bar, ?header],
          );
    return CustomScrollView(
      slivers: [
        if (top != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              DashSpace.lg,
              DashSpace.sm,
              DashSpace.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(child: top),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            top == null ? 8 : 0,
            16,
            fabScrollClearance(context),
          ),
          sliver: SliverResponsiveCards(
            itemCount: content.count,
            itemBuilder: content.card,
          ),
        ),
      ],
    );
  }
}

/// A group of summary pills above a record list (fuel tab). Uses [DashPill].
class SummaryPillRow extends StatelessWidget {
  const SummaryPillRow({super.key, required this.pills});

  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DashSpace.md),
      child: Wrap(
        spacing: DashSpace.sm,
        runSpacing: DashSpace.sm,
        children: pills,
      ),
    );
  }
}
