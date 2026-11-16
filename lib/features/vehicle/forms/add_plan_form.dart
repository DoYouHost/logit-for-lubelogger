import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/extra_field.dart';
import '../../../core/models/plan_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'attachments_field.dart';
import 'extra_fields_field.dart';
import 'form_fields.dart';
import 'record_form_scaffold.dart';

/// Opens the add/edit form for a planner item as a modal bottom sheet. Pass
/// [existing] to edit that item instead (prefilled, with a delete option).
/// Resolves to `true` once an item was added/updated/deleted, or `null` if
/// cancelled.
Future<bool?> showAddPlanForm(
  BuildContext context,
  int vehicleId, {
  PlanRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.plan',
      _AddPlanForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddPlanForm extends ConsumerStatefulWidget {
  const _AddPlanForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final PlanRecord? existing;

  @override
  ConsumerState<_AddPlanForm> createState() => _AddPlanFormState();
}

class _AddPlanFormState extends ConsumerState<_AddPlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();

  late PlanType _type;
  late PlanPriority _priority;
  late PlanProgress _progress;
  List<Attachment> _files = const [];
  List<ExtraField> _extraFields = const [];
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  /// A finished plan can be read and deleted, but not written back: every value
  /// the API accepts would demote it. The whole form goes read-only rather than
  /// letting a save look like it worked.
  bool get _readOnly => widget.existing?.progress == PlanProgress.done;

  bool get _enabled => !_submitting && !_readOnly;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    // Fall back to sensible defaults for add, or when the server reports a value
    // this build doesn't know. Done is kept as-is so the dropdown shows the
    // plan's real state — the form is read-only for it anyway.
    _type = (e != null && e.type != PlanType.unknown)
        ? e.type
        : PlanType.service;
    _priority = (e != null && e.priority != PlanPriority.unknown)
        ? e.priority
        : PlanPriority.normal;
    _progress = switch (e?.progress) {
      null || PlanProgress.unknown => PlanProgress.backlog,
      final stored => stored,
    };
    if (e != null) {
      _description.text = e.description;
      _cost.text = formatFormNumber(e.cost);
      _notes.text = e.notes;
      _files = [...e.files];
      _extraFields = e.extraFields;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formPlanEditTitle : l10n.formPlanTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _readOnly ? null : _submit,
      onDelete: _confirmDelete,
      error: _error,
      notice: _readOnly ? _DoneNotice(message: l10n.planDoneReadOnly) : null,
      fields: [
        TextFormField(
          controller: _description,
          enabled: _enabled,
          decoration: dashFieldDecoration(t, labelText: l10n.colDescription),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        const SizedBox(height: DashSpace.lg),
        dashCombo<PlanType>(
          context,
          id: 'form.plan_type',
          label: Text(l10n.formPlanType),
          initialSelection: _type,
          enabled: _enabled,
          entries: [
            for (final v in PlanType.values)
              if (v != PlanType.unknown)
                DropdownMenuEntry(
                  value: v,
                  label: _typeLabel(v, l10n),
                  labelWidget: logTag(
                    'form.plan_type.option',
                    Text(_typeLabel(v, l10n)),
                  ),
                ),
          ],
          onSelected: (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: DashSpace.lg),
        dashCombo<PlanPriority>(
          context,
          id: 'form.plan_priority',
          label: Text(l10n.formPlanPriority),
          initialSelection: _priority,
          enabled: _enabled,
          entries: [
            for (final v in PlanPriority.values)
              if (v != PlanPriority.unknown)
                DropdownMenuEntry(
                  value: v,
                  label: _priorityLabel(v, l10n),
                  labelWidget: logTag(
                    'form.plan_priority.option',
                    Text(_priorityLabel(v, l10n)),
                  ),
                ),
          ],
          onSelected: (v) => setState(() => _priority = v ?? _priority),
        ),
        const SizedBox(height: DashSpace.lg),
        dashCombo<PlanProgress>(
          context,
          id: 'form.plan_progress',
          label: Text(l10n.formPlanProgress),
          initialSelection: _progress,
          enabled: _enabled,
          entries: [
            for (final v in PlanProgress.values)
              // Done appears only on a plan that already is one, so the field
              // can show its real state; picking it is never an option.
              if (v != PlanProgress.unknown && (v.isWritable || v == _progress))
                DropdownMenuEntry(
                  value: v,
                  enabled: v.isWritable,
                  label: _progressLabel(v, l10n),
                  labelWidget: logTag(
                    'form.plan_progress.option',
                    Text(_progressLabel(v, l10n)),
                  ),
                ),
          ],
          onSelected: (v) => setState(() => _progress = v ?? _progress),
        ),
        const SizedBox(height: DashSpace.lg),
        _CostField(controller: _cost, enabled: _enabled),
        const SizedBox(height: DashSpace.lg),
        TextFormField(
          controller: _notes,
          enabled: _enabled,
          minLines: 2,
          maxLines: 4,
          decoration: dashFieldDecoration(t, labelText: l10n.formNotesOptional),
        ),
        const SizedBox(height: DashSpace.lg),
        ExtraFieldsField(
          recordType: ExtraFieldRecordType.plan,
          initial: _extraFields,
          enabled: _enabled,
          onChanged: (fields) => _extraFields = fields,
        ),
        const SizedBox(height: DashSpace.lg),
        AttachmentsField(
          initial: _files,
          enabled: _enabled,
          onChanged: (files) => _files = files,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_readOnly || !_formKey.currentState!.validate()) return;
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
        await repo.addPlanRecord(
          vehicleId: widget.vehicleId,
          description: _description.text.trim(),
          cost: parseUserDecimal(_cost.text)!,
          type: _type,
          priority: _priority,
          progress: _progress,
          notes: _notes.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      } else {
        await repo.updatePlanRecord(
          id: existing.id,
          description: _description.text.trim(),
          cost: parseUserDecimal(_cost.text)!,
          type: _type,
          priority: _priority,
          progress: _progress,
          notes: _notes.text.trim(),
          files: _files,
          extraFields: _extraFields,
        );
      }
      ref.invalidate(planRecordsProvider(widget.vehicleId));
      ref.invalidate(vehicleInfoProvider(widget.vehicleId));
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
          .deletePlanRecord(widget.existing!.id);
      ref.invalidate(planRecordsProvider(widget.vehicleId));
      ref.invalidate(vehicleInfoProvider(widget.vehicleId));
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

/// Why a finished plan can be read but not saved.
class _DoneNotice extends StatelessWidget {
  const _DoneNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashSpace.md,
        vertical: DashSpace.md,
      ),
      decoration: BoxDecoration(
        color: t.accentOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accentOrange.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: t.accentOrange),
          const SizedBox(width: DashSpace.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: DashTokens.fontUi,
                fontSize: 12.5,
                height: 1.35,
                color: t.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _typeLabel(PlanType v, AppLocalizations l10n) => switch (v) {
  PlanType.service => l10n.catService,
  PlanType.repair => l10n.catRepairs,
  PlanType.upgrade => l10n.catUpgrades,
  PlanType.unknown => l10n.catService,
};

String _priorityLabel(PlanPriority v, AppLocalizations l10n) => switch (v) {
  PlanPriority.critical => l10n.planPriorityCritical,
  PlanPriority.normal => l10n.planPriorityNormal,
  PlanPriority.low => l10n.planPriorityLow,
  PlanPriority.unknown => l10n.planPriorityNormal,
};

String _progressLabel(PlanProgress v, AppLocalizations l10n) => switch (v) {
  PlanProgress.backlog => l10n.planProgressBacklog,
  PlanProgress.inProgress => l10n.planProgressInProgress,
  PlanProgress.testing => l10n.planProgressTesting,
  PlanProgress.done => l10n.planProgressDone,
  PlanProgress.unknown => l10n.planProgressBacklog,
};

/// Required cost field (allows 0) shared shape with the other forms' numeric
/// inputs — monospace, shift-digits entry.
class _CostField extends StatelessWidget {
  const _CostField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: numberKeyboard(decimal: true),
      inputFormatters: decimalInputFormatters,
      style: const TextStyle(fontFamily: DashTokens.fontMono),
      decoration: dashFieldDecoration(t, labelText: l10n.colCost),
      validator: (raw) {
        final value = parseUserDecimal(raw);
        if (value == null) {
          return (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : l10n.validationNumber;
        }
        if (value < 0) return l10n.validationNumber;
        return null;
      },
    );
  }
}
