import 'package:material_ui/material_ui.dart';

import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';

/// The app's destructive confirmation, in this app's words: `dash_kit`'s dialog
/// with the title, message and labels every delete here would otherwise repeat.
///
/// [what] names the thing being deleted for the log (`record`, `vehicle`) and
/// becomes the dialog's id; the title and message are user-facing text and
/// never go in.
Future<bool> confirmDelete(
  BuildContext context, {
  required String what,
  String? title,
  String? message,
  String? confirmLabel,
}) {
  final l10n = AppLocalizations.of(context);
  return confirmDialog(
    context,
    id: 'confirm.$what',
    title: title ?? l10n.confirmDeleteTitle,
    message: message ?? l10n.confirmDeleteMessage,
    confirmLabel: confirmLabel ?? l10n.actionDelete,
    cancelLabel: l10n.actionCancel,
    destructive: true,
  );
}

/// The same dialog for something questionable rather than destructive — an
/// odometer reading below the previous one. Nothing is lost either way, so the
/// confirm is not painted as a danger.
Future<bool> confirmRisky(
  BuildContext context, {
  required String what,
  required String title,
  required String message,
  required String confirmLabel,
}) {
  final l10n = AppLocalizations.of(context);
  return confirmDialog(
    context,
    id: 'confirm.$what',
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: l10n.actionCancel,
  );
}
