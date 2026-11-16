import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/supply_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'form_fields.dart';
import 'record_form_scaffold.dart';

/// Opens the add/edit form for a supply / part record as a modal bottom sheet.
/// Pass [existing] to edit that record instead (prefilled, with a delete
/// option). Resolves to `true` once a record was added/updated/deleted, or
/// `null` if cancelled.
Future<bool?> showAddSupplyForm(
  BuildContext context,
  int vehicleId, {
  SupplyRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.supply',
      _AddSupplyForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddSupplyForm extends ConsumerStatefulWidget {
  const _AddSupplyForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final SupplyRecord? existing;

  @override
  ConsumerState<_AddSupplyForm> createState() => _AddSupplyFormState();
}

class _AddSupplyFormState extends ConsumerState<_AddSupplyForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _partNumber = TextEditingController();
  final _partSupplier = TextEditingController();
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();

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
    if (e != null) {
      _description.text = e.description;
      _partNumber.text = e.partNumber;
      _partSupplier.text = e.partSupplier;
      final q = parseUserDecimal(e.partQuantity);
      if (q != null) _quantity.text = formatFormNumber(q);
      _cost.text = formatFormNumber(e.cost);
      _notes.text = e.notes;
      _tags.text = e.tags;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _partNumber.dispose();
    _partSupplier.dispose();
    _quantity.dispose();
    _cost.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(unitsSettingsProvider);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formSupplyEditTitle : l10n.formSupplyTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: _confirmDelete,
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
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _partNumber,
          enabled: !_submitting,
          decoration: dashFieldDecoration(
            t,
            labelText: l10n.formSupplyPartNumber,
          ),
        ),
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _partSupplier,
          enabled: !_submitting,
          decoration: dashFieldDecoration(
            t,
            labelText: l10n.formSupplyPartSupplier,
          ),
        ),
        const SizedBox(height: DashSpace.lg),
        _numberField(controller: _quantity, label: l10n.formSupplyQuantity),
        const SizedBox(height: DashSpace.lg),
        _numberField(controller: _cost, label: l10n.colCost, allowZero: true),
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _notes,
          enabled: !_submitting,
          minLines: 2,
          maxLines: 4,
          decoration: dashFieldDecoration(t, labelText: l10n.formNotesOptional),
        ),
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _tags,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.formTagsOptional),
        ),
        const SizedBox(height: DashSpace.lg),
        ExtraFieldsField(
          recordType: ExtraFieldRecordType.supply,
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
    bool allowZero = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return TextFormField(
      controller: controller,
      enabled: !_submitting,
      keyboardType: numberKeyboard(decimal: true),
      inputFormatters: decimalInputFormatters,
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
    try {
      if (existing == null) {
        await repo.addSupplyRecord(
          vehicleId: widget.vehicleId,
          date: _date,
          description: _description.text.trim(),
          partQuantity: parseUserDecimal(_quantity.text)!,
          cost: parseUserDecimal(_cost.text)!,
          partNumber: _partNumber.text.trim(),
          partSupplier: _partSupplier.text.trim(),
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updateSupplyRecord(
          id: existing.id,
          date: _date,
          description: _description.text.trim(),
          partQuantity: parseUserDecimal(_quantity.text)!,
          cost: parseUserDecimal(_cost.text)!,
          partNumber: _partNumber.text.trim(),
          partSupplier: _partSupplier.text.trim(),
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      }
      ref.invalidate(supplyRecordsProvider(widget.vehicleId));
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
          .deleteSupplyRecord(widget.existing!.id);
      ref.invalidate(supplyRecordsProvider(widget.vehicleId));
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
}
