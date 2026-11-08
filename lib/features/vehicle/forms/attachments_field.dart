import 'dart:io';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/files/upload_prep.dart';
import '../../../core/models/attachment.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/error_messages.dart';
import '../../../providers.dart';
import '../attachments/attachment_viewer.dart';

/// A record form's file-attachments editor: pick files, upload them right away
/// via [VehiclesRepository.uploadDocuments], and report the current list up
/// through [onChanged]. Existing attachments (when editing) show as removable
/// chips. Every record type except reminders supports files.
class AttachmentsField extends ConsumerStatefulWidget {
  const AttachmentsField({
    super.key,
    required this.initial,
    required this.enabled,
    required this.onChanged,
  });

  /// Attachments the record already has (empty when adding).
  final List<Attachment> initial;

  /// False while the owning form is submitting.
  final bool enabled;

  /// Called with the full up-to-date list after every add or remove.
  final ValueChanged<List<Attachment>> onChanged;

  @override
  ConsumerState<AttachmentsField> createState() => _AttachmentsFieldState();
}

class _AttachmentsFieldState extends ConsumerState<AttachmentsField> {
  late List<Attachment> _files = [...widget.initial];
  bool _uploading = false;
  String? _error;

  bool get _busy => _uploading || !widget.enabled;

  /// Counts and outcomes only — a file name is the user's (`invoice-anna.pdf`),
  /// and the picker is a platform channel whose failures are invisible from
  /// anywhere else.
  void _log(
    String evt, {
    LogLevel lvl = LogLevel.info,
    Map<String, Object?> fields = const {},
  }) => DiagnosticRecorder.active?.add(
    LogSource.ui,
    evt,
    lvl: lvl,
    fields: fields,
  );

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(allowMultiple: true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = l10n.attachmentUploadError);
      _log(
        'attachment_pick_failed',
        lvl: LogLevel.error,
        fields: {'type': error.runtimeType.toString()},
      );
      return;
    }
    if (result == null) return; // user cancelled

    final picked = [
      for (final f in result.files)
        if (f.path != null) (path: f.path!, name: f.name),
    ];
    // A picker that answers with files the app cannot read (no path — a cloud
    // provider's stream) looks exactly like a cancelled pick from the outside.
    if (picked.isEmpty) {
      _log(
        'attachment_pick_empty',
        lvl: result.files.isEmpty ? LogLevel.info : LogLevel.warn,
        fields: {'n': result.files.length},
      );
      return;
    }
    _log('attachment_pick', fields: {'n': picked.length});

    setState(() => _uploading = true);
    // Measured after downscaling, so a failure reports the bytes that were
    // actually on the wire rather than what came out of the picker. Null while
    // the upload has not got far enough to know.
    int? bytes;
    try {
      final ready = await prepareForUpload(picked);
      bytes = await _totalBytes(ready);
      final uploaded = await ref
          .read(vehiclesRepositoryProvider)
          .uploadDocuments(ready);
      _log('attachment_uploaded', fields: {'n': uploaded.length});
      if (!mounted) return;
      setState(() {
        _files = [..._files, ...uploaded];
        _uploading = false;
      });
      widget.onChanged(_files);
    } on Object catch (error) {
      _log(
        'attachment_upload_failed',
        lvl: LogLevel.error,
        fields: {
          'n': picked.length,
          'bytes': bytes,
          'type': error.runtimeType.toString(),
        },
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = _uploadError(l10n, error, bytes);
      });
    }
  }

  /// Statuses that mean "this file will not go through", as opposed to "the
  /// server hiccuped". 413 is the honest answer; a proxy that drops an oversized
  /// body instead of answering it surfaces as 502 or 504 — issue #15. Retrying
  /// any of the three with the same file cannot succeed, so the message must not
  /// end in "try again".
  static const _rejectedStatuses = {413, 502, 504};

  String _uploadError(AppLocalizations l10n, Object error, int? bytes) {
    if (error is! AppApiException) return l10n.attachmentUploadError;
    final size = bytes == null
        ? null
        : (bytes / (1024 * 1024)).toStringAsFixed(1);
    final status = error.statusCode;
    if (size != null && status != null && _rejectedStatuses.contains(status)) {
      return l10n.attachmentUploadRejected(size, status);
    }
    if (size != null &&
        (error.code == AppErrorCode.serverUnreachable ||
            error.code == AppErrorCode.connectionError)) {
      return l10n.attachmentUploadInterrupted(size);
    }
    return error.localized(l10n);
  }

  Future<int> _totalBytes(List<UploadFile> files) async {
    var total = 0;
    for (final file in files) {
      try {
        total += await File(file.path).length();
      } on IOException {
        continue;
      }
    }
    return total;
  }

  void _remove(Attachment file) {
    setState(() => _files = [..._files]..remove(file));
    _log('attachment_removed', fields: {'n': _files.length});
    widget.onChanged(_files);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    // One surface for the whole field: the add button, the chips and their
    // remove buttons all report as `form.attachments` without a tag each.
    return logSurface(
      'form.attachments',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.attachmentsLabel,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: DashSpace.sm),
            Wrap(
              spacing: DashSpace.sm,
              runSpacing: DashSpace.sm,
              children: [for (final f in _files) _chip(t, f)],
            ),
          ],
          const SizedBox(height: DashSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, size: 18),
              label: Text(l10n.attachmentAddButton),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: DashSpace.sm),
            Text(
              _error!,
              style: TextStyle(
                color: t.dangerInk,
                fontFamily: DashTokens.fontUi,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(DashTokens t, Attachment file) => Container(
    padding: const EdgeInsets.fromLTRB(
      DashSpace.md,
      DashSpace.xs,
      DashSpace.xs,
      DashSpace.xs,
    ),
    decoration: BoxDecoration(
      color: t.subCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: t.subCardBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => openAttachment(context, ref, file),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DashSpace.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 15,
                  color: t.textTertiary,
                ),
                const SizedBox(width: DashSpace.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          icon: const Icon(Icons.close, size: 16),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          color: t.textTertiary,
          onPressed: _busy ? null : () => _remove(file),
        ),
      ],
    ),
  );
}
