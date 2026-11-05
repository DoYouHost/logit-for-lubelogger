import 'dart:async';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/api/server_capabilities.dart';
import 'core/app_localizations_loader.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/whoami.dart';
import 'core/auth/credentials_store.dart';
import 'core/cache/http_cache.dart';
import 'core/cache/offline_interceptor.dart';
import 'core/cache/photo_cache.dart';
import 'core/cache/sync_service.dart';
import 'core/cache/write_queue.dart';
import 'core/diagnostics/diagnostics_wiring.dart';
import 'core/diagnostics/report_config.dart';
import 'core/diagnostics/session_facts.dart';
import 'core/format/chart_range.dart';
import 'core/format/expense_timeline.dart';
import 'core/format/gas_stats.dart';
import 'core/format/vehicle_units.dart';
import 'core/models/dated_cost.dart';
import 'core/models/equipment_record.dart';
import 'core/models/extra_field.dart';
import 'core/models/gas_record.dart';
import 'core/models/note_record.dart';
import 'core/models/odometer_record.dart';
import 'core/models/plan_record.dart';
import 'core/models/reminder_record.dart';
import 'core/models/server_info.dart';
import 'core/models/server_version.dart';
import 'core/models/supply_record.dart';
import 'core/models/vehicle_info.dart';
import 'core/models/vehicle_record.dart';
import 'core/models/vehicle_tab.dart';
import 'core/notifications/notification_service.dart';
import 'core/background/background_worker.dart';
import 'core/quick_actions_service.dart';
import 'core/settings/server_profile.dart';
import 'core/settings/settings_repository.dart';
import 'core/settings/units_settings.dart';
import 'data/vehicles_repository.dart';

/// Overridden in main() after `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

final credentialsStoreProvider = Provider<CredentialsStore>(
  (ref) => SecureCredentialsStore(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Display-unit preferences (currency symbol, distance, fuel economy). Persisted
/// locally; independent of the server's own locale.
final unitsSettingsProvider =
    NotifierProvider<UnitsSettingsNotifier, UnitsSettings>(
      UnitsSettingsNotifier.new,
    );

class UnitsSettingsNotifier extends Notifier<UnitsSettings> {
  @override
  UnitsSettings build() => ref.watch(settingsRepositoryProvider).loadUnits();

  Future<void> _save(UnitsSettings units) async {
    await ref.read(settingsRepositoryProvider).saveUnits(units);
    state = units;
  }

  Future<void> setBase(MeasurementSystem base) =>
      _save(state.copyWith(base: base));

  Future<void> setCurrency(CurrencyOption currency) =>
      _save(state.copyWith(currency: currency));

  Future<void> setDistance(DistanceUnit distance) =>
      _save(state.copyWith(distance: distance));

  Future<void> setEconomy(FuelEconomyUnit economy) =>
      _save(state.copyWith(economy: economy));

  Future<void> setDateOrder(DateOrder dateOrder) =>
      _save(state.copyWith(dateOrder: dateOrder));

  Future<void> setDateSeparator(DateSeparator dateSeparator) =>
      _save(state.copyWith(dateSeparator: dateSeparator));
}

/// Which record tabs are visible on the vehicle screen (and offered by the FAB
/// add sheet). Persisted locally; defaults to all tabs. Iterate
/// [VehicleTab.values] and filter by membership to keep a stable tab order.
final visibleTabsProvider =
    NotifierProvider<VisibleTabsNotifier, Set<VehicleTab>>(
      VisibleTabsNotifier.new,
    );

class VisibleTabsNotifier extends Notifier<Set<VehicleTab>> {
  @override
  Set<VehicleTab> build() =>
      ref.watch(settingsRepositoryProvider).loadVisibleTabs();

  /// Show or hide a single tab, persisting the new set.
  Future<void> setVisible(VehicleTab tab, bool visible) async {
    final next = {...state};
    if (visible) {
      next.add(tab);
    } else {
      next.remove(tab);
    }
    await ref.read(settingsRepositoryProvider).saveVisibleTabs(next);
    state = next;
  }
}

/// The range every dashboard chart opens on, from Settings.
final chartDefaultRangeProvider =
    NotifierProvider<ChartDefaultRangeNotifier, ChartRangePreset>(
      ChartDefaultRangeNotifier.new,
    );

class ChartDefaultRangeNotifier extends Notifier<ChartRangePreset> {
  @override
  ChartRangePreset build() =>
      ref.watch(settingsRepositoryProvider).loadChartDefaultRange();

  Future<void> set(ChartRangePreset preset) async {
    await ref.read(settingsRepositoryProvider).saveChartDefaultRange(preset);
    state = preset;
  }
}

/// The dashboard charts whose range can be switched.
enum DashboardChart { expensesByType, expensesDistance, economy }

/// One chart on one vehicle's dashboard. Per vehicle because a custom range
/// fitted to one vehicle's history is usually empty on another.
typedef ChartKey = ({int vehicleId, DashboardChart chart});

/// Ranges picked on individual charts. Kept for the app's lifetime only, and
/// dropped when the default changes: a new default the charts didn't follow
/// would look like the setting did nothing.
final chartRangeOverridesProvider =
    NotifierProvider<ChartRangeOverridesNotifier, Map<ChartKey, ChartRange>>(
      ChartRangeOverridesNotifier.new,
    );

class ChartRangeOverridesNotifier extends Notifier<Map<ChartKey, ChartRange>> {
  @override
  Map<ChartKey, ChartRange> build() {
    ref.watch(chartDefaultRangeProvider);
    return const {};
  }

  /// Shows [key] over [range]; the default preset clears the override.
  void set(ChartKey key, ChartRange range) {
    final followsDefault =
        range == PresetRange(ref.read(chartDefaultRangeProvider));
    state = {
      for (final e in state.entries)
        if (e.key != key) e.key: e.value,
      if (!followsDefault) key: range,
    };
  }
}

/// The range a chart is currently shown over.
final chartRangeProvider = Provider.family<ChartRange, ChartKey>(
  (ref, key) =>
      ref.watch(chartRangeOverridesProvider)[key] ??
      PresetRange(ref.watch(chartDefaultRangeProvider)),
);

/// The order record tabs appear in — on the vehicle screen (after the always-
/// first Dashboard) and in the FAB add sheet. A full permutation of
/// [VehicleTab.values]; visibility is tracked separately by
/// [visibleTabsProvider]. Persisted locally; defaults to enum order.
final tabOrderProvider = NotifierProvider<TabOrderNotifier, List<VehicleTab>>(
  TabOrderNotifier.new,
);

class TabOrderNotifier extends Notifier<List<VehicleTab>> {
  @override
  List<VehicleTab> build() =>
      ref.watch(settingsRepositoryProvider).loadTabOrder();

  /// Move the tab at [oldIndex] to [newIndex], persisting the new order. Indices
  /// use `ReorderableListView.onReorderItem` semantics: [newIndex] is already
  /// adjusted for the removal, so it's the final insertion slot in the list
  /// after the dragged item is taken out.
  Future<void> move(int oldIndex, int newIndex) async {
    final next = [...state];
    next.insert(newIndex, next.removeAt(oldIndex));
    await ref.read(settingsRepositoryProvider).saveTabOrder(next);
    state = next;
  }
}

/// The currency symbol to display: the user's forced choice, or the server's
/// symbol when set to [CurrencyOption.auto].
final currencySymbolProvider = Provider<String>((ref) {
  final forced = ref.watch(unitsSettingsProvider).currency.fixedSymbol;
  if (forced != null) return forced;
  return ref.watch(serverInfoProvider).valueOrNull?.currencySymbol ?? r'$';
});

/// Bare Dio (no auth) used for the login probe.
final bareDioProvider = Provider<Dio>((ref) => createBareDio());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    bareDio: ref.watch(bareDioProvider),
    credentials: ref.watch(credentialsStoreProvider),
  ),
);

/// Active server profile; `null` = unconfigured (router → /setup).
final serverProfileProvider =
    NotifierProvider<ServerProfileNotifier, ServerProfile?>(
      ServerProfileNotifier.new,
    );

class ServerProfileNotifier extends Notifier<ServerProfile?> {
  @override
  ServerProfile? build() => ref.watch(settingsRepositoryProvider).loadProfile();

  Future<void> save(ServerProfile profile) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.saveProfile(profile);
    state = profile;
    // Arm the background pass for the new session. Unconditional: even with
    // reminders and background refresh both off, it is what delivers a write
    // the server wasn't there to take.
    await registerBackgroundWorker();
    // Publish the launcher add-record shortcuts for the new session.
    final l10n = await loadAppLocalizations();
    await quickActionsService.setRecordShortcuts(
      fuelLabel: l10n.quickActionAddFuel,
      odometerLabel: l10n.quickActionAddOdometer,
    );
  }

  /// "Log out / change server": clear the profile and every stored secret, drop
  /// the offline copies and anything queued for the old server, stop the
  /// background pass, and remove the launcher shortcuts (none of them can work
  /// without credentials).
  Future<void> clear() async {
    // Before the profile goes: the cache is keyed by the server it came from.
    // Not via apiClientProvider — it watches this notifier, so reading it here
    // is a CircularDependencyError.
    final profile = state;
    if (profile != null) await HttpCache(baseUrl: profile.baseUrl).clear();
    await ref.read(writeQueueProvider).clear();
    await ref.read(settingsRepositoryProvider).clearProfile();
    await ref.read(credentialsStoreProvider).clearAll();
    await cancelBackgroundWorker();
    await quickActionsService.clear();
    state = null;
  }
}

/// Whether past-due reminder notifications are enabled. Turning it on requests
/// the Android 13+ notification permission and schedules the background check;
/// turning it off cancels it. Persisted via [SettingsRepository].
final reminderNotificationsProvider =
    NotifierProvider<ReminderNotificationsNotifier, bool>(
      ReminderNotificationsNotifier.new,
    );

class ReminderNotificationsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).loadRemindersEnabled();

  /// Turn reminder notifications on or off. Returns false when enabling was
  /// blocked by a denied notification permission (state stays off).
  Future<bool> setEnabled(bool enabled) async {
    final settings = ref.read(settingsRepositoryProvider);
    if (enabled) {
      final granted = await NotificationService().requestPermission();
      // "The app never notifies me" starts here as often as it starts in the
      // worker: a permission the system refused leaves the feature switched
      // off, and nothing else in the log would say why.
      DiagnosticRecorder.active?.add(
        LogSource.notif,
        'permission',
        lvl: granted ? LogLevel.info : LogLevel.warn,
        fields: {'reason': granted ? 'granted' : 'denied'},
      );
      if (!granted) return false;
      await settings.saveRemindersEnabled(true);
      state = true;
      // The pass is already scheduled while signed in; this only makes sure of
      // it for a session that predates the background layer.
      await registerBackgroundWorker();
      return true;
    }
    await settings.saveRemindersEnabled(false);
    state = false;
    return true;
  }
}

/// Whether the background pass may refresh stored data. Independent of the
/// reminder switch: the pass runs while signed in either way, and this only
/// says whether it also re-reads the lists.
final backgroundRefreshProvider =
    NotifierProvider<BackgroundRefreshNotifier, bool>(
      BackgroundRefreshNotifier.new,
    );

class BackgroundRefreshNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(settingsRepositoryProvider).loadBackgroundRefreshEnabled();

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(settingsRepositoryProvider)
        .saveBackgroundRefreshEnabled(enabled);
    state = enabled;
  }
}

/// Bytes the offline copy occupies, for the Settings row that offers to drop it.
final cacheSizeProvider = FutureProvider<int>(
  (ref) => ref.watch(apiClientProvider).cache.sizeInBytes(),
);

/// Most recently built client. Survives the transient frame between "change
/// server" clearing the profile and the router redirecting to /setup, when
/// repository providers that `watch` this may momentarily rebuild with a null
/// profile. Never used for a real request in that window — its consumers are
/// about to unmount. Safe to cache: [ApiClient] holds no disposable resources.
ApiClient? _lastApiClient;

/// API client for the active profile. Routes without a profile redirect to
/// /setup, so the UI should never read this while the profile is null.
final apiClientProvider = Provider<ApiClient>((ref) {
  final profile = ref.watch(serverProfileProvider);
  if (profile == null) {
    final cached = _lastApiClient;
    if (cached != null) {
      assert(() {
        debugPrint('apiClientProvider: reusing last client (profile is null)');
        return true;
      }());
      return cached;
    }
    throw StateError('apiClientProvider used without a server profile');
  }
  return _lastApiClient = ApiClient(
    profile: profile,
    credentials: ref.watch(credentialsStoreProvider),
    queue: ref.watch(writeQueueProvider),
    status: ref.watch(offlineStatusProvider),
  );
});

/// Writes the server hasn't taken yet. Held outside [apiClientProvider] so a
/// client rebuilt on a profile change doesn't drop what is waiting.
final writeQueueProvider = Provider<WriteQueue>((ref) {
  final queue = WriteQueue(ref.watch(sharedPreferencesProvider));
  ref.onDispose(queue.dispose);
  return queue;
});

/// Whether the server is answering. Outlives the client for the same reason.
final offlineStatusProvider = Provider<OfflineStatus>((ref) {
  final status = OfflineStatus();
  ref.onDispose(status.dispose);
  return status;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final profile = ref.watch(serverProfileProvider);
  return SyncService(
    dio: ref.watch(apiClientProvider).dio,
    queue: ref.watch(writeQueueProvider),
    repository: ref.watch(vehiclesRepositoryProvider),
    photos: profile == null || profile.isDemo
        ? null
        : PhotoCache(
            baseUrl: profile.baseUrl,
            apiKey: ref.watch(apiKeyProvider).valueOrNull,
          ),
  );
});

/// What the offline layer is holding, and whether the server is answering.
class SyncState {
  const SyncState({
    this.pending = const [],
    this.rejected = const [],
    this.offline = false,
    this.syncing = false,
    this.lastContact,
  });

  /// Writes waiting for a server that wasn't there.
  final List<PendingWrite> pending;

  /// Writes the server refused. They will not be retried; the user reads why
  /// and dismisses them.
  final List<PendingWrite> rejected;

  final bool offline;
  final bool syncing;

  /// When the server last answered anything.
  final DateTime? lastContact;

  bool get hasWork => pending.isNotEmpty || rejected.isNotEmpty;
}

final syncStateProvider = NotifierProvider<SyncStateNotifier, SyncState>(
  SyncStateNotifier.new,
);

class SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final queue = ref.watch(writeQueueProvider);
    final status = ref.watch(offlineStatusProvider);
    queue.addListener(_onChanged);
    status.addListener(_onChanged);
    ref.onDispose(() {
      queue.removeListener(_onChanged);
      status.removeListener(_onChanged);
    });
    return _snapshot();
  }

  void _onChanged() => state = _snapshot(syncing: state.syncing);

  SyncState _snapshot({bool syncing = false}) {
    final queue = ref.read(writeQueueProvider);
    final status = ref.read(offlineStatusProvider);
    return SyncState(
      pending: queue.pending,
      rejected: queue.rejected,
      offline: status.offline,
      lastContact: status.lastContact,
      syncing: syncing,
    );
  }

  /// Re-reads the queue from disk — the background isolate may have drained
  /// part of it while the app was away.
  Future<void> reload() => ref.read(writeQueueProvider).reload();

  /// Delivers what is waiting, then re-reads every list: the server now holds
  /// records none of the screens know about. The stored copies stay — the
  /// interceptor already knows they predate the write, so they will be
  /// refreshed rather than trusted, and they are still what a sudden loss of
  /// signal would leave the user with.
  Future<SyncOutcome> syncNow() async {
    if (state.syncing) {
      return (delivered: 0, refused: 0, remaining: 0, stopped: false);
    }
    state = _snapshot(syncing: true);
    try {
      await ref.read(writeQueueProvider).reload();
      final outcome = await ref.read(syncServiceProvider).drain();
      if (outcome.delivered > 0) invalidateAllData(ref.invalidate);
      return outcome;
    } finally {
      state = _snapshot();
    }
  }

  Future<void> discardRejected([String? id]) =>
      ref.read(writeQueueProvider).discardRejected(id);
}

/// Drops every stored read, wholesale — `invalidate` on a family clears all of
/// its instances. For when the server's contents changed under all of them at
/// once (a drained queue) rather than one vehicle's worth.
void invalidateAllData(Invalidate invalidate) {
  invalidate(garageProvider);
  invalidate(vehicleInfoProvider);
  invalidate(gasRecordsProvider);
  invalidate(odometerRecordsProvider);
  invalidate(vehicleRecordsProvider);
  invalidate(supplyRecordsProvider);
  invalidate(planRecordsProvider);
  invalidate(remindersProvider);
  invalidate(notesProvider);
  invalidate(equipmentRecordsProvider);
}

/// The active API key, for authenticating image requests (`Image.network`
/// headers). Read once per profile.
final apiKeyProvider = FutureProvider<String?>(
  (ref) => ref.watch(credentialsStoreProvider).readApiKey(),
);

/// App name/version/build number, for the Settings "About" section.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Describes the session for a report: app and server version, the device, the
/// display settings.
///
/// A provider rather than a closure inside the recorder, because a change or
/// feature request needs the same versions and has no recording to read them
/// off — and two copies of this argument list would be two places for the
/// server version to be fetched differently.
final sessionFactsProvider = Provider<Future<SessionFacts> Function()>(
  (ref) =>
      () => loadSessionFacts(
        profile: ref.read(serverProfileProvider),
        credentials: ref.read(credentialsStoreProvider),
        // Read through the repository only when a profile exists: without one
        // [apiClientProvider] throws by design, and a recording started from the
        // setup screen has no server to ask anyway.
        readServerVersion: ref.read(serverProfileProvider) == null
            ? null
            : () async =>
                  (await ref.read(vehiclesRepositoryProvider).serverVersion())
                      .currentVersion,
      ),
);

/// Bug-report log recorder. Holding it in a provider keeps one instance per
/// app, which matters: [DiagnosticRecorder.active] is process-wide state and
/// two recorders would fight over it.
final diagnosticRecorderProvider = Provider<DiagnosticRecorder>(
  (ref) => lubeloggerRecorder(
    settings: ref.watch(settingsRepositoryProvider),
    loadFacts: ref.watch(sessionFactsProvider),
  ),
);

/// Sends bug reports to the relay.
///
/// On the bare Dio on purpose: the relay is not the LubeLogger server, so it
/// must see none of the auth interceptors, none of the credentials and none of
/// the base URL the user configured.
final relayClientProvider = Provider<RelayClient>(
  (ref) => RelayClient(ref.watch(relayDioProvider), baseUrl: relayBaseUrl),
);

/// A report carries the gzipped log in its body — up to a couple of megabytes
/// from a 10 MB session — and dio spends `sendTimeout` on the whole body, so the
/// 15 s an API call gets would fail it on a slow mobile link.
final relayDioProvider = Provider<Dio>(
  (ref) => createBareDio()
    ..options.sendTimeout = kUploadSendTimeout
    ..options.receiveTimeout = kUploadReceiveTimeout,
);

final reportOutboxProvider = Provider<ReportOutbox>(
  (ref) => const ReportOutbox(),
);

/// One per app: it owns the single outbox slot and a timer, and two of them
/// would race each other over both.
final reportSenderProvider = Provider<ReportSender>((ref) {
  final sender = ReportSender(
    client: ref.watch(relayClientProvider),
    outbox: ref.watch(reportOutboxProvider),
    installId: () => installId(ref.read(sharedPreferencesProvider)),
    // Read, not watched: rebuilding this provider on a profile change would
    // hand out a second sender over the same outbox slot.
    demoMode: () => ref.read(serverProfileProvider)?.isDemo ?? false,
    formatVersion: reportLogSchema,
  );
  ref.onDispose(sender.dispose);
  return sender;
});

final vehiclesRepositoryProvider = Provider<VehiclesRepository>(
  (ref) => VehiclesRepository(ref.watch(apiClientProvider).dio),
);

/// A read that answers from the last stored copy — instantly, without a
/// request — and asks the server behind that answer. The screen only rebuilds
/// if the server had something different to say.
///
/// This is what lets a launch show records before the network has been touched.
/// Wherever the offline cache isn't installed (tests, demo mode) the flags are
/// inert and this is exactly the fetch it wraps, no cache and no second call.
Future<T> cachedRead<T>(
  Ref ref,
  Future<T> Function(VehiclesRepository repo) read,
) async {
  // Registered before the first await, while the provider is certainly alive.
  var disposed = false;
  ref.onDispose(() => disposed = true);

  final repo = ref.watch(vehiclesRepositoryProvider);
  final probe = CacheProbe();
  final stored = await read(repo.withCache(probe, cacheFirst: true));
  if (probe.shouldRevalidate) {
    unawaited(_revalidate(ref, repo, read, () => disposed));
  }
  return stored;
}

Future<void> _revalidate<T>(
  Ref ref,
  VehiclesRepository repo,
  Future<T> Function(VehiclesRepository repo) read,
  bool Function() disposed,
) async {
  final probe = CacheProbe();
  try {
    await read(repo.withCache(probe, revalidate: true));
  } on Object {
    // Unreachable, or refused: the stored copy remains the best answer, and
    // this refresh was never something the user asked for.
    return;
  }
  if (probe.changed && !disposed()) ref.invalidateSelf();
}

/// Server metadata (currency, locale, date format). Cached per session; drives
/// number/date formatting across the app.
final serverInfoProvider = FutureProvider<ServerInfo>(
  (ref) => cachedRead(ref, (repo) => repo.serverInfo()),
);

/// Which version-gated endpoints the connected server has. Derived from
/// [serverInfoProvider]'s `currentVersion`, and permissive while that is still
/// loading — see [ServerCapabilities].
final serverCapabilitiesProvider = Provider<ServerCapabilities>(
  (ref) => ServerCapabilities.forVersion(
    ref.watch(serverInfoProvider).valueOrNull?.currentVersion ?? '',
  ),
);

/// The household's custom-field templates, or null when the server didn't
/// answer — `/api/extrafields` is newer than the record endpoints, and
/// [mergeExtraFields] treats null as "unknown" and round-trips a record's own
/// fields rather than clearing them. Cached for the session.
final extraFieldTemplatesProvider =
    FutureProvider<Map<ExtraFieldRecordType, List<ExtraField>>?>((ref) async {
      try {
        return await cachedRead(ref, (repo) => repo.extraFieldTemplates());
      } on Object catch (error) {
        // The HTTP probe records the failed call; this records that the app chose
        // to carry on without templates, which is why an edit form may show a
        // record's stale fields instead of the configured ones.
        DiagnosticRecorder.active?.add(
          LogSource.http,
          'extra_fields_unavailable',
          lvl: LogLevel.warn,
          fields: {'type': error.runtimeType.toString()},
        );
        return null;
      }
    });

/// One record type's custom-field template: null when unknown, empty when the
/// server has none configured for it (it omits those types entirely).
final extraFieldTemplateProvider =
    Provider.family<AsyncValue<List<ExtraField>?>, ExtraFieldRecordType>(
      (ref, type) => ref
          .watch(extraFieldTemplatesProvider)
          .whenData(
            (templates) => templates == null
                ? null
                : templates[type] ?? const <ExtraField>[],
          ),
    );

/// The authenticated account (username, email, admin/root). Powers the Settings
/// "signed in as" line and gates the root-only backup action.
final whoAmIProvider = FutureProvider<WhoAmI>(
  (ref) => cachedRead(ref, (repo) => repo.whoAmI()),
);

/// Running vs. latest server version, for the Settings "update available" hint.
final serverVersionProvider = FutureProvider<ServerVersion>(
  (ref) => cachedRead(ref, (repo) => repo.serverVersion()),
);

/// Garage contents: every vehicle with its aggregated info, in one request.
final garageProvider = FutureProvider<List<VehicleInfo>>(
  (ref) => cachedRead(ref, (repo) => repo.allInfo()),
);

/// Aggregated info for one vehicle (odometer, costs, reminders) — powers the
/// dashboard header, stat block, and both expense/reminder charts.
final vehicleInfoProvider = FutureProvider.family<VehicleInfo, int>(
  (ref, vehicleId) => cachedRead(ref, (repo) => repo.info(vehicleId)),
);

/// Display units for one vehicle. Until the vehicle loads it reports the plain
/// combustion/distance units, so a label can settle from `L` to `kWh`.
final vehicleUnitsProvider = Provider.family<VehicleUnits, int>((
  ref,
  vehicleId,
) {
  final vehicle = ref
      .watch(vehicleInfoProvider(vehicleId))
      .valueOrNull
      ?.vehicle;
  return VehicleUnits(
    ref.watch(unitsSettingsProvider),
    isElectric: vehicle?.isElectric ?? false,
    useHours: vehicle?.useHours ?? false,
  );
});

/// Locally-computed fuel statistics for one vehicle (lifetime average, distance
/// span, per-month economy). Kept in raw stored units; unit conversion happens
/// at display time, so this doesn't depend on the units settings. It does depend
/// on the vehicle: an electric one's consumption is derived from state of charge
/// rather than read off the record.
///
/// Computed from [gasRecordsProvider] rather than fetching its own copy — the
/// dashboard and the Fuel tab would otherwise ask for the same log twice.
final gasStatsProvider = FutureProvider.family<GasStats, int>((
  ref,
  vehicleId,
) async {
  final (records, info) = await (
    ref.watch(gasRecordsProvider(vehicleId).future),
    ref.watch(vehicleInfoProvider(vehicleId).future),
  ).wait;
  return GasStats.from(records, isElectric: info.vehicle.isElectric);
});

/// Raw refuel log for one vehicle, powering the Fuel tab's per-record table
/// (economy is computed by [fuelRows]). Distinct from [gasStatsProvider], which
/// aggregates the same records into lifetime/monthly stats.
final gasRecordsProvider = FutureProvider.family<List<GasRecord>, int>(
  (ref, vehicleId) => cachedRead(ref, (repo) => repo.gasRecords(vehicleId)),
);

/// Odometer readings for one vehicle, powering the Odometer tab's table.
final odometerRecordsProvider =
    FutureProvider.family<List<OdometerRecord>, int>(
      (ref, vehicleId) =>
          cachedRead(ref, (repo) => repo.odometerRecords(vehicleId)),
    );

/// Date of the vehicle's highest-odometer reading among fuel-ups and dedicated
/// odometer records — the "as of" date shown under the dashboard's "Last
/// Reported Odometer" stat. Reads [odometerReadingsProvider], the same timeline
/// [ExpenseTimeline] charts (gas + odometer records only), not the server's
/// `lastReportedOdometer`, which also considers service/repair/upgrade
/// mileage — a rare enough source for the current max that this stays a close
/// approximation without fetching those record types just for a date label.
final lastOdometerDateProvider = FutureProvider.family<DateTime?, int>(
  (ref, vehicleId) async => highestReadingDate(
    await ref.watch(odometerReadingsProvider(vehicleId).future),
  ),
);

/// Every odometer reading from fuel-ups and dedicated odometer records, so a
/// fuel-only vehicle still has a distance timeline.
final odometerReadingsProvider =
    FutureProvider.family<List<OdometerReading>, int>((ref, vehicleId) async {
      final (gas, odometers) = await (
        ref.watch(gasRecordsProvider(vehicleId).future),
        ref.watch(odometerRecordsProvider(vehicleId).future),
      ).wait;
      return [
        for (final g in gas) (date: g.date, odometer: g.odometer),
        for (final o in odometers) (date: o.date, odometer: o.odometer),
      ];
    });

/// Full records for one vehicle's generic (date + cost) record tab, keyed by
/// vehicle + [RecordKind] (service / repair / upgrade / tax).
final vehicleRecordsProvider =
    FutureProvider.family<
      List<VehicleRecord>,
      ({int vehicleId, RecordKind kind})
    >(
      (ref, key) =>
          cachedRead(ref, (repo) => repo.records(key.kind, key.vehicleId)),
    );

/// Supply / part records for one vehicle, powering the Supplies tab.
final supplyRecordsProvider = FutureProvider.family<List<SupplyRecord>, int>(
  (ref, vehicleId) => cachedRead(ref, (repo) => repo.supplyRecords(vehicleId)),
);

/// Planner items for one vehicle, powering the Planner tab.
final planRecordsProvider = FutureProvider.family<List<PlanRecord>, int>(
  (ref, vehicleId) => cachedRead(ref, (repo) => repo.planRecords(vehicleId)),
);

/// Reminders for one vehicle, powering the Reminders tab.
final remindersProvider = FutureProvider.family<List<ReminderRecord>, int>(
  (ref, vehicleId) => cachedRead(ref, (repo) => repo.reminders(vehicleId)),
);

/// Free-text notes for one vehicle, powering the Notes tab.
final notesProvider = FutureProvider.family<List<NoteRecord>, int>(
  (ref, vehicleId) => cachedRead(ref, (repo) => repo.notes(vehicleId)),
);

/// Equipment items for one vehicle, powering the Equipment tab.
final equipmentRecordsProvider =
    FutureProvider.family<List<EquipmentRecord>, int>(
      (ref, vehicleId) =>
          cachedRead(ref, (repo) => repo.equipmentRecords(vehicleId)),
    );

/// Every dated expense (by category) and distance gain of one vehicle, which the
/// dashboard charts slice into the range each one shows.
///
/// Every list it needs is already a provider of its own, so it composes those
/// instead of re-fetching: opening the dashboard and then a record tab reads
/// each endpoint once.
final expenseTimelineProvider = FutureProvider.family<ExpenseTimeline, int>((
  ref,
  vehicleId,
) async {
  Future<List<VehicleRecord>> records(RecordKind kind) => ref.watch(
    vehicleRecordsProvider((vehicleId: vehicleId, kind: kind)).future,
  );

  final (service, repair, upgrade, tax, gas, readings) = await (
    records(RecordKind.service),
    records(RecordKind.repair),
    records(RecordKind.upgrade),
    records(RecordKind.tax),
    ref.watch(gasRecordsProvider(vehicleId).future),
    ref.watch(odometerReadingsProvider(vehicleId).future),
  ).wait;

  List<DatedCost> costs(List<VehicleRecord> records) => [
    for (final r in records) DatedCost(date: r.date, cost: r.cost),
  ];

  return ExpenseTimeline.from(
    costsByCategory: {
      ExpenseCategory.service: costs(service),
      ExpenseCategory.repair: costs(repair),
      ExpenseCategory.upgrade: costs(upgrade),
      ExpenseCategory.tax: costs(tax),
      ExpenseCategory.fuel: [
        for (final r in gas) DatedCost(date: r.date, cost: r.cost),
      ],
    },
    odometerReadings: readings,
  );
});

/// Drops every request behind one vehicle's screens, for pull-to-refresh.
///
/// The stats and the expense timeline derive from these lists rather than
/// fetching their own copies, so they follow — invalidating *them* would only
/// recompute from the same cache.
///
/// Takes the invalidator rather than a ref: `Ref` and `WidgetRef` share no
/// supertype, and this is called from both a notifier and a widget.
void invalidateVehicleData(Invalidate invalidate, int vehicleId) {
  invalidate(vehicleInfoProvider(vehicleId));
  invalidate(gasRecordsProvider(vehicleId));
  invalidate(odometerRecordsProvider(vehicleId));
  for (final kind in RecordKind.values) {
    invalidate(vehicleRecordsProvider((vehicleId: vehicleId, kind: kind)));
  }
}

/// `ref.invalidate` from either a provider or a widget. See
/// [invalidateVehicleData].
typedef Invalidate = void Function(ProviderOrFamily provider);
