import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/note_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'record_form_scaffold.dart';

/// Opens the add/edit form for a free-text note as a modal bottom sheet. Pass
/// [existing] to edit that note instead (prefilled, with a delete option).
/// Resolves to `true` once a note was added/updated/deleted, or `null` if
/// cancelled.
Future<bool?> showAddNoteForm(
  BuildContext context,
  int vehicleId, {
  NoteRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.note',
      _AddNoteForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddNoteForm extends ConsumerStatefulWidget {
  const _AddNoteForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final NoteRecord? existing;

  @override
  ConsumerState<_AddNoteForm> createState() => _AddNoteFormState();
}

class _AddNoteFormState extends ConsumerState<_AddNoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tags = TextEditingController();

  late bool _pinned;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _pinned = e?.pinned ?? false;
    if (e != null) {
      _title.text = e.description;
      _body.text = e.noteText;
      _tags.text = e.tags;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formNoteEditTitle : l10n.formNoteTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: _confirmDelete,
      error: _error,
      fields: [
        TextFormField(
          controller: _title,
          enabled: !_submitting,
          decoration: dashFieldDecoration(
            t,
            labelText: l10n.formNoteTitleLabel,
          ),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _body,
          enabled: !_submitting,
          minLines: 3,
          maxLines: 6,
          decoration: dashFieldDecoration(t, labelText: l10n.formNoteBodyLabel),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        const SizedBox(height: DashSpace.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.formNotePinned),
          value: _pinned,
          onChanged: _submitting ? null : (v) => setState(() => _pinned = v),
        ),
        const SizedBox(height: DashSpace.sm),
        TextFormField(
          controller: _tags,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.formTagsOptional),
        ),
        const SizedBox(height: DashSpace.lg),
        ExtraFieldsField(
          recordType: ExtraFieldRecordType.note,
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
        await repo.addNote(
          vehicleId: widget.vehicleId,
          description: _title.text.trim(),
          noteText: _body.text.trim(),
          pinned: _pinned,
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updateNote(
          id: existing.id,
          description: _title.text.trim(),
          noteText: _body.text.trim(),
          pinned: _pinned,
          tags: _tags.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      }
      ref.invalidate(notesProvider(widget.vehicleId));
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
          .deleteNote(widget.existing!.id);
      ref.invalidate(notesProvider(widget.vehicleId));
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
