import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/diagnostics/log_form.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/format/formatters.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/odometer_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'form_fields.dart';

/// Opens the "Add odometer reading" form as a modal bottom sheet. Pass
/// [existing] to edit that reading instead (prefilled, with a delete option).
/// Resolves to `true` once a reading was added/updated/deleted, or `null` if
/// cancelled.
Future<bool?> showAddOdometerForm(
  BuildContext context,
  int vehicleId, {
  OdometerRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.odometer',
      _AddOdometerForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddOdometerForm extends ConsumerStatefulWidget {
  const _AddOdometerForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final OdometerRecord? existing;

  @override
  ConsumerState<_AddOdometerForm> createState() => _AddOdometerFormState();
}

class _AddOdometerFormState extends ConsumerState<_AddOdometerForm> {
  final _formKey = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _tags = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _date;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    // The warning under the field tracks what is being typed, not what is
    // submitted — a wrong digit is worth catching before the save button.
    _odometer.addListener(() => setState(() {}));
    if (e != null) {
      _odometer.text = formatFormNumber(
        ref
            .read(vehicleUnitsProvider(widget.vehicleId))
            .toDisplayOdometer(e.odometer),
      );
      _tags.text = e.tags;
      _notes.text = e.notes;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
  }

  @override
  void dispose() {
    _odometer.dispose();
    _tags.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(widget.vehicleId));
    final previous = _previousReading(
      ref.watch(odometerRecordsProvider(widget.vehicleId)).value ?? const [],
      // Only an added reading can fall back to it, so an edit does not even
      // ask — watching it would fetch the vehicle for a value it discards.
      _isEditing
          ? null
          : ref
                .watch(vehicleInfoProvider(widget.vehicleId))
                .value
                ?.lastReportedOdometer,
    );
    final previousText = previous == null
        ? null
        : '${Formatters.odometer(units.toDisplayOdometer(previous))} '
              '${units.distanceLabel}';
    final entered = _enteredReading;
    final goesBackwards =
        previous != null && entered != null && entered < previous;

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
                      _isEditing
                          ? l10n.formOdometerEditTitle
                          : l10n.formOdometerTitle,
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
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: Icon(Icons.delete_outline, color: t.dangerInk),
                      onPressed: _submitting ? null : _confirmDelete,
                    ).tagged('form.delete'),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
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
              TextFormField(
                controller: _odometer,
                enabled: !_submitting,
                keyboardType: numberKeyboard(decimal: false),
                inputFormatters: integerInputFormatters,
                style: const TextStyle(fontFamily: DashTokens.fontMono),
                decoration:
                    dashFieldDecoration(
                      t,
                      labelText: l10n.formOdometerLabel(units.distanceLabel),
                    ).copyWith(
                      // One line under the field, which turns from the hint into
                      // the warning. A lower reading is legitimate often enough (a
                      // swapped cluster, a correction) that it must not block the
                      // save — hence this and a confirmation on submit, rather than
                      // a validator error.
                      helperText: previousText == null
                          ? null
                          : goesBackwards
                          ? l10n.formOdometerBackwards(previousText)
                          : l10n.formOdometerLast(previousText),
                      helperStyle: goesBackwards
                          ? TextStyle(color: t.accentOrange)
                          : null,
                      helperMaxLines: 2,
                    ),
                validator: (raw) {
                  final value = parseUserDecimal(raw);
                  if (value == null) {
                    return (raw == null || raw.trim().isEmpty)
                        ? l10n.validationRequired
                        : l10n.validationNumber;
                  }
                  if (value <= 0) return l10n.validationNumber;
                  return null;
                },
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
                recordType: ExtraFieldRecordType.odometer,
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

  /// The reading this one follows, in stored units, or null when the app knows
  /// of none.
  ///
  /// "Follows" is by date, not by insertion: editing a three-year-old entry has
  /// to be measured against the entry before *it*, or every old record would be
  /// flagged as going backwards simply for being old.
  ///
  /// Readings also arrive with fuel-ups and services, which this list does not
  /// hold. The server's own `lastReportedOdometer` counts those, so it fills in
  /// for a garage that logs no odometer records at all — but it says nothing
  /// about *when* that reading was taken, so an edit never uses it.
  double? _previousReading(List<OdometerRecord> records, double? reported) {
    final existingId = widget.existing?.id;
    double? best;
    for (final r in records) {
      if (r.id == existingId || r.odometer <= 0) continue;
      if (r.date != null && r.date!.isAfter(_date)) continue;
      if (best == null || r.odometer > best) best = r.odometer;
    }
    if (best != null || _isEditing) return best;
    return (reported != null && reported > 0) ? reported : null;
  }

  /// [_previousReading]'s inputs, read rather than watched — for the submit
  /// path, which runs outside a build.
  double? _previousReadingNow() => _previousReading(
    ref.read(odometerRecordsProvider(widget.vehicleId)).value ?? const [],
    _isEditing
        ? null
        : ref
              .read(vehicleInfoProvider(widget.vehicleId))
              .value
              ?.lastReportedOdometer,
  );

  /// Reading currently in the field, in stored units.
  double? get _enteredReading {
    final value = parseUserDecimal(_odometer.text);
    if (value == null || value <= 0) return null;
    return ref
        .read(vehicleUnitsProvider(widget.vehicleId))
        .toStoredDistance(value.toDouble());
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
    if (!await _confirmBackwards(l10n)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(vehiclesRepositoryProvider);
    final units = ref.read(vehicleUnitsProvider(widget.vehicleId));
    final odometer = units.toStoredDistance(
      parseUserDecimal(_odometer.text)!.toDouble(),
    );
    final existing = widget.existing;
    try {
      if (existing == null) {
        await repo.addOdometerRecord(
          vehicleId: widget.vehicleId,
          date: _date,
          odometer: odometer,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updateOdometerRecord(
          id: existing.id,
          date: _date,
          odometer: odometer,
          // The update endpoint requires initialOdometer; preserve the record's.
          initialOdometer: existing.initialOdometer,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
          equipmentRecordId: existing.equipmentRecordId,
        );
      }
      _invalidateOdometerProviders();
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

  /// Asks once when the reading goes below the one it follows. True means carry
  /// on — including when there is nothing to warn about.
  ///
  /// The inline warning is easy to type straight past; a reading with a fumbled
  /// digit poisons every number derived from it (the gain since last, fuel
  /// economy, the distance chart), and nothing later in the app can tell it from
  /// a real one.
  Future<bool> _confirmBackwards(AppLocalizations l10n) async {
    final previous = _previousReadingNow();
    final entered = _enteredReading;
    if (previous == null || entered == null || entered >= previous) return true;

    final units = ref.read(vehicleUnitsProvider(widget.vehicleId));
    final value =
        '${Formatters.odometer(units.toDisplayOdometer(previous))} '
        '${units.distanceLabel}';
    return confirmRisky(
      context,
      what: 'odometer_backwards',
      title: l10n.formOdometerBackwardsTitle,
      message: l10n.formOdometerBackwardsMessage(value),
      confirmLabel: l10n.actionSaveAnyway,
    );
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
          .deleteOdometerRecord(widget.existing!.id);
      _invalidateOdometerProviders();
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

  /// Refreshes every view derived from odometer readings after a write.
  /// [lastOdometerDateProvider] and [expenseTimelineProvider] recompute via
  /// their watch on the records list.
  void _invalidateOdometerProviders() {
    ref.invalidate(odometerRecordsProvider(widget.vehicleId));
    ref.invalidate(vehicleInfoProvider(widget.vehicleId));
  }
}
