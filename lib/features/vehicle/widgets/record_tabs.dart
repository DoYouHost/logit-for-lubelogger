import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/format/gas_stats.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/equipment_record.dart';
import '../../../core/models/gas_record.dart';
import '../../../core/models/note_record.dart';
import '../../../core/models/odometer_record.dart';
import '../../../core/models/plan_record.dart';
import '../../../core/models/reminder_record.dart';
import '../../../core/models/supply_record.dart';
import '../../../core/models/vehicle_record.dart';
import '../../../core/format/vehicle_units.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../forms/add_equipment_form.dart';
import '../forms/add_fuel_form.dart';
import '../forms/add_generic_record_form.dart';
import '../forms/add_note_form.dart';
import '../forms/add_odometer_form.dart';
import '../forms/add_plan_form.dart';
import '../forms/add_reminder_form.dart';
import '../forms/add_supply_form.dart';
import 'record_filter.dart';
import 'record_list.dart';

const _placeholder = '—';

/// Short date in the user's chosen order + separator, or a dash when missing.
String _date(DateTime? d, VehicleUnits units) =>
    d == null ? _placeholder : units.formatDate(d);

/// Odometer / distance reading in the display unit, bare (no unit suffix).
String _odo(double? raw, VehicleUnits units) => (raw == null || raw <= 0)
    ? _placeholder
    : Formatters.odometer(units.toDisplayDistance(raw));

/// [_odo] with its unit label appended, or just the bare placeholder when
/// there's no reading — a record card shows "—" alone, never "— km".
String _odoUnit(double? raw, VehicleUnits units) {
  final v = _odo(raw, units);
  return v == _placeholder ? v : '$v ${units.distanceLabel}';
}

/// The two things a card used to hide: its attachments and its note. Both are
/// stored, editable and previously invisible — the only way to learn a record
/// had three photos on it was to open the edit form.
///
/// Tail of every card's meta row, so the row still reads left-to-right as the
/// record's own numbers first. Pass only what the card doesn't already show:
/// the note tab and the equipment tab print their notes as the description, so
/// they send [files] alone.
List<RecordMetaItem> _extras(
  AppLocalizations l10n, {
  List<Attachment> files = const [],
  String notes = '',
}) => [
  if (files.isNotEmpty)
    RecordMetaItem(
      Icons.attach_file,
      '${files.length}',
      tooltip: l10n.cardAttachments(files.length),
    ),
  if (notes.trim().isNotEmpty)
    RecordMetaItem.flag(Icons.notes, tooltip: l10n.cardHasNote),
];

/// Odometer readings as a card list: each card headlines the reading, with the
/// gain since the previous reading (Δ) in the meta row.
class OdometerTab extends ConsumerWidget {
  const OdometerTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final async = ref.watch(odometerRecordsProvider(vehicleId));

    return RecordsTabBody<OdometerRecord>(
      async: async,
      emptyIcon: Icons.speed,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(odometerRecordsProvider(vehicleId));
        await ref.read(odometerRecordsProvider(vehicleId).future);
      },
      facets: RecordFacets<OdometerRecord>(
        searchIn: (r) => [r.notes, Formatters.odometer(r.odometer)],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            label: l10n.colDate,
            compare: (a, b) => _compareDates(a.date, b.date),
          ),
          RecordSort(
            label: l10n.colOdometer,
            compare: (a, b) => a.odometer.compareTo(b.odometer),
          ),
        ],
      ),
      builder: (records, filter) {
        // The gain over the previous reading is a property of the whole
        // chronological chain, so it is computed over every record and then
        // looked up per card — filtering or re-sorting the list first would
        // measure each reading against whatever happens to precede it on
        // screen.
        final ascending = [...records]
          ..sort((a, b) => _compareDates(a.date, b.date));
        final deltas = <int, double?>{};
        double? previous;
        for (final r in ascending) {
          final o = r.odometer;
          deltas[r.id] = (previous != null && o > previous)
              ? o - previous
              : null;
          previous = o > 0 ? o : previous;
        }
        final displayed = filter.apply(records);
        return RecordsContent(
          count: displayed.length,
          card: (context, index) {
            final r = displayed[index];
            return RecordCard(
              date: _date(r.date, units),
              headline: _odoUnit(r.odometer, units),
              meta: [
                RecordMetaItem(
                  Icons.trending_up,
                  _odoUnit(deltas[r.id], units),
                ),
                ..._extras(l10n, files: r.files, notes: r.notes),
              ],
              tags: splitTags(r.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: () => showAddOdometerForm(context, vehicleId, existing: r),
            );
          },
        );
      },
    );
  }
}

/// Generic (date + cost) record cards for service / repair / upgrade / tax.
/// Tax cards have no odometer meta item.
class GenericRecordsTab extends ConsumerWidget {
  const GenericRecordsTab({
    super.key,
    required this.vehicleId,
    required this.kind,
  });

  final int vehicleId;
  final RecordKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final key = (vehicleId: vehicleId, kind: kind);
    final async = ref.watch(vehicleRecordsProvider(key));

    return RecordsTabBody<VehicleRecord>(
      async: async,
      emptyIcon: Icons.receipt_long,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(vehicleRecordsProvider(key));
        await ref.read(vehicleRecordsProvider(key).future);
      },
      facets: RecordFacets<VehicleRecord>(
        searchIn: (r) => [r.description, r.notes],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            label: l10n.colDate,
            compare: (a, b) => _compareDates(a.date, b.date),
          ),
          RecordSort(
            label: l10n.colCost,
            compare: (a, b) => a.cost.compareTo(b.cost),
          ),
          if (kind.hasOdometer)
            RecordSort(
              label: l10n.colOdometer,
              compare: (a, b) => (a.odometer ?? 0).compareTo(b.odometer ?? 0),
            ),
          RecordSort(
            label: l10n.colDescription,
            compare: (a, b) => _byText(a.description, b.description),
            descendingByDefault: false,
          ),
        ],
      ),
      builder: (records, filter) {
        final sorted = filter.apply(records);
        return RecordsContent(
          count: sorted.length,
          card: (context, index) {
            final r = sorted[index];
            return RecordCard(
              date: _date(r.date, units),
              headline: Formatters.currency(r.cost, symbol),
              headlineColor: t.accentGoldInk,
              description: r.description.isEmpty ? _placeholder : r.description,
              meta: [
                if (kind.hasOdometer)
                  RecordMetaItem(Icons.speed, _odoUnit(r.odometer, units)),
                ..._extras(l10n, files: r.files, notes: r.notes),
              ],
              tags: splitTags(r.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: kind.editable
                  ? () => showGenericRecordForm(
                      context,
                      vehicleId,
                      kind,
                      existing: r,
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

/// Fuel history: summary pills + a card per fill-up (design handoff — date +
/// cost headline, meta row of odometer / Δ / economy / price-per-volume).
/// Economy uses [fuelRows]' fill-to-full accumulation so it matches the server.
class FuelTab extends ConsumerWidget {
  const FuelTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(gasRecordsProvider(vehicleId));
    final stats = ref.watch(gasStatsProvider(vehicleId)).value;

    String econ(double? rawRatio) {
      if (rawRatio == null) return _placeholder;
      final v = units.economyValue(rawRatio, 1);
      return v == null ? _placeholder : Formatters.number(v, decimals: 1);
    }

    // Cost per unit divides by what was bought, so an electric record uses the
    // energy it put in rather than the energy the battery later gave up.
    String pricePerUnit(GasRecord r) => r.fuelConsumed <= 0
        ? _placeholder
        : Formatters.currency(r.cost / r.fuelConsumed, symbol);

    String econMeta(double? rawRatio) {
      final v = econ(rawRatio);
      return v == _placeholder ? v : '$v ${units.economyLabel}';
    }

    String priceMeta(GasRecord r) {
      final v = pricePerUnit(r);
      return v == _placeholder ? v : '$v/${units.consumptionLabel}';
    }

    return RecordsTabBody<GasRecord>(
      async: async,
      emptyIcon: Icons.local_gas_station,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(gasRecordsProvider(vehicleId));
        await ref.read(gasRecordsProvider(vehicleId).future);
      },
      facets: RecordFacets<GasRecord>(
        searchIn: (r) => [r.notes, Formatters.odometer(r.odometer)],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            label: l10n.colDate,
            compare: (a, b) => _compareDates(a.date, b.date),
          ),
          RecordSort(
            label: l10n.colCost,
            compare: (a, b) => a.cost.compareTo(b.cost),
          ),
          RecordSort(
            label: l10n.colOdometer,
            compare: (a, b) => a.odometer.compareTo(b.odometer),
          ),
        ],
      ),
      builder: (records, filter) {
        // Economy accumulates across fill-ups (a missed or partial one carries
        // into the next), so the rows are built from every record in order and
        // only then narrowed — computing them from a filtered list would
        // silently restate every figure on the screen.
        final rows = fuelRows(records, isElectric: units.isElectric);
        final displayed = filter.sortStably([
          for (var i = rows.length - 1; i >= 0; i--)
            if (filter.matches(rows[i].record)) rows[i],
        ], (row) => row.record);
        // The pills stay lifetime figures, filter or no filter: an average
        // recomputed over an arbitrary subset of fill-ups is not this vehicle's
        // consumption, and the bar sits directly above them to say so.
        final totalFuel = rows.fold<double>(0, (s, r) => s + r.rawConsumption);
        final totalCost = records.fold<double>(0, (s, r) => s + r.cost);

        // Per-record economies in the display unit, for min/max. Avg uses the
        // lifetime distance÷volume ratio (matches the dashboard + server).
        final economies = <double>[
          for (final r in rows)
            if (r.rawRatio != null) units.economyValue(r.rawRatio!, 1)!,
        ];
        final avg = stats?.averageRawRatio;
        final avgDisplayed = avg == null ? null : units.economyValue(avg, 1);
        String econLabel(double? v) => v == null
            ? _placeholder
            : '${Formatters.number(v, decimals: 1)} ${units.economyLabel}';

        return RecordsContent(
          count: displayed.length,
          header: SummaryPillRow(
            pills: [
              DashPill(
                label: l10n.fuelPillRecords(records.length),
                accent: t.accentGold,
                accentInk: t.accentGoldInk,
              ),
              DashPill(
                label: l10n.fuelPillAvg(econLabel(avgDisplayed)),
                accent: t.accentBlue,
                accentInk: t.accentBlueInk,
              ),
              if (economies.isNotEmpty) ...[
                DashPill(
                  label: l10n.fuelPillMin(
                    econLabel(economies.reduce((a, b) => a < b ? a : b)),
                  ),
                  accent: t.accentBlue,
                  accentInk: t.accentBlueInk,
                ),
                DashPill(
                  label: l10n.fuelPillMax(
                    econLabel(economies.reduce((a, b) => a > b ? a : b)),
                  ),
                  accent: t.accentBlue,
                  accentInk: t.accentBlueInk,
                ),
              ],
              if (stats != null)
                DashPill(
                  label: l10n.fuelPillDistance(
                    _odoUnit(stats.distanceSpan, units),
                  ),
                  accent: t.accentOrange,
                  accentInk: t.accentOrangeInk,
                ),
              DashPill(
                label: (units.isElectric ? l10n.fuelPillEnergy : l10n.fuelPillFuel)(
                  '${Formatters.odometer(totalFuel)} ${units.consumptionLabel}',
                ),
                accent: t.accentOrange,
                accentInk: t.accentOrangeInk,
              ),
              DashPill(
                label: l10n.fuelPillCost(
                  Formatters.currency(totalCost, symbol),
                ),
                accent: t.accentGold,
                accentInk: t.accentGoldInk,
              ),
            ],
          ),
          card: (context, index) {
            final row = displayed[index];
            return RecordCard(
              date: _date(row.record.date, units),
              headline: Formatters.currency(row.record.cost, symbol),
              headlineColor: t.accentGoldInk,
              meta: [
                RecordMetaItem(
                  Icons.speed,
                  _odoUnit(row.record.odometer, units),
                ),
                RecordMetaItem(
                  Icons.trending_up,
                  _odoUnit(row.rawDelta, units),
                ),
                RecordMetaItem(Icons.local_gas_station, econMeta(row.rawRatio)),
                RecordMetaItem(Icons.sell, priceMeta(row.record)),
                ..._extras(
                  l10n,
                  files: row.record.files,
                  notes: row.record.notes,
                ),
              ],
              tags: splitTags(row.record.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: () =>
                  showAddFuelForm(context, vehicleId, existing: row.record),
            );
          },
        );
      },
    );
  }
}

/// Supply / part records as cards: date + cost headline, with part number,
/// supplier and quantity in the meta row.
class SupplyTab extends ConsumerWidget {
  const SupplyTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(supplyRecordsProvider(vehicleId));

    return RecordsTabBody<SupplyRecord>(
      async: async,
      emptyIcon: Icons.inventory_2_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(supplyRecordsProvider(vehicleId));
        await ref.read(supplyRecordsProvider(vehicleId).future);
      },
      facets: RecordFacets<SupplyRecord>(
        // A part is looked for by its number or its supplier at least as often
        // as by what it was called.
        searchIn: (r) => [r.description, r.notes, r.partNumber, r.partSupplier],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            label: l10n.colDate,
            compare: (a, b) => _compareDates(a.date, b.date),
          ),
          RecordSort(
            label: l10n.colCost,
            compare: (a, b) => a.cost.compareTo(b.cost),
          ),
          RecordSort(
            label: l10n.colDescription,
            compare: (a, b) => _byText(a.description, b.description),
            descendingByDefault: false,
          ),
        ],
      ),
      builder: (records, filter) {
        final sorted = filter.apply(records);
        return RecordsContent(
          count: sorted.length,
          card: (context, index) {
            final r = sorted[index];
            return RecordCard(
              date: _date(r.date, units),
              headline: Formatters.currency(r.cost, symbol),
              headlineColor: t.accentGoldInk,
              description: r.description.isEmpty ? _placeholder : r.description,
              meta: [
                if (r.partNumber.isNotEmpty)
                  RecordMetaItem(Icons.tag, r.partNumber),
                if (r.partSupplier.isNotEmpty)
                  RecordMetaItem(Icons.storefront, r.partSupplier),
                if (r.partQuantity.isNotEmpty)
                  RecordMetaItem(Icons.numbers, r.partQuantity),
                ..._extras(l10n, files: r.files, notes: r.notes),
              ],
              tags: splitTags(r.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: () => showAddSupplyForm(context, vehicleId, existing: r),
            );
          },
        );
      },
    );
  }
}

/// Planner items as cards: creation date + estimated cost, with priority and
/// progress in the meta row.
class PlanTab extends ConsumerWidget {
  const PlanTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final symbol = ref.watch(currencySymbolProvider);
    final async = ref.watch(planRecordsProvider(vehicleId));

    return RecordsTabBody<PlanRecord>(
      async: async,
      emptyIcon: Icons.checklist_rtl,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(planRecordsProvider(vehicleId));
        await ref.read(planRecordsProvider(vehicleId).future);
      },
      facets: RecordFacets<PlanRecord>(
        searchIn: (r) => [r.description, r.notes],
        // The planner is the one record type the server stores no tags for
        // (`PlanRecordExportModel` has no field for them).
        tagsOf: (_) => '',
        sorts: [
          RecordSort(
            label: l10n.colDate,
            compare: (a, b) => _compareDates(a.dateCreated, b.dateCreated),
          ),
          RecordSort(
            label: l10n.formPlanPriority,
            compare: (a, b) =>
                _priorityRank(a.priority).compareTo(_priorityRank(b.priority)),
          ),
          RecordSort(
            label: l10n.formPlanProgress,
            // Ascending: backlog first, done last — the board's own order, and
            // what is left to do is the reason to open this tab.
            compare: (a, b) =>
                _progressRank(a.progress).compareTo(_progressRank(b.progress)),
            descendingByDefault: false,
          ),
          RecordSort(
            label: l10n.colCost,
            compare: (a, b) => a.cost.compareTo(b.cost),
          ),
        ],
      ),
      builder: (records, filter) {
        final sorted = filter.apply(records);
        return RecordsContent(
          count: sorted.length,
          card: (context, index) {
            final r = sorted[index];
            return RecordCard(
              date: _date(r.dateCreated, units),
              headline: Formatters.currency(r.cost, symbol),
              headlineColor: t.accentGoldInk,
              description: r.description.isEmpty ? _placeholder : r.description,
              meta: [
                RecordMetaItem(
                  Icons.flag_outlined,
                  _planPriority(r.priority, l10n),
                ),
                RecordMetaItem(
                  Icons.timelapse,
                  _planProgress(r.progress, l10n),
                ),
                ..._extras(l10n, files: r.files, notes: r.notes),
              ],
              onTap: () => showAddPlanForm(context, vehicleId, existing: r),
            );
          },
        );
      },
    );
  }
}

/// Reminders as cards: the description leads, a color-coded urgency badge sits
/// at the right, and the due date / odometer follow in the meta row. Sorted
/// most-urgent first.
class ReminderTab extends ConsumerWidget {
  const ReminderTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final async = ref.watch(remindersProvider(vehicleId));

    return RecordsTabBody<ReminderRecord>(
      async: async,
      emptyIcon: Icons.notifications_active_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(remindersProvider(vehicleId));
        await ref.read(remindersProvider(vehicleId).future);
      },
      facets: RecordFacets<ReminderRecord>(
        searchIn: (r) => [r.description, r.notes],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            label: l10n.colUrgency,
            compare: (a, b) =>
                _urgencyRank(a.urgency).compareTo(_urgencyRank(b.urgency)),
          ),
          RecordSort(
            label: l10n.colDate,
            // Ascending by due date reads as "soonest first", which is the
            // question this tab answers.
            compare: (a, b) => _compareDates(a.dueDate, b.dueDate),
            descendingByDefault: false,
          ),
          RecordSort(
            label: l10n.colDescription,
            compare: (a, b) => _byText(a.description, b.description),
            descendingByDefault: false,
          ),
        ],
      ),
      builder: (records, filter) {
        final sorted = filter.apply(records);
        return RecordsContent(
          count: sorted.length,
          card: (context, index) {
            final r = sorted[index];
            return RecordCard(
              // Reminders have no date/cost; the description leads instead.
              date: r.description.isEmpty ? _placeholder : r.description,
              headline: _urgencyLabel(r.urgency, l10n),
              headlineColor: _urgencyColor(r.urgency, t),
              meta: [
                if (r.showsDate)
                  RecordMetaItem(Icons.event, _date(r.dueDate, units)),
                if (r.showsOdometer)
                  RecordMetaItem(Icons.speed, _odoUnit(r.dueOdometer, units)),
                // Reminders are the one type with no attachments (the server's
                // ReminderExportModel has no files field).
                ..._extras(l10n, notes: r.notes),
              ],
              tags: splitTags(r.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: () => showAddReminderForm(context, vehicleId, existing: r),
            );
          },
        );
      },
    );
  }
}

/// Notes as cards: the title leads with the body below; pinned notes are
/// flagged in the meta row and sorted to the top.
class NoteTab extends ConsumerWidget {
  const NoteTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notesProvider(vehicleId));

    return RecordsTabBody<NoteRecord>(
      async: async,
      emptyIcon: Icons.sticky_note_2_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(notesProvider(vehicleId));
        await ref.read(notesProvider(vehicleId).future);
      },
      facets: RecordFacets<NoteRecord>(
        searchIn: (r) => [r.description, r.noteText],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            // Pinned first, otherwise the server's own order — which the
            // filter's stable sort preserves.
            label: l10n.notePinned,
            compare: (a, b) => (a.pinned ? 1 : 0).compareTo(b.pinned ? 1 : 0),
          ),
          RecordSort(
            label: l10n.colDescription,
            compare: (a, b) => _byText(a.description, b.description),
            descendingByDefault: false,
          ),
        ],
      ),
      builder: (records, filter) {
        final sorted = filter.apply(records);
        return RecordsContent(
          count: sorted.length,
          card: (context, index) {
            final r = sorted[index];
            return RecordCard(
              // Notes have no date/cost; the title leads instead.
              date: r.description.isEmpty ? _placeholder : r.description,
              headline: '',
              description: r.noteText.isEmpty ? null : r.noteText,
              meta: [
                if (r.pinned) RecordMetaItem(Icons.push_pin, l10n.notePinned),
                // The note's own text is the description above; only its files
                // are hidden.
                ..._extras(l10n, files: r.files),
              ],
              tags: splitTags(r.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: () => showAddNoteForm(context, vehicleId, existing: r),
            );
          },
        );
      },
    );
  }
}

/// Equipment items as cards: the name leads, an equipped/removed badge sits at
/// the right, and the distance traveled while equipped follows in the meta row.
class EquipmentTab extends ConsumerWidget {
  const EquipmentTab({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(vehicleId));
    final async = ref.watch(equipmentRecordsProvider(vehicleId));

    return RecordsTabBody<EquipmentRecord>(
      async: async,
      emptyIcon: Icons.handyman_outlined,
      emptyLabel: l10n.recordsEmpty,
      onRefresh: () async {
        ref.invalidate(equipmentRecordsProvider(vehicleId));
        await ref.read(equipmentRecordsProvider(vehicleId).future);
      },
      facets: RecordFacets<EquipmentRecord>(
        searchIn: (r) => [r.description, r.notes],
        tagsOf: (r) => r.tags,
        sorts: [
          RecordSort(
            label: l10n.colDescription,
            compare: (a, b) => _byText(a.description, b.description),
            descendingByDefault: false,
          ),
          RecordSort(
            label: l10n.colDistance,
            compare: (a, b) =>
                (a.distanceTraveled ?? 0).compareTo(b.distanceTraveled ?? 0),
          ),
        ],
      ),
      builder: (records, filter) {
        final sorted = filter.apply(records);
        return RecordsContent(
          count: sorted.length,
          card: (context, index) {
            final r = sorted[index];
            return RecordCard(
              // Equipment has no date/cost; the name leads instead.
              date: r.description.isEmpty ? _placeholder : r.description,
              headline: r.isEquipped
                  ? l10n.equipmentEquipped
                  : l10n.equipmentRemoved,
              headlineColor: r.isEquipped ? equippedInk(t) : t.textTertiary,
              description: r.notes.isEmpty ? null : r.notes,
              meta: [
                if (r.distanceTraveled != null)
                  RecordMetaItem(
                    Icons.route,
                    _odoUnit(r.distanceTraveled, units),
                  ),
                // Equipment prints its notes as the description above.
                ..._extras(l10n, files: r.files),
              ],
              tags: splitTags(r.tags),
              activeTags: filter.activeTags,
              onTagTap: filter.onTagTap,
              onTap: () =>
                  showAddEquipmentForm(context, vehicleId, existing: r),
            );
          },
        );
      },
    );
  }
}

/// Positive-status green for an equipped item: the dashboard's OK green in the
/// dark theme, and that hue darkened in the light one, where the swatch reads
/// 2.3:1 as a headline. `brand_contrast_test.dart` measures both.
@visibleForTesting
Color equippedInk(DashTokens t) =>
    t.isDark ? const Color(0xFF4CAF6E) : const Color(0xFF317147);

String _planPriority(PlanPriority p, AppLocalizations l10n) => switch (p) {
  PlanPriority.critical => l10n.planPriorityCritical,
  PlanPriority.normal => l10n.planPriorityNormal,
  PlanPriority.low => l10n.planPriorityLow,
  PlanPriority.unknown => _placeholder,
};

String _planProgress(PlanProgress p, AppLocalizations l10n) => switch (p) {
  PlanProgress.backlog => l10n.planProgressBacklog,
  PlanProgress.inProgress => l10n.planProgressInProgress,
  PlanProgress.testing => l10n.planProgressTesting,
  PlanProgress.done => l10n.planProgressDone,
  PlanProgress.unknown => _placeholder,
};

String _urgencyLabel(ReminderUrgency u, AppLocalizations l10n) => switch (u) {
  ReminderUrgency.notUrgent => l10n.urgencyNotUrgent,
  ReminderUrgency.urgent => l10n.urgencyUrgent,
  ReminderUrgency.veryUrgent => l10n.urgencyVeryUrgent,
  ReminderUrgency.pastDue => l10n.urgencyPastDue,
  ReminderUrgency.unknown => _placeholder,
};

Color _urgencyColor(ReminderUrgency u, DashTokens t) => switch (u) {
  ReminderUrgency.notUrgent => t.textTertiary,
  ReminderUrgency.urgent => t.accentOrangeInk,
  ReminderUrgency.veryUrgent => t.dangerInk,
  ReminderUrgency.pastDue => t.dangerInk,
  ReminderUrgency.unknown => t.textTertiary,
};

/// Sort weight for a planner item's priority: critical outranks normal.
int _priorityRank(PlanPriority p) => switch (p) {
  PlanPriority.critical => 2,
  PlanPriority.normal => 1,
  PlanPriority.low => 0,
  PlanPriority.unknown => -1,
};

/// Sort weight following the board's own left-to-right order.
int _progressRank(PlanProgress p) => switch (p) {
  PlanProgress.backlog => 0,
  PlanProgress.inProgress => 1,
  PlanProgress.testing => 2,
  PlanProgress.done => 3,
  PlanProgress.unknown => 4,
};

/// Sort weight so the most pressing reminders float to the top.
int _urgencyRank(ReminderUrgency u) => switch (u) {
  ReminderUrgency.pastDue => 3,
  ReminderUrgency.veryUrgent => 2,
  ReminderUrgency.urgent => 1,
  ReminderUrgency.notUrgent => 0,
  ReminderUrgency.unknown => -1,
};

/// A→Z, case-insensitively: a sort by name that put every lowercase entry after
/// every uppercase one would look broken.
int _byText(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

/// Chronological compare with nulls sorted last.
int _compareDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
