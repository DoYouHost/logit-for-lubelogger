import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import 'pending_write_label.dart';

Future<void> showSyncSheet(BuildContext context) =>
    dashSheet<void>(context, builder: (_) => const _SyncSheet());

/// App-bar entry to the sync sheet, shown only when there is something to say:
/// writes still on the phone, writes the server refused, or a server that has
/// stopped answering.
///
/// It has to be somewhere the user passes anyway. A save that could not be
/// delivered still closed its form and still looks saved, and the record it
/// made will not be in any list until it lands — so the count is the only thing
/// standing between that and entering it twice.
class SyncStatusAction extends ConsumerWidget {
  const SyncStatusAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final sync = ref.watch(syncStateProvider);
    if (!sync.hasWork && !sync.offline) return const SizedBox.shrink();

    final pending = sync.pending.length;
    final refused = sync.rejected.isNotEmpty;
    // The count sits on the fill and the icon on the app bar, so each takes the
    // colour that reads where it is.
    final fill = refused ? t.dangerInk : t.accentGold;
    final label = refused ? t.onDanger : t.onAccent;
    final ink = refused
        ? t.dangerInk
        : (pending > 0 ? t.accentGoldInk : t.textTertiary);

    return IconButton(
      tooltip: pending > 0 ? l10n.syncPendingTooltip : l10n.syncOfflineTooltip,
      onPressed: () => showSyncSheet(context),
      icon: Badge(
        isLabelVisible: pending > 0,
        label: Text('$pending'),
        backgroundColor: fill,
        textColor: label,
        child: Icon(
          pending > 0 || refused
              ? Icons.cloud_upload_outlined
              : Icons.cloud_off_outlined,
          color: ink,
        ),
      ),
    ).tagged('sync.open');
  }
}

class _SyncSheet extends ConsumerWidget {
  const _SyncSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final sync = ref.watch(syncStateProvider);

    return logSurface(
      'sync',
      SafeArea(
        top: false,
        left: false,
        right: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DashSpace.xl,
            DashSpace.xs,
            DashSpace.xl,
            DashSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.syncTitle,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: DashSpace.sm),
              Text(
                sync.offline || sync.lastContact == null
                    ? l10n.syncOffline
                    : l10n.syncLastContact(_when(context, sync.lastContact!)),
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 13,
                  color: sync.offline ? t.dangerInk : t.textTertiary,
                ),
              ),
              const SizedBox(height: DashSpace.lg),
              if (sync.pending.isEmpty)
                Text(
                  l10n.syncNothingPending,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 14,
                    color: t.textSecondary,
                  ),
                )
              else ...[
                Text(
                  l10n.syncPendingCount(sync.pending.length),
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: DashSpace.sm),
                for (final write in sync.pending)
                  _WriteRow(
                    title: describePendingWrite(write, l10n),
                    subtitle: write.attempts == 0
                        ? null
                        : l10n.syncAttempts(write.attempts),
                    icon: Icons.schedule,
                    tint: t.accentGold,
                  ),
                const SizedBox(height: DashSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: sync.syncing ? null : () => _send(context, ref),
                    icon: sync.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      sync.syncing ? l10n.syncSending : l10n.syncSendNow,
                    ),
                  ).tagged('sync.send'),
                ),
              ],
              if (sync.rejected.isNotEmpty) ...[
                const SizedBox(height: DashSpace.xl),
                Text(
                  l10n.syncRejectedTitle,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.dangerInk,
                  ),
                ),
                const SizedBox(height: DashSpace.xs),
                Text(
                  l10n.syncRejectedExplain,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 12.5,
                    height: 1.35,
                    color: t.textTertiary,
                  ),
                ),
                const SizedBox(height: DashSpace.sm),
                for (final write in sync.rejected)
                  _WriteRow(
                    title: describePendingWrite(write, l10n),
                    subtitle: write.lastError,
                    icon: Icons.error_outline,
                    tint: t.dangerInk,
                    onDiscard: () => ref
                        .read(syncStateProvider.notifier)
                        .discardRejected(write.id),
                  ),
                const SizedBox(height: DashSpace.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        ref.read(syncStateProvider.notifier).discardRejected(),
                    child: Text(l10n.syncDiscardAll),
                  ).tagged('sync.discardAll'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref.read(syncStateProvider.notifier).syncNow();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome.stopped
              ? l10n.syncStillOffline
              : l10n.syncSentResult(outcome.delivered),
        ),
      ),
    );
  }

  /// Time of day for today, a date for anything older — "14:32" answers "is
  /// this current?" and a bare time three days stale would not.
  static String _when(BuildContext context, DateTime moment) {
    final material = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final sameDay =
        moment.year == now.year &&
        moment.month == now.month &&
        moment.day == now.day;
    return sameDay
        ? material.formatTimeOfDay(TimeOfDay.fromDateTime(moment))
        : material.formatMediumDate(moment);
  }
}

class _WriteRow extends StatelessWidget {
  const _WriteRow({
    required this.title,
    required this.icon,
    required this.tint,
    this.subtitle,
    this.onDiscard,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DashSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: DashSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: DashTokens.fontUi,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: DashTokens.fontUi,
                      fontSize: 12,
                      color: t.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (onDiscard != null)
            TextButton(onPressed: onDiscard, child: Text(l10n.syncDiscard)),
        ],
      ),
    );
  }
}
