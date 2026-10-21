import '../models/reminder_record.dart';

/// A past-due reminder eligible for a system notification, flattened across
/// vehicles. Pure data — no plugin dependency — so the decision logic below is
/// unit-testable without Flutter bindings.
class ReminderAlert {
  const ReminderAlert({
    required this.vehicleId,
    required this.vehicleName,
    required this.reminderId,
    required this.description,
    required this.dueKey,
  });

  final int vehicleId;
  final String vehicleName;
  final int reminderId;
  final String description;

  /// Stable identity of THIS due-cycle (see [reminderDueKey]).
  final String dueKey;

  /// A stable, non-negative 32-bit id for the OS notification, derived from
  /// [dueKey] so re-showing the same due-cycle reuses (updates) one notification.
  int get notificationId => dueKey.hashCode & 0x7fffffff;
}

/// Identity of a reminder's current due-cycle. The due target (date/odometer) is
/// part of the key on purpose: a LubeLogger reminder recurs by rolling its due
/// target forward while keeping the same `id`, so keying on `id` alone would
/// suppress every future cycle forever. When the target changes, the key
/// changes and the reminder can alert again. See docs/api-server.md and
/// docs/api-records.md.
String reminderDueKey({
  required int vehicleId,
  required int reminderId,
  DateTime? dueDate,
  double? dueOdometer,
}) =>
    'v$vehicleId:r$reminderId:'
    '${dueDate?.toIso8601String() ?? ''}:'
    '${dueOdometer?.round() ?? ''}';

/// Build a [ReminderAlert] for [vehicle] from a raw [record], or null when the
/// record isn't past due (the only urgency we notify on).
ReminderAlert? reminderAlertFor(
  int vehicleId,
  String vehicleName,
  ReminderRecord record,
) {
  if (record.urgency != ReminderUrgency.pastDue) return null;
  return ReminderAlert(
    vehicleId: vehicleId,
    vehicleName: vehicleName,
    reminderId: record.id,
    description: record.description,
    dueKey: reminderDueKey(
      vehicleId: vehicleId,
      reminderId: record.id,
      dueDate: record.dueDate,
      dueOdometer: record.dueOdometer,
    ),
  );
}

/// The outcome of a reminder check: what to post now, and the set to persist as
/// "already notified" for the next run.
class ReminderNotifyPlan {
  const ReminderNotifyPlan({
    required this.toNotify,
    required this.nextNotified,
  });

  /// Alerts that became past due since the last check — the ones to post now.
  final List<ReminderAlert> toNotify;

  /// The keys to persist for the next run: exactly the currently past-due keys.
  /// Persisting the current set (not the union with history) is what makes this
  /// self-pruning — a reminder that leaves past-due (serviced/recurred) drops
  /// out, so if it later returns it notifies again; one that stays past-due
  /// remains in the set and is not re-notified.
  final Set<String> nextNotified;
}

/// Decide which past-due reminders warrant a notification this run.
///
/// Given every currently past-due [pastDue] alert and the [alreadyNotified] keys
/// from the previous run, notify only keys not seen before, and return the
/// current key set to persist. Duplicate keys within one run are collapsed so a
/// key is never posted twice.
ReminderNotifyPlan planReminderNotifications(
  List<ReminderAlert> pastDue,
  Set<String> alreadyNotified,
) {
  final current = <String>{};
  final seen = <String>{};
  final toNotify = <ReminderAlert>[];
  for (final alert in pastDue) {
    current.add(alert.dueKey);
    if (alreadyNotified.contains(alert.dueKey)) continue;
    if (!seen.add(alert.dueKey)) continue; // collapse duplicates this run
    toNotify.add(alert);
  }
  return ReminderNotifyPlan(toNotify: toNotify, nextNotified: current);
}
