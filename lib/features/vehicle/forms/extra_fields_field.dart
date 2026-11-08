import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/extra_field.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import 'form_fields.dart';

/// A record form's custom-fields editor: renders the household's configured
/// fields for [recordType], prefilled from the record being edited, and reports
/// the filled ones up through [onChanged].
///
/// Only fields with a value are reported — matching the web UI, which drops
/// empty ones instead of storing them. Clearing a field therefore removes it.
class ExtraFieldsField extends ConsumerStatefulWidget {
  const ExtraFieldsField({
    super.key,
    required this.recordType,
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });

  final ExtraFieldRecordType recordType;

  /// The record's stored fields (empty when adding).
  final List<ExtraField> initial;

  final bool enabled;

  /// Called with the fields to persist after every edit, and once the template
  /// resolves.
  final ValueChanged<List<ExtraField>> onChanged;

  @override
  ConsumerState<ExtraFieldsField> createState() => _ExtraFieldsFieldState();
}

class _ExtraFieldsFieldState extends ConsumerState<ExtraFieldsField> {
  /// Every value the user has typed, keyed by field name. Survives a re-merge
  /// when the template arrives after the first build.
  late final Map<String, String> _values = {
    for (final f in widget.initial) f.name: f.value,
  };

  final Map<String, TextEditingController> _controllers = {};

  /// Null until the template resolves — and permanently null on a server that
  /// has no `/api/extrafields`, which [mergeExtraFields] handles.
  List<ExtraField>? _template;

  /// Whether [_report] has run. Needed on top of the template comparison: an
  /// unknown template never differs from the initial null, and the form would
  /// be left holding whatever it was constructed with.
  bool _reported = false;

  /// The server's own date format, which is what the web's datepicker writes
  /// and re-parses; an ISO string would show up there as an unparseable value.
  DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The fields to render: the record's own, carrying anything typed since,
  /// reconciled with the template.
  List<ExtraField> get _fields {
    final stored = [
      for (final f in widget.initial) f.copyWith(value: _values[f.name]),
    ];
    return [
      for (final f in mergeExtraFields(stored, _template))
        f.copyWith(value: _values[f.name]),
    ];
  }

  void _report() => widget.onChanged([
    for (final f in _fields)
      if (f.value.isNotEmpty) f,
  ]);

  /// [rebuild] for the picker fields, which render their value from state; a
  /// text field's controller already holds what the user typed.
  void _set(String name, String value, {bool rebuild = false}) {
    if (rebuild) {
      setState(() => _values[name] = value);
    } else {
      _values[name] = value;
    }
    _report();
  }

  TextEditingController _controllerFor(ExtraField field) => _controllers
      .putIfAbsent(field.name, () => TextEditingController(text: field.value));

  @override
  Widget build(BuildContext context) {
    // Watched, not read at pick time: an unlistened FutureProvider is still
    // loading the first time it's read, which would silently fall back to ISO.
    _dateFormat = _formatOf(ref.watch(serverInfoProvider).value?.dateFormat);
    final template = ref
        .watch(extraFieldTemplateProvider(widget.recordType))
        .value;
    if (!_reported || !identical(template, _template)) {
      _reported = true;
      _template = template;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report();
      });
    }

    final fields = _fields;
    if (fields.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    return logSurface(
      'form.extrafields',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.extraFieldsLabel,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
          for (final field in fields) ...[
            const SizedBox(height: DashSpace.md),
            _input(field, l10n, t),
          ],
        ],
      ),
    );
  }

  Widget _input(ExtraField field, AppLocalizations l10n, DashTokens t) {
    final label = field.isRequired ? '${field.name} *' : field.name;
    return switch (field.fieldType) {
      ExtraFieldType.date => _PickerField(
        key: ValueKey('date:${field.name}'),
        label: label,
        value: field.value,
        icon: Icons.calendar_month,
        enabled: widget.enabled,
        validator: (v) => _requiredError(field, v, l10n),
        onTap: () => _pickDate(field),
      ),
      ExtraFieldType.time => _PickerField(
        key: ValueKey('time:${field.name}'),
        label: label,
        value: field.value,
        icon: Icons.schedule,
        enabled: widget.enabled,
        validator: (v) => _requiredError(field, v, l10n),
        onTap: () => _pickTime(field),
      ),
      ExtraFieldType.number ||
      ExtraFieldType.decimal => _text(field, label, l10n, t, numeric: true),
      // Location is a plain string here: the web's pick-my-position button
      // fills the same field from the browser's geolocation API.
      ExtraFieldType.text ||
      ExtraFieldType.location => _text(field, label, l10n, t),
    };
  }

  Widget _text(
    ExtraField field,
    String label,
    AppLocalizations l10n,
    DashTokens t, {
    bool numeric = false,
  }) {
    final decimal = field.fieldType == ExtraFieldType.decimal;
    return TextFormField(
      controller: _controllerFor(field),
      enabled: widget.enabled,
      keyboardType: numeric ? numberKeyboard(decimal: decimal) : null,
      inputFormatters: !numeric
          ? null
          : decimal
          ? decimalInputFormatters
          : integerInputFormatters,
      style: numeric ? const TextStyle(fontFamily: DashTokens.fontMono) : null,
      decoration: dashFieldDecoration(t, labelText: label),
      validator: (v) => _requiredError(field, v, l10n),
      onChanged: (v) => _set(field.name, v),
    );
  }

  String? _requiredError(
    ExtraField field,
    String? value,
    AppLocalizations l10n,
  ) => field.isRequired && (value == null || value.trim().isEmpty)
      ? l10n.validationRequired
      : null;

  Future<void> _pickDate(ExtraField field) async {
    final picked = await pickDate(
      context,
      initial: _parseDate(field.value, _dateFormat) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 50, 12, 31),
    );
    if (picked != null) {
      _set(field.name, _dateFormat.format(picked), rebuild: true);
    }
  }

  /// `HH:mm`, matching the web's `<input type="time">`.
  Future<void> _pickTime(ExtraField field) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(field.value) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    _set(field.name, '$hh:$mm', rebuild: true);
  }

  static DateFormat _formatOf(String? pattern) {
    if (pattern == null || pattern.isEmpty) return DateFormat('yyyy-MM-dd');
    try {
      return DateFormat(pattern);
    } on Object {
      return DateFormat('yyyy-MM-dd');
    }
  }

  static DateTime? _parseDate(String raw, DateFormat format) {
    if (raw.trim().isEmpty) return null;
    try {
      return format.parseLoose(raw);
    } on Object {
      return DateTime.tryParse(raw);
    }
  }

  static TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

/// A read-only field opened by tapping it, for the date and time kinds. Wrapped
/// in a [FormField] so a required-but-empty one fails the enclosing form.
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.validator,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        // The picker writes straight to the owning state, so this pulls the
        // FormField's own value back in step — validation must see what was
        // picked, not what the field was built with.
        if (state.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.mounted) state.didChange(value);
          });
        }
        return InkWell(
          onTap: enabled ? onTap : null,
          child: InputDecorator(
            decoration: dashFieldDecoration(
              t,
              labelText: label,
            ).copyWith(errorText: state.errorText),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? '—' : value,
                    style: TextStyle(
                      fontFamily: DashTokens.fontMono,
                      fontSize: 13.5,
                      color: value.isEmpty ? t.textTertiary : t.textPrimary,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: t.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }
}
