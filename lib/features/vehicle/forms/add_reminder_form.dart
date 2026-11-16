import 'package:app_util/app_util.dart';
import 'package:material_ui/material_ui.dart';
import '../../common/confirm_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/models/reminder_record.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import 'form_fields.dart';
import 'record_form_scaffold.dart';

/// Metrics a reminder can be measured against (excludes the [unknown] sentinel).
const _selectableMetrics = [
  ReminderMetric.date,
  ReminderMetric.odometer,
  ReminderMetric.both,
];

/// Opens the add/edit form for a reminder as a modal bottom sheet. Pass
/// [existing] to edit that reminder instead (prefilled, with a delete option).
/// Resolves to `true` once a reminder was added/updated/deleted, or `null` if
/// cancelled. Recurring reminders aren't supported — the API's write model has
/// no recurrence fields.
Future<bool?> showAddReminderForm(
  BuildContext context,
  int vehicleId, {
  ReminderRecord? existing,
}) {
  return dashSheet<bool>(
    context,
    builder: (_) => logSurface(
      'form.reminder',
      _AddReminderForm(vehicleId: vehicleId, existing: existing),
    ),
  );
}

class _AddReminderForm extends ConsumerStatefulWidget {
  const _AddReminderForm({required this.vehicleId, this.existing});

  final int vehicleId;
  final ReminderRecord? existing;

  @override
  ConsumerState<_AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends ConsumerState<_AddReminderForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _odometer = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();

  late ReminderMetric _metric;
  late DateTime _dueDate;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;
  bool get _needsDate => _metric != ReminderMetric.odometer;
  bool get _needsOdometer => _metric != ReminderMetric.date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _metric = (e != null && e.metric != ReminderMetric.unknown)
        ? e.metric
        : ReminderMetric.date;
    _dueDate = e?.dueDate ?? DateTime.now();
    if (e != null) {
      _description.text = e.description;
      final o = e.dueOdometer;
      if (o != null) {
        _odometer.text = formatFormNumber(
          ref.read(vehicleUnitsProvider(widget.vehicleId)).toDisplayOdometer(o),
        );
      }
      _notes.text = e.notes;
      _tags.text = e.tags;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _odometer.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final units = ref.watch(vehicleUnitsProvider(widget.vehicleId));

    return RecordFormScaffold(
      formKey: _formKey,
      title: _isEditing ? l10n.formReminderEditTitle : l10n.formReminderTitle,
      isEditing: _isEditing,
      submitting: _submitting,
      onCancel: () => Navigator.pop(context),
      onSubmit: _submit,
      onDelete: _confirmDelete,
      error: _error,
      fields: [
        TextFormField(
          controller: _description,
          enabled: !_submitting,
          decoration: dashFieldDecoration(t, labelText: l10n.colDescription),
          validator: (raw) => (raw == null || raw.trim().isEmpty)
              ? l10n.validationRequired
              : null,
        ),
        const SizedBox(height: DashSpace.lg),
        dashCombo<ReminderMetric>(
          context,
          id: 'form.reminder_metric',
          label: Text(l10n.formReminderMetric),
          initialSelection: _metric,
          enabled: !_submitting,
          entries: [
            for (final m in _selectableMetrics)
              DropdownMenuEntry(
                value: m,
                label: _metricLabel(m, l10n),
                labelWidget: logTag(
                  'form.reminder_metric.option',
                  Text(_metricLabel(m, l10n)),
                ),
              ),
          ],
          onSelected: (m) => setState(() => _metric = m ?? _metric),
        ),
        if (_needsDate) ...[
          const SizedBox(height: DashSpace.lg),
          DateField(
            text: units.formatDate(_dueDate),
            label: l10n.formReminderDueDate,
            onPick: _submitting ? null : _pickDate,
          ),
        ],
        if (_needsOdometer) ...[
          const SizedBox(height: DashSpace.lg),
          TextFormField(
            controller: _odometer,
            enabled: !_submitting,
            keyboardType: numberKeyboard(decimal: false),
            inputFormatters: integerInputFormatters,
            style: const TextStyle(fontFamily: DashTokens.fontMono),
            decoration: dashFieldDecoration(
              t,
              labelText: l10n.formReminderDueOdometer(units.distanceLabel),
            ),
            validator: (raw) {
              // Only enforced while the field is shown (odometer/both metrics).
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
        ],
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
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(
      context,
      initial: _dueDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(_dueDate.year + 10, 12, 31),
    );
    if (picked != null) setState(() => _dueDate = picked);
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
    final dueDate = _needsDate ? _dueDate : null;
    final dueOdometer = _needsOdometer
        ? ref
              .read(vehicleUnitsProvider(widget.vehicleId))
              .toStoredDistance(parseUserDecimal(_odometer.text)!.toDouble())
        : null;
    try {
      if (existing == null) {
        await repo.addReminder(
          vehicleId: widget.vehicleId,
          description: _description.text.trim(),
          metric: _metric,
          dueDate: dueDate,
          dueOdometer: dueOdometer,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
        );
      } else {
        await repo.updateReminder(
          id: existing.id,
          description: _description.text.trim(),
          metric: _metric,
          dueDate: dueDate,
          dueOdometer: dueOdometer,
          notes: _notes.text.trim(),
          tags: _tags.text.trim(),
        );
      }
      ref.invalidate(remindersProvider(widget.vehicleId));
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
          .deleteReminder(widget.existing!.id);
      ref.invalidate(remindersProvider(widget.vehicleId));
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

String _metricLabel(ReminderMetric m, AppLocalizations l10n) => switch (m) {
  ReminderMetric.date => l10n.formReminderMetricDate,
  ReminderMetric.odometer => l10n.formReminderMetricOdometer,
  ReminderMetric.both => l10n.formReminderMetricBoth,
  ReminderMetric.unknown => l10n.formReminderMetricDate,
};
