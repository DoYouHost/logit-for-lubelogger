import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/format/fuel_entry_mode.dart';
import '../../../core/format/vehicle_units.dart';
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
import 'record_form_scaffold.dart';

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
  late RangeValues _soc;
  late bool _fillToFull;
  late bool _missedFuelUp;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  /// The two of price, fuel and cost the third is calculated from: the
  /// Settings pair on a new record, the stored pair on an existing one. Always
  /// two: typing into the third while one of them is empty swaps that one out,
  /// for this record only.
  final List<TextEditingController> _typed = [];

  /// Price, fuel and cost in display order: the pair first, so the keyboard's
  /// next key walks straight through it, and the calculated field last.
  late final List<TextEditingController> _order;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    _fillToFull = e?.isFillToFull ?? true;
    _missedFuelUp = e?.missedFuelUp ?? false;
    _soc = RangeValues(
      (e?.startingSoc ?? GasRecord.defaultStartingSoc).toDouble(),
      (e?.endingSoc ?? GasRecord.defaultEndingSoc).toDouble(),
    );
    // An existing record calculates the price whatever Settings say, so its
    // stored fuel and cost are saved back unchanged.
    _order = switch (e == null
        ? ref.read(fuelEntryModeProvider)
        : FuelEntryMode.costAndFuel) {
      FuelEntryMode.costAndFuel => [_fuel, _cost, _price],
      FuelEntryMode.priceAndCost => [_price, _cost, _fuel],
      FuelEntryMode.priceAndFuel => [_price, _fuel, _cost],
    };
    _typed.addAll(_order.take(2));
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
      _recompute();
    }
  }

  TextEditingController get _calculated =>
      [_price, _fuel, _cost].firstWhere((c) => !_typed.contains(c));

  bool _isEmpty(TextEditingController c) => c.text.trim().isEmpty;

  /// The calculated field is greyed out only once both inputs have a value, so
  /// a pair whose input is empty can be swapped by typing into the third.
  TextEditingController? get _locked =>
      _typed.any(_isEmpty) ? null : _calculated;

  /// A field the user edited by hand (a calculated write does not call this).
  void _typedIn(TextEditingController field) {
    // The third takes input only while unlocked, so one of the pair is empty.
    final empty = _typed.indexWhere(_isEmpty);
    if (!_isEmpty(field) && !_typed.contains(field) && empty >= 0) {
      _typed[empty] = field;
    }
    setState(_recompute);
  }

  /// Also empties the calculated field while an input is missing.
  void _recompute() {
    final target = _calculated;
    final value = deriveFuelEntry(
      target == _price
          ? FuelEntryMode.costAndFuel
          : target == _fuel
          ? FuelEntryMode.priceAndCost
          : FuelEntryMode.priceAndFuel,
      price: parseUserDecimal(_price.text),
      cost: parseUserDecimal(_cost.text),
      fuel: parseUserDecimal(_fuel.text),
    );
    target.text = value == null ? '' : formatFormNumber(value);
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

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formFuelEditTitle : l10n.formFuelTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: _isEditing ? _confirmDelete : null,
      error: _error,
      fields: [
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
        for (final field in _order) ...[
          const SizedBox(height: DashSpace.lg),
          _linkedField(field, units, l10n),
        ],
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
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _tags,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.formTagsOptional),
        ),
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _notes,
          enabled: !_submitting,
          minLines: 2,
          maxLines: 4,
          decoration: dashFieldDecoration(t, labelText: l10n.formNotesOptional),
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
      ],
    );
  }

  Widget _linkedField(
    TextEditingController field,
    VehicleUnits units,
    AppLocalizations l10n,
  ) {
    if (field == _price) {
      return _numberField(
        controller: _price,
        label: units.isElectric
            ? l10n.formEnergyPriceLabel(units.consumptionLabel)
            : l10n.formFuelPriceLabel(units.consumptionLabel),
        allowZero: true,
        // Not stored, so it is required only while the calculation reads it.
        optional: !_typed.contains(_price),
        linked: true,
      );
    }
    if (field == _fuel) {
      return _numberField(
        controller: _fuel,
        label: units.isElectric
            ? l10n.formEnergyLabel(units.consumptionLabel)
            : l10n.formFuelLabel(units.consumptionLabel),
        linked: true,
      );
    }
    return _numberField(
      controller: _cost,
      label: l10n.colCost,
      allowZero: true,
      linked: true,
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool decimal = true,
    bool allowZero = false,
    bool optional = false,
    bool linked = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return TextFormField(
      controller: controller,
      // The calculated field is greyed out; a disabled field still validates,
      // which matters when its value comes out as zero.
      enabled: !_submitting && controller != _locked,
      keyboardType: numberKeyboard(decimal: decimal),
      // A disabled field cannot take focus, so next skips the calculated one.
      textInputAction: TextInputAction.next,
      inputFormatters: decimal
          ? decimalInputFormatters
          : integerInputFormatters,
      style: const TextStyle(fontFamily: DashTokens.fontMono),
      decoration: dashFieldDecoration(t, labelText: label),
      onChanged: linked ? (_) => _typedIn(controller) : null,
      validator: (raw) {
        final value = parseUserDecimal(raw);
        if (value == null) {
          if (optional && (raw == null || raw.trim().isEmpty)) return null;
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
    if (!_formKey.currentState!.validate()) return;
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
