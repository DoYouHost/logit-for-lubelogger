import 'dart:async';

import 'package:app_util/app_util.dart';
import 'package:flutter/material.dart';
import '../../../core/diagnostics/log_form.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/format/fuel_entry_mode.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/gas_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'form_fields.dart';

/// Opens the "Add fuel record" form as a modal bottom sheet. Pass [existing] to
/// edit that record instead (prefilled, with a delete option). Resolves to
/// `true` once a record was added/updated/deleted (so the caller can refresh
/// or confirm), or `null` if cancelled.
Future<bool?> showAddFuelForm(
  BuildContext context,
  int vehicleId, {
  GasRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.fuel',
      _AddFuelForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddFuelForm extends ConsumerStatefulWidget {
  const _AddFuelForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final GasRecord? existing;

  @override
  ConsumerState<_AddFuelForm> createState() => _AddFuelFormState();
}

class _AddFuelFormState extends ConsumerState<_AddFuelForm> {
  final _formKey = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _price = TextEditingController();
  final _fuel = TextEditingController();
  final _cost = TextEditingController();
  final _tags = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _date;
  late FuelEntryMode _mode;
  late RangeValues _soc;
  late bool _fillToFull;
  late bool _missedFuelUp;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    // An edit opens on the record's own pair: deriving a stored value back from
    // a rounded price could nudge it, and the user did not ask for that.
    _mode = e == null
        ? ref.read(fuelEntryModeProvider)
        : FuelEntryMode.costAndFuel;
    _date = e?.date ?? DateTime.now();
    _fillToFull = e?.isFillToFull ?? true;
    _missedFuelUp = e?.missedFuelUp ?? false;
    _soc = RangeValues(
      (e?.startingSoc ?? GasRecord.defaultStartingSoc).toDouble(),
      (e?.endingSoc ?? GasRecord.defaultEndingSoc).toDouble(),
    );
    if (e != null) {
      _odometer.text = formatFormNumber(
        ref
            .read(vehicleUnitsProvider(widget.vehicleId))
            .toDisplayOdometer(e.odometer),
      );
      _fuel.text = formatFormNumber(e.fuelConsumed);
      _cost.text = formatFormNumber(e.cost);
      _tags.text = e.tags;
      _notes.text = e.notes;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
    _price.addListener(_recompute);
    _fuel.addListener(_recompute);
    _cost.addListener(_recompute);
    _recompute();
  }

  TextEditingController get _derived => switch (_mode) {
    FuelEntryMode.costAndFuel => _price,
    FuelEntryMode.priceAndCost => _fuel,
    FuelEntryMode.priceAndFuel => _cost,
  };

  /// Fills the field the mode calculates. Writes only when the text differs, so
  /// the listener the write itself triggers settles on the second pass.
  void _recompute() {
    final value = deriveFuelEntry(
      _mode,
      price: parseUserDecimal(_price.text),
      cost: parseUserDecimal(_cost.text),
      fuel: parseUserDecimal(_fuel.text),
    );
    final text = value == null ? '' : formatFormNumber(value);
    if (_derived.text != text) _derived.text = text;
  }

  void _setMode(FuelEntryMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _recompute();
    unawaited(ref.read(fuelEntryModeProvider.notifier).set(mode));
  }

  @override
  void dispose() {
    _odometer.dispose();
    _price.dispose();
    _fuel.dispose();
    _cost.dispose();
    _tags.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(widget.vehicleId));

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DashSpace.xl,
          DashSpace.xs,
          DashSpace.xl,
          DashSpace.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? l10n.formFuelEditTitle : l10n.formFuelTitle,
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: t.dangerInk),
                      onPressed: _submitting ? null : _confirmDelete,
                    ).tagged('form.delete'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                  ).tagged('form.close'),
                ],
              ),
              const SizedBox(height: DashSpace.sm),
              DateField(
                text: units.formatDate(_date),
                onPick: _submitting ? null : _pickDate,
              ),
              const SizedBox(height: DashSpace.lg),
              _numberField(
                controller: _odometer,
                label: l10n.formOdometerLabel(units.distanceLabel),
                decimal: false,
              ),
              const SizedBox(height: DashSpace.lg),
              _EntryModeSelector(
                mode: _mode,
                onChanged: _submitting ? null : _setMode,
              ),
              const SizedBox(height: DashSpace.lg),
              // Hidden in the default mode so the form reads as it always did;
              // there the price is calculated and not stored anyway.
              if (_mode != FuelEntryMode.costAndFuel) ...[
                _numberField(
                  controller: _price,
                  label: units.isElectric
                      ? l10n.formEnergyPriceLabel(units.consumptionLabel)
                      : l10n.formFuelPriceLabel(units.consumptionLabel),
                  // A free fill-up has a price of 0, but it cannot divide.
                  allowZero: _mode == FuelEntryMode.priceAndFuel,
                ),
                const SizedBox(height: DashSpace.lg),
              ],
              _numberField(
                controller: _fuel,
                label: units.isElectric
                    ? l10n.formEnergyLabel(units.consumptionLabel)
                    : l10n.formFuelLabel(units.consumptionLabel),
                calculated: _mode == FuelEntryMode.priceAndCost,
              ),
              // Electric only, like the web's dual-range slider: the server
              // reads state of charge for no other kind of vehicle.
              if (units.isElectric) ...[
                const SizedBox(height: DashSpace.lg),
                _SocField(
                  values: _soc,
                  enabled: !_submitting,
                  onChanged: (v) => setState(() => _soc = v),
                ),
              ],
              const SizedBox(height: DashSpace.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.formFillToFull),
                value: _fillToFull,
                // A missed fuel-up has no meaningful "filled to full" state.
                onChanged: _submitting || _missedFuelUp
                    ? null
                    : (v) => setState(() => _fillToFull = v),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.formMissedFuelUp),
                value: _missedFuelUp,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _missedFuelUp = v ?? false),
              ),
              const SizedBox(height: DashSpace.sm),
              _numberField(
                controller: _cost,
                label: l10n.colCost,
                allowZero: _mode != FuelEntryMode.priceAndCost,
                calculated: _mode == FuelEntryMode.priceAndFuel,
              ),
              const SizedBox(height: DashSpace.lg),
              TextFormField(
                controller: _tags,
                enabled: !_submitting,
                decoration: dashFieldDecoration(
                  t,
                  labelText: l10n.formTagsOptional,
                ),
              ),
              const SizedBox(height: DashSpace.lg),
              TextFormField(
                controller: _notes,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 4,
                decoration: dashFieldDecoration(
                  t,
                  labelText: l10n.formNotesOptional,
                ),
              ),
              const SizedBox(height: DashSpace.lg),
              ExtraFieldsField(
                recordType: ExtraFieldRecordType.gas,
                initial: _extraFields,
                enabled: !_submitting,
                onChanged: (fields) => _extraFields = fields,
              ),
              const SizedBox(height: DashSpace.lg),
              AttachmentsField(
                initial: _files,
                enabled: !_submitting,
                onChanged: (files) => _files = files,
              ),
              if (_error != null) ...[
                const SizedBox(height: DashSpace.md),
                Text(
                  _error!,
                  style: TextStyle(
                    color: t.dangerInk,
                    fontFamily: DashTokens.fontUi,
                  ),
                ),
              ],
              const SizedBox(height: DashSpace.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ).tagged('form.cancel'),
                  ),
                  const SizedBox(width: DashSpace.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? l10n.actionSave : l10n.actionAdd),
                    ).tagged('form.submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool decimal = true,
    bool allowZero = false,
    bool calculated = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return TextFormField(
      controller: controller,
      // A calculated field is disabled, which greys it out; it still validates,
      // since a calculated amount can come out as zero.
      enabled: !_submitting && !calculated,
      keyboardType: numberKeyboard(decimal: decimal),
      inputFormatters: decimal
          ? decimalInputFormatters
          : integerInputFormatters,
      style: const TextStyle(fontFamily: DashTokens.fontMono),
      decoration: dashFieldDecoration(t, labelText: label),
      validator: (raw) {
        final value = parseUserDecimal(raw);
        if (value == null) {
          return (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : l10n.validationNumber;
        }
        if (value < 0 || (!allowZero && value == 0)) {
          return l10n.validationNumber;
        }
        return null;
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(
      context,
      initial: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(_date.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!validateAndLog(context, _formKey)) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(vehiclesRepositoryProvider);
    final odometer = ref
        .read(vehicleUnitsProvider(widget.vehicleId))
        .toStoredDistance(parseUserDecimal(_odometer.text)!.toDouble());
    final existing = widget.existing;
    try {
      if (existing == null) {
        await repo.addGasRecord(
          vehicleId: widget.vehicleId,
          date: _date,
          odometer: odometer,
          fuelConsumed: parseUserDecimal(_fuel.text)!,
          cost: parseUserDecimal(_cost.text)!,
          isFillToFull: _fillToFull,
          missedFuelUp: _missedFuelUp,
          startingSoc: _soc.start.round(),
          endingSoc: _soc.end.round(),
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updateGasRecord(
          vehicleId: widget.vehicleId,
          id: existing.id,
          date: _date,
          odometer: odometer,
          fuelConsumed: parseUserDecimal(_fuel.text)!,
          cost: parseUserDecimal(_cost.text)!,
          isFillToFull: _fillToFull,
          missedFuelUp: _missedFuelUp,
          startingSoc: _soc.start.round(),
          endingSoc: _soc.end.round(),
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      }
      _invalidateFuelProviders();
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? l10n.recordAdded : l10n.recordUpdated,
          ),
        ),
      );
    } on AppApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.localized(l10n);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = existing == null
            ? l10n.recordAddError
            : l10n.recordUpdateError;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDelete(context, what: 'record');
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(vehiclesRepositoryProvider)
          .deleteGasRecord(widget.existing!.id);
      _invalidateFuelProviders();
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.recordDeleted)));
    } on AppApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.localized(l10n);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.recordDeleteError;
      });
    }
  }

  /// Refreshes every view derived from the refuel log after an add/update/delete.
  /// The fuel statistics and the monthly breakdown watch the log, so dropping it
  /// is enough for them.
  void _invalidateFuelProviders() {
    ref.invalidate(gasRecordsProvider(widget.vehicleId));
    ref.invalidate(vehicleInfoProvider(widget.vehicleId));
  }
}

/// Picks which two of price, total cost and fuel amount are typed. The third
/// is calculated: shown greyed out, except the price in the default mode.
class _EntryModeSelector extends StatelessWidget {
  const _EntryModeSelector({required this.mode, required this.onChanged});

  final FuelEntryMode mode;
  final ValueChanged<FuelEntryMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.formEntryModeHint,
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: DashSpace.xs),
        SegmentedButton<FuelEntryMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: FuelEntryMode.costAndFuel,
              label: Text(l10n.formEntryModeCostAmount),
            ),
            ButtonSegment(
              value: FuelEntryMode.priceAndCost,
              label: Text(l10n.formEntryModePriceCost),
            ),
            ButtonSegment(
              value: FuelEntryMode.priceAndFuel,
              label: Text(l10n.formEntryModePriceAmount),
            ),
          ],
          selected: {mode},
          onSelectionChanged: onChanged == null
              ? null
              : (selection) => onChanged!(selection.first),
        ).tagged('form.fuel.entryMode'),
      ],
    );
  }
}

/// Battery charge before and after a charging session, as a percentage range —
/// the app's take on the web's dual-range slider. Equal ends are allowed, as
/// they are there, even though the server then derives no battery capacity.
class _SocField extends StatelessWidget {
  const _SocField({
    required this.values,
    required this.enabled,
    required this.onChanged,
  });

  final RangeValues values;
  final bool enabled;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.formStateOfCharge,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            Text(
              l10n.formStateOfChargeRange(
                values.start.round(),
                values.end.round(),
              ),
              style: TextStyle(
                fontFamily: DashTokens.fontMono,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.accentGoldInk,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: t.accentGold,
          labels: RangeLabels(
            '${values.start.round()}%',
            '${values.end.round()}%',
          ),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
