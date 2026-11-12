import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/diagnostics/log_form.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Shared chrome for a record add/edit bottom sheet: a title row (with a delete
/// action when editing and a close button), the caller's [fields] inside a
/// [Form], an optional error line, and the cancel / add-or-save buttons. The
/// owning widget keeps the form key, controllers and submit/delete logic; this
/// only lays out the common shell so every record form looks identical.
class RecordFormScaffold extends StatelessWidget {
  const RecordFormScaffold({
    super.key,
    required this.formKey,
    required this.title,
    required this.isEditing,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
    required this.onDelete,
    required this.error,
    required this.fields,
    this.notice,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final bool isEditing;
  final bool submitting;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  /// Invoked by the delete icon; only shown when [isEditing].
  final VoidCallback? onDelete;
  final String? error;

  /// Shown above the fields — for a record the server won't let us write back.
  final Widget? notice;
  final List<Widget> fields;

  /// The shell owns the verdict because it owns the [Form] — every caller
  /// re-validates inside its own handler, which is idempotent, and this way a
  /// refusal is recorded once for all of them instead of once per form that
  /// remembered to.
  void _submit(BuildContext context) {
    if (validateAndLog(context, formKey)) onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only the fields scroll: on a short screen (a landscape tablet)
            // a fully scrolling sheet pushed the buttons below the fold.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DashSpace.xl,
                  DashSpace.xs,
                  DashSpace.xl,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: DashTokens.fontUi,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: t.textPrimary,
                            ),
                          ),
                        ),
                        // The chrome names itself here, once, for every form that
                        // uses this shell — the fields inside stay unnamed and report
                        // as the form's own surface (`form.fuel`, `form.note`, …).
                        if (isEditing && onDelete != null)
                          IconButton(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            icon: Icon(
                              Icons.delete_outline,
                              color: t.dangerInk,
                            ),
                            onPressed: submitting ? null : onDelete,
                          ).tagged('form.delete'),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: submitting ? null : onCancel,
                        ).tagged('form.close'),
                      ],
                    ),
                    const SizedBox(height: DashSpace.sm),
                    if (notice != null) ...[
                      notice!,
                      const SizedBox(height: DashSpace.lg),
                    ],
                    ...fields,
                    if (error != null) ...[
                      const SizedBox(height: DashSpace.md),
                      Text(
                        error!,
                        style: TextStyle(
                          color: t.dangerInk,
                          fontFamily: DashTokens.fontUi,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DashSpace.xl),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : onCancel,
                      child: Text(l10n.actionCancel),
                    ).tagged('form.cancel'),
                  ),
                  const SizedBox(width: DashSpace.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: submitting || onSubmit == null
                          ? null
                          : () => _submit(context),
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? l10n.actionSave : l10n.actionAdd),
                    ).tagged('form.submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
