import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/equipment_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'record_form_scaffold.dart';

/// Opens the add/edit form for an equipment item as a modal bottom sheet. Pass
/// [existing] to edit that item instead (prefilled, with a delete option).
/// Resolves to `true` once an item was added/updated/deleted, or `null` if
/// cancelled.
Future<bool?> showAddEquipmentForm(
  BuildContext context,
  int vehicleId, {
  EquipmentRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.equipment',
      _AddEquipmentForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddEquipmentForm extends ConsumerStatefulWidget {
  const _AddEquipmentForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final EquipmentRecord? existing;

  @override
  ConsumerState<_AddEquipmentForm> createState() => _AddEquipmentFormState();
}

class _AddEquipmentFormState extends ConsumerState<_AddEquipmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();

  late bool _isEquipped;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _isEquipped = e?.isEquipped ?? true;
    if (e != null) {
      _name.text = e.description;
      _notes.text = e.notes;
      _tags.text = e.tags;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formEquipmentEditTitle : l10n.formEquipmentTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: _confirmDelete,
      error: _error,
      fields: [
        TextFormField(
          controller: _name,
          enabled: !_submitting,
          decoration: dashFieldDecoration(
            t,
            labelText: l10n.formEquipmentNameLabel,
          ),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        const SizedBox(height: DashSpace.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.formEquipmentEquipped),
          value: _isEquipped,
          onChanged: _submitting
              ? null
              : (v) => setState(() => _isEquipped = v),
        ),
        const SizedBox(height: DashSpace.sm),
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
          recordType: ExtraFieldRecordType.equipment,
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
        await repo.addEquipmentRecord(
          vehicleId: widget.vehicleId,
          description: _name.text.trim(),
          isEquipped: _isEquipped,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updateEquipmentRecord(
          id: existing.id,
          description: _name.text.trim(),
          isEquipped: _isEquipped,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      }
      ref.invalidate(equipmentRecordsProvider(widget.vehicleId));
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
          .deleteEquipmentRecord(widget.existing!.id);
      ref.invalidate(equipmentRecordsProvider(widget.vehicleId));
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
