import 'dart:convert';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../format/chart_range.dart';
import '../models/vehicle_tab.dart';
import 'server_profile.dart';
import 'units_settings.dart';

/// Persists the server profile and display preferences in SharedPreferences.
/// The URL is not a secret — [CredentialsStore] holds the API key.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _profileKey = 'server_profile';
  static const _unitsKey = 'units_settings';
  static const _visibleTabsKey = 'visible_tabs';
  static const _tabOrderKey = 'tab_order';
  static const _remindersEnabledKey = 'reminder_notifications_enabled';
  static const _backgroundRefreshKey = 'background_refresh_enabled';
  static const _chartRangeKey = 'chart_default_range';

  final SharedPreferences _prefs;

  ServerProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return ServerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Treat a corrupted entry as no profile — the user goes through setup
      // again instead of the app crashing on launch.
      return null;
    }
  }

  Future<void> saveProfile(ServerProfile profile) {
    // Not the URL — that is the user's private host, and the session header
    // already carries its shape. What matters here is that the server the log
    // describes changed halfway through.
    _logChange('profile', profile.isDemo ? 'demo' : 'saved');
    return _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() {
    _logChange('profile', 'cleared');
    return _prefs.remove(_profileKey);
  }

  UnitsSettings loadUnits() {
    final raw = _prefs.getString(_unitsKey);
    if (raw == null) return const UnitsSettings();
    try {
      return UnitsSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const UnitsSettings();
    }
  }

  Future<void> saveUnits(UnitsSettings units) {
    _logChange('units', _unitFacts(units));
    return _prefs.setString(_unitsKey, jsonEncode(units.toJson()));
  }

  /// The record tabs the user wants visible. Absent (never set) defaults to all
  /// tabs; unknown persisted ids are dropped so removing a tab type can't break
  /// loading.
  Set<VehicleTab> loadVisibleTabs() {
    final names = _prefs.getStringList(_visibleTabsKey);
    if (names == null) return VehicleTab.values.toSet();
    return {for (final n in names) ?VehicleTab.byName(n)};
  }

  Future<void> saveVisibleTabs(Set<VehicleTab> tabs) {
    _logChange('tabs_visible', _hiddenTabs(tabs));
    return _prefs.setStringList(_visibleTabsKey, [
      for (final t in tabs) t.name,
    ]);
  }

  /// The order record tabs appear in — on the vehicle screen (after the always-
  /// first Dashboard) and in the FAB add sheet. A full permutation of
  /// [VehicleTab.values]; visibility is tracked separately by [loadVisibleTabs].
  /// Absent (never set) defaults to enum order; unknown persisted ids are
  /// dropped, and any tab missing from the stored order (e.g. one added in a
  /// newer app version) is appended so it can never disappear.
  List<VehicleTab> loadTabOrder() {
    final names = _prefs.getStringList(_tabOrderKey);
    if (names == null) return VehicleTab.values.toList();
    final ordered = [for (final n in names) ?VehicleTab.byName(n)];
    final seen = ordered.toSet();
    return [
      ...ordered,
      for (final t in VehicleTab.values)
        if (!seen.contains(t)) t,
    ];
  }

  Future<void> saveTabOrder(List<VehicleTab> order) {
    _logChange('tab_order', [for (final t in order) t.name]);
    return _prefs.setStringList(_tabOrderKey, [for (final t in order) t.name]);
  }

  /// Whether the background check may post past-due reminder notifications.
  /// Opt-in (defaults off) since it needs the Android 13+ notification
  /// permission. Also read by the WorkManager background isolate.
  bool loadRemindersEnabled() => _prefs.getBool(_remindersEnabledKey) ?? false;

  Future<void> saveRemindersEnabled(bool enabled) {
    _logChange('reminders', enabled);
    return _prefs.setBool(_remindersEnabledKey, enabled);
  }

  /// Whether the background pass may refresh stored data, so the app opens onto
  /// something current instead of a spinner. Defaults on — unlike the reminder
  /// check it needs no permission — but it is the app's only unprompted network
  /// use, which is reason enough for a switch. Also read by the background
  /// isolate. Queued writes are delivered either way.
  bool loadBackgroundRefreshEnabled() =>
      _prefs.getBool(_backgroundRefreshKey) ?? true;

  Future<void> saveBackgroundRefreshEnabled(bool enabled) {
    _logChange('background_refresh', enabled);
    return _prefs.setBool(_backgroundRefreshKey, enabled);
  }

  /// The range dashboard charts open on. Three months unless the user chose
  /// otherwise; an unknown stored name falls back to that too.
  ChartRangePreset loadChartDefaultRange() =>
      ChartRangePreset.byName(_prefs.getString(_chartRangeKey) ?? '') ??
      ChartRangePreset.threeMonths;

  Future<void> saveChartDefaultRange(ChartRangePreset preset) {
    _logChange('chart_range', preset.name);
    return _prefs.setString(_chartRangeKey, preset.name);
  }

  /// The diagnostic recording in progress, over the preferences key both
  /// applications shipped. Written by the UI isolate and read by the
  /// WorkManager one, which is how a recording started in the app reaches an
  /// isolate that shares no Dart state with it.
  ///
  /// A leftover id at startup means the app died mid-recording; the bug-report
  /// controller clears it and offers the salvaged files.
  DiagnosticsSessionStore get diagnosticsSessions =>
      SharedPreferencesSessionStore(_prefs);

  String? loadDiagnosticsSession() => diagnosticsSessions.loadSession();

  Future<void> saveDiagnosticsSession(String? session) =>
      diagnosticsSessions.saveSession(session);

  /// Every preference that changes what the user sees, for the top of a bug
  /// report.
  ///
  /// This app displays other people's numbers, and almost all of how it displays
  /// them is decided here: whether the server's `148230` is kilometres or miles,
  /// which symbol goes next to a cost, and in which order a date's fields are
  /// printed. Without this snapshot, "the odometer is wrong" and "the date is
  /// wrong" both begin with a round of questions whose answers were on the phone
  /// all along.
  ///
  /// None of it is personal: the values are this app's own enum names.
  Map<String, Object?> diagnosticsSnapshot() {
    final hidden = _hiddenTabs(loadVisibleTabs());
    final order = [for (final t in loadTabOrder()) t.name];
    final defaultOrder = [for (final t in VehicleTab.values) t.name];
    return {
      'units': _unitFacts(loadUnits()),
      if (hidden.isNotEmpty) 'tabs_hidden': hidden,
      // Only when the user moved something: the default permutation is twelve
      // names that say nothing, printed at the top of every report.
      if (!_sameOrder(order, defaultOrder)) 'tab_order': order,
      'reminders': loadRemindersEnabled(),
      'chart_range': loadChartDefaultRange().name,
    };
  }

  /// The units settings, plus the date pattern they add up to. The pattern is
  /// derived rather than stored, and it is the field a reader actually wants:
  /// `dd/MM/yyyy` next to a date the server sent as `01/15/2024` is the whole
  /// diagnosis.
  static Map<String, Object?> _unitFacts(UnitsSettings units) => {
    'base': units.base.name,
    'currency': units.currency.name,
    'distance': units.distance.name,
    'economy': units.economy.name,
    'date_fmt': units.dateOrder.pattern.join(units.dateSeparator.value),
  };

  /// Hidden rather than visible: the default is that nothing is hidden, so this
  /// is empty in the common case and names exactly what the user turned off.
  static List<String> _hiddenTabs(Set<VehicleTab> visible) => [
    for (final t in VehicleTab.values)
      if (!visible.contains(t)) t.name,
  ];

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// One preference changed while a recording was running.
  ///
  /// Here rather than in the notifiers that call it, because this class is the
  /// single door every preference goes through — a setting added later is logged
  /// by the same line that persists it, and cannot be forgotten separately.
  static void _logChange(String name, Object? value) => DiagnosticRecorder
      .active
      ?.add(LogSource.app, 'setting', fields: {'name': name, 'value': value});
}
