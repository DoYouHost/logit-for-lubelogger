import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/core/format/expense_timeline.dart';
import 'package:lubelogger_mobile/core/models/vehicle_info.dart';
import 'package:lubelogger_mobile/core/models/vehicle_tab.dart';
import 'package:lubelogger_mobile/features/common/vehicle_tab_ui.dart';
import 'package:lubelogger_mobile/features/dashboard/widgets/dashboard_charts.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_filter.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_list.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:material_ui/material_ui.dart';

import 'a11y_harness.dart';

const _vehicle = '/vehicle/1';

/// Every record tab is visible by default, so the strip is the real one.
Future<void> _openTab(WidgetTester tester, VehicleTab tab) => a11yTap(
  tester,
  find.descendant(of: find.byType(TabBar), matching: find.text(tab.label(pl))),
);

/// What a tab's list asks the server for, answered with nothing.
List<Override> _empty() => [
  odometerRecordsProvider.overrideWith((ref, id) async => []),
  gasRecordsProvider.overrideWith((ref, id) async => []),
  vehicleRecordsProvider.overrideWith((ref, key) async => []),
  supplyRecordsProvider.overrideWith((ref, id) async => []),
  planRecordsProvider.overrideWith((ref, id) async => []),
  remindersProvider.overrideWith((ref, id) async => []),
  notesProvider.overrideWith((ref, id) async => []),
  equipmentRecordsProvider.overrideWith((ref, id) async => []),
];

/// What a tab's list asks the server for, refused.
List<Override> _failing() => [
  odometerRecordsProvider.overrideWith((ref, id) async => throw Exception()),
  gasRecordsProvider.overrideWith((ref, id) async => throw Exception()),
  vehicleRecordsProvider.overrideWith((ref, key) async => throw Exception()),
  supplyRecordsProvider.overrideWith((ref, id) async => throw Exception()),
  planRecordsProvider.overrideWith((ref, id) async => throw Exception()),
  remindersProvider.overrideWith((ref, id) async => throw Exception()),
  notesProvider.overrideWith((ref, id) async => throw Exception()),
  equipmentRecordsProvider.overrideWith((ref, id) async => throw Exception()),
];

void main() {
  group('dashboard', () {
    a11ySurface(
      'dashboard',
      location: _vehicle,
      shows: find.text(pl.chartExpensesByType),
    );

    a11ySurface(
      'dashboard of the second vehicle',
      location: '/vehicle/2',
      shows: find.text(pl.chartExpensesByType),
    );

    a11ySurface(
      'dashboard: vehicle failed to load',
      location: _vehicle,
      overrides: [
        vehicleInfoProvider.overrideWith((ref, id) async => throw Exception()),
      ],
      shows: find.text(pl.dashLoadError),
    );

    a11ySurface(
      'dashboard: nothing spent in the range',
      location: _vehicle,
      overrides: [
        expenseTimelineProvider.overrideWith(
          (ref, id) async => ExpenseTimeline.from(
            costsByCategory: const {},
            odometerReadings: const [],
          ),
        ),
      ],
      shows: find.text(pl.chartNoDataInRange),
    );

    a11ySurface(
      'dashboard: no reminders',
      location: _vehicle,
      overrides: [
        vehicleInfoProvider.overrideWith(
          (ref, id) async => VehicleInfo.fromJson({
            'vehicleData': {
              'id': id,
              'year': 2020,
              'make': 'Make',
              'model': 'Model',
              'licensePlate': 'PLATE',
              'imageLocation': '',
            },
            'lastReportedOdometer': 1000,
            'serviceRecordCost': 10,
            'repairRecordCost': 20,
            'upgradeRecordCost': 30,
            'taxRecordCost': 40,
            'gasRecordCost': 50,
            'veryUrgentReminderCount': 0,
            'urgentReminderCount': 0,
            'notUrgentReminderCount': 0,
            'pastDueReminderCount': 0,
          }),
        ),
      ],
      shows: find.text(pl.chartNoReminders),
    );

    // A tap on a chart's canvas opens a tooltip over the slot it lands on.
    final tooltip = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Tooltip',
    );

    for (final chart in [ExpenseDistanceChart, EconomyChart]) {
      a11ySurface(
        'dashboard: $chart tooltip',
        location: _vehicle,
        arrange: (tester) async {
          final canvas = find
              .descendant(
                of: find.byType(chart),
                matching: find.byType(GestureDetector),
              )
              .first;
          await a11yTap(tester, canvas);
          // A slot with no value draws nothing, so walk along the canvas until one
          // answers.
          final box = tester.getRect(canvas);
          for (var step = 1; step < 20 && tooltip.evaluate().isEmpty; step++) {
            await tester.tapAt(
              box.topLeft + Offset(box.width * step / 20, box.height / 2),
            );
            await a11ySettle(tester, const Duration(milliseconds: 200));
          }
        },
        shows: tooltip,
      );
    }

    a11ySurface(
      'dashboard: range sheet',
      location: _vehicle,
      arrange: (tester) =>
          a11yTap(tester, byLogId('dashboard.chartRange').first),
      shows: find.text(pl.chartRangeTitle),
    );

    a11ySurface(
      'dashboard: custom range picker',
      location: _vehicle,
      arrange: (tester) async {
        await a11yTap(tester, byLogId('dashboard.chartRange').first);
        await a11yTap(tester, find.text(pl.chartRangeCustom));
      },
      shows: find.byType(DateRangePickerDialog),
    );
  });

  group('add record sheet', () {
    a11ySurface(
      'add record sheet',
      location: _vehicle,
      arrange: (tester) => a11yTap(tester, byLogId('vehicle.add')),
      shows: find.text(pl.addRecordTitle),
    );

    a11ySurface(
      'add record sheet: hidden types expanded',
      location: _vehicle,
      prefs: {
        'visible_tabs': ['odometer', 'fuel'],
      },
      arrange: (tester) async {
        await a11yTap(tester, byLogId('vehicle.add'));
        await a11yTap(tester, byLogId('add_sheet.hidden'));
      },
      // Tax is hidden in this scenario: its tile exists only once the section opens.
      shows: byLogId('add_sheet.tax'),
    );

    a11ySurface(
      'add record sheet: opened by a long press',
      location: _vehicle,
      arrange: (tester) async {
        await a11yTap(tester, find.text(pl.tabOdometer).first);
        // On a record tab the `+` adds that record, so a long press is the only way
        // to the sheet: prove the tab was switched first.
        expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
        await a11yLongPress(tester, byLogId('vehicle.add'));
      },
      shows: find.text(pl.addRecordTitle),
    );
  });

  group('tab strip', () {
    a11ySurface(
      'only the dashboard tab visible',
      location: _vehicle,
      prefs: {'visible_tabs': <String>[]},
      arrange: (tester) async {
        // Scoped to the strip: the dashboard names its odometer in a stat of its own.
        final strip = find.byType(TabBar);
        expect(
          find.descendant(of: strip, matching: find.text(pl.tabOdometer)),
          findsNothing,
        );
        expect(
          find.descendant(of: strip, matching: find.text(pl.catFuel)),
          findsNothing,
        );
      },
      shows: find.text(pl.tabDashboard),
    );

    a11ySurface(
      'tabs reordered',
      location: _vehicle,
      prefs: {
        'tab_order': ['equipment', 'note', 'fuel'],
      },
      arrange: (tester) async {
        double left(String label) => tester
            .getTopLeft(
              find.descendant(
                of: find.byType(TabBar),
                matching: find.text(label),
              ),
            )
            .dx;
        // The strip is laid out in full, so an off-screen tab has a position too.
        expect(left(pl.catEquipment), lessThan(left(pl.catNote)));
        expect(left(pl.catNote), lessThan(left(pl.catFuel)));
        expect(left(pl.catFuel), lessThan(left(pl.tabOdometer)));
      },
      shows: find.text(pl.tabDashboard),
    );
  });

  for (final tab in VehicleTab.values) {
    group('${tab.name} tab', () {
      a11ySurface(
        '${tab.name} records',
        location: _vehicle,
        arrange: (tester) => _openTab(tester, tab),
        shows: find.byType(RecordCard),
      );

      a11ySurface(
        '${tab.name}: no records',
        location: _vehicle,
        overrides: _empty(),
        arrange: (tester) => _openTab(tester, tab),
        shows: find.byType(EmptyStateView),
      );

      a11ySurface(
        '${tab.name}: records failed to load',
        location: _vehicle,
        overrides: _failing(),
        arrange: (tester) => _openTab(tester, tab),
        shows: find.text(pl.retry),
      );
    });
  }

  group('record list tools', () {
    Future<void> openService(WidgetTester tester) =>
        _openTab(tester, VehicleTab.service);

    a11ySurface(
      'sort menu open',
      location: _vehicle,
      arrange: (tester) async {
        await openService(tester);
        await a11yTap(tester, byLogId('records.sort'));
      },
      shows: find.byType(CheckedPopupMenuItem<int>),
    );

    a11ySurface(
      'search typed',
      location: _vehicle,
      arrange: (tester) async {
        await openService(tester);
        await a11yEnter(
          tester,
          find.descendant(
            of: byLogId('records.search'),
            matching: find.byType(TextField),
          ),
          'olej',
        );
      },
      shows: byLogId('records.search.clear'),
    );

    a11ySurface(
      'search without a match',
      location: _vehicle,
      arrange: (tester) async {
        await openService(tester);
        await a11yEnter(
          tester,
          find.descendant(
            of: byLogId('records.search'),
            matching: find.byType(TextField),
          ),
          'zzzzzz-no-such-record',
        );
      },
      shows: find.byType(EmptyStateView),
    );

    a11ySurface(
      'tag filter active',
      location: _vehicle,
      arrange: (tester) async {
        await openService(tester);
        await a11yTap(tester, find.byType(RecordTagChip).first);
      },
      shows: find.byWidgetPredicate((w) => w is RecordTagChip && w.selected),
    );
  });
}
