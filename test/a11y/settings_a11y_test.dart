import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lubelogger_mobile/core/models/server_version.dart';
import 'package:lubelogger_mobile/providers.dart';

import 'a11y_harness.dart';

const _settings = '/settings';

/// Opens one of the settings selects, the way a finger does.
Future<void> _openSelect(WidgetTester tester, String id) =>
    a11yTap(tester, byLogId(id));

void main() {
  a11ySurface(
    'settings',
    location: _settings,
    shows: find.text(pl.settingsUnits),
  );

  group('selects', () {
    // Every select of the screen. The options of a closed select are built too, hidden
    // in its button, so neither an option's text nor its log id proves the menu is
    // open; the buttons the open route builds for them do.
    final openMenu = find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('_DropdownMenuItemButton'),
    );
    for (final id in [
      'settings.storageBase',
      'settings.currency',
      'settings.fuelEconomy',
      'settings.dateFormat',
      'settings.dateSeparator',
      'settings.chartRange',
      'settings.fuelCalculated',
    ]) {
      a11ySurface(
        'settings: $id open',
        location: _settings,
        arrange: (tester) => _openSelect(tester, id),
        shows: openMenu.first,
      );
    }
  });

  group('states', () {
    a11ySurface(
      'settings: reminders and background refresh on',
      location: _settings,
      prefs: {
        'reminder_notifications_enabled': true,
        'background_refresh_enabled': true,
      },
      shows: find.byWidgetPredicate((w) => w is Switch && w.value),
    );

    a11ySurface(
      'settings: some tabs hidden',
      location: _settings,
      prefs: {
        'visible_tabs': ['odometer', 'fuel'],
        'tab_order': ['fuel', 'odometer'],
      },
      // A tab row whose switch is off: only a hidden tab has one.
      shows: find.descendant(
        of: byLogId('settings.tabOrder.toggle'),
        matching: find.byWidgetPredicate((w) => w is Switch && !w.value),
      ),
    );

    a11ySurface(
      'settings: a server update is available',
      location: _settings,
      overrides: [
        serverVersionProvider.overrideWith(
          (ref) async => const ServerVersion(
            currentVersion: '1.7.0',
            latestVersion: '1.8.0',
          ),
        ),
      ],
      shows: find.textContaining(_prefix(pl.updateAvailable)),
    );

    a11ySurface(
      'settings: backup made',
      location: _settings,
      arrange: (tester) => a11yTap(tester, byLogId('settings.backup')),
      shows: find.text(pl.backupCreated),
    );
  });

  a11ySurface(
    'settings: open source licenses',
    location: _settings,
    arrange: (tester) => a11yTap(tester, byLogId('settings.licenses')),
    shows: find.byType(LicensePage),
  );
}

/// The words a parameterised string starts with, to find it without knowing what
/// fills it in.
String _prefix(String Function(String) format) =>
    format('\u0000').split('\u0000').first.trim();
