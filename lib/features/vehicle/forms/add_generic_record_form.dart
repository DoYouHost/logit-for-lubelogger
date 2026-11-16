import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/vehicle_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'form_fields.dart';
import 'record_form_scaffold.dart';

/// Opens the add/edit form for a generic (date + cost) record [kind] — service /
/// repair / upgrade / tax — as a modal bottom sheet. Pass [existing] to edit
/// that record instead (prefilled, with a delete option). Resolves to `true`
/// once a record was added/updated/deleted, or `null` if cancelled.
///
/// No supply picker: the web UI can requisition supplies onto these records, but
/// that's a session-authed MVC feature. The public API's write model
/// (`GenericRecordExportModel`) has no supplies field, so it's not possible over
/// x-api-key for now — may change if LubeLogger adds it to the API.
Future<bool?> showGenericRecordForm(
  BuildContext context,
  int vehicleId,
  RecordKind kind, {
  VehicleRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.${kind.name}',
      _AddGenericRecordForm(
        vehicleId: vehicleId,
        kind: kind,
        existing: existing,
      ),
    ),
  );
}

/// Localized add/edit titles for each generic record [kind].
({String add, String edit}) _titlesFor(
  RecordKind kind,
  AppLocalizations l10n,
) => switch (kind) {
  RecordKind.service => (
    add: l10n.formServiceTitle,
    edit: l10n.formServiceEditTitle,
  ),
  RecordKind.repair => (
    add: l10n.formRepairTitle,
    edit: l10n.formRepairEditTitle,
  ),
  RecordKind.upgrade => (
    add: l10n.formUpgradeTitle,
    edit: l10n.formUpgradeEditTitle,
  ),
  RecordKind.tax => (add: l10n.formTaxTitle, edit: l10n.formTaxEditTitle),
};

class _AddGenericRecordForm extends ConsumerStatefulWidget {
  const _AddGenericRecordForm({
    required this.vehicleId,
    required this.kind,
    this.existing,
  });

  final int vehicleId;
  final RecordKind kind;
  final VehicleRecord? existing;

  @override
  ConsumerState<_AddGenericRecordForm> createState() =>
      _AddGenericRecordFormState();
}

class _AddGenericRecordFormState extends ConsumerState<_AddGenericRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  final _tags = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _date;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;
  bool get _hasOdometer => widget.kind.hasOdometer;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      final o = e.odometer;
      if (o != null) {
        _odometer.text = formatFormNumber(
          ref.read(vehicleUnitsProvider(widget.vehicleId)).toDisplayOdometer(o),
        );
      }
      _description.text = e.description;
      _cost.text = formatFormNumber(e.cost);
      _tags.text = e.tags;
      _notes.text = e.notes;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
  }

  @override
  void dispose() {
    _odometer.dispose();
    _description.dispose();
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
    final titles = _titlesFor(widget.kind, l10n);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? titles.edit : titles.add,
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
        TextFormField(
          controller: _description,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.colDescription),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        if (_hasOdometer) ...[
          const SizedBox(height: DashSpace.lg),
          _numberField(
            controller: _odometer,
            label: l10n.formOdometerLabel(units.distanceLabel),
            decimal: false,
          ),
        ],
        const SizedBox(height: DashSpace.lg),
        _numberField(controller: _cost, label: l10n.colCost, allowZero: true),
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
          recordType: widget.kind.extraFieldType,
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

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool decimal = true,
    bool allowZero = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return TextFormField(
      controller: controller,
      enabled: !_submitting,
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
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(vehiclesRepositoryProvider);
    final existing = widget.existing;
    // Odometer is only collected (and required by the server) for the
    // odometer-bearing kinds; tax sends none.
    final odometer = _hasOdometer
        ? ref
              .read(vehicleUnitsProvider(widget.vehicleId))
              .toStoredDistance(parseUserDecimal(_odometer.text)!.toDouble())
        : null;
    try {
      if (existing == null) {
        await repo.addRecord(
          kind: widget.kind,
          vehicleId: widget.vehicleId,
          date: _date,
          description: _description.text.trim(),
          cost: parseUserDecimal(_cost.text)!,
          odometer: odometer,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updateRecord(
          kind: widget.kind,
          id: existing.id,
          date: _date,
          description: _description.text.trim(),
          cost: parseUserDecimal(_cost.text)!,
          odometer: odometer,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      }
      _invalidateProviders();
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
          .deleteRecord(widget.kind, widget.existing!.id);
      _invalidateProviders();
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

  /// Refreshes every view derived from this record type after a write: its own
  /// tab list and the vehicle's aggregated info (record counts/costs). The
  /// monthly expense breakdown watches the tab list, so it follows.
  void _invalidateProviders() {
    ref.invalidate(
      vehicleRecordsProvider((vehicleId: widget.vehicleId, kind: widget.kind)),
    );
    ref.invalidate(vehicleInfoProvider(widget.vehicleId));
  }
}
