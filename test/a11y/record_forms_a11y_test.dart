import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/fuel_entry_mode.dart';
import 'package:lubelogger_mobile/core/models/vehicle_tab.dart';
import 'package:lubelogger_mobile/features/common/vehicle_tab_ui.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_list.dart';
import 'package:material_ui/material_ui.dart';

import 'a11y_harness.dart';

/// The title each record form opens with, for a new record and for an existing
/// one. Read from the localization API, so a reworded title cannot detach a test
/// from its form.
({String add, String edit}) _titles(VehicleTab tab) => switch (tab) {
  VehicleTab.odometer => (
    add: pl.formOdometerTitle,
    edit: pl.formOdometerEditTitle,
  ),
  VehicleTab.service => (
    add: pl.formServiceTitle,
    edit: pl.formServiceEditTitle,
  ),
  VehicleTab.repair => (add: pl.formRepairTitle, edit: pl.formRepairEditTitle),
  VehicleTab.upgrade => (
    add: pl.formUpgradeTitle,
    edit: pl.formUpgradeEditTitle,
  ),
  VehicleTab.fuel => (add: pl.formFuelTitle, edit: pl.formFuelEditTitle),
  VehicleTab.tax => (add: pl.formTaxTitle, edit: pl.formTaxEditTitle),
  VehicleTab.supply => (add: pl.formSupplyTitle, edit: pl.formSupplyEditTitle),
  VehicleTab.plan => (add: pl.formPlanTitle, edit: pl.formPlanEditTitle),
  VehicleTab.reminder => (
    add: pl.formReminderTitle,
    edit: pl.formReminderEditTitle,
  ),
  VehicleTab.note => (add: pl.formNoteTitle, edit: pl.formNoteEditTitle),
  VehicleTab.equipment => (
    add: pl.formEquipmentTitle,
    edit: pl.formEquipmentEditTitle,
  ),
};

/// The forms that ask for a date, and so have the calendar button.
const _withDate = {
  VehicleTab.odometer,
  VehicleTab.service,
  VehicleTab.repair,
  VehicleTab.upgrade,
  VehicleTab.fuel,
  VehicleTab.tax,
  VehicleTab.supply,
  VehicleTab.reminder,
};

const _vehicle = '/vehicle/1';

/// The words a parameterised string starts with, to find it without knowing the
/// unit that fills it in.
String _prefix(String Function(String) format) =>
    format('\u0000').split('\u0000').first.trim();

Future<void> _openTab(WidgetTester tester, VehicleTab tab) => a11yTap(
  tester,
  find.descendant(of: find.byType(TabBar), matching: find.text(tab.label(pl))),
);

/// The `+` on a record tab adds that tab's record type straight away.
Future<void> _openAdd(WidgetTester tester, VehicleTab tab) async {
  await _openTab(tester, tab);
  await a11yTap(tester, byLogId('vehicle.add'));
}

/// A tap on a card opens the record for editing.
Future<void> _openEdit(
  WidgetTester tester,
  VehicleTab tab, {
  Finder? card,
}) async {
  await _openTab(tester, tab);
  await a11yTap(tester, card ?? find.byType(RecordCard).first);
}

void main() {
  for (final tab in VehicleTab.values) {
    final titles = _titles(tab);
    group('${tab.name} form', () {
      a11ySurface(
        '${tab.name}: new record',
        location: _vehicle,
        arrange: (tester) => _openAdd(tester, tab),
        shows: find.text(titles.add),
      );

      a11ySurface(
        '${tab.name}: new record saved empty',
        location: _vehicle,
        arrange: (tester) async {
          await _openAdd(tester, tab);
          await a11yTap(tester, byLogId('form.submit'));
        },
        shows: a11yValidationError,
      );

      a11ySurface(
        '${tab.name}: existing record',
        location: _vehicle,
        arrange: (tester) => _openEdit(tester, tab),
        shows: find.text(titles.edit),
      );

      a11ySurface(
        '${tab.name}: delete confirmation',
        location: _vehicle,
        arrange: (tester) async {
          await _openEdit(tester, tab);
          await a11yTap(tester, byLogId('form.delete'));
        },
        shows: find.text(pl.confirmDeleteTitle),
      );

      if (_withDate.contains(tab)) {
        a11ySurface(
          '${tab.name}: date picker',
          location: _vehicle,
          arrange: (tester) async {
            await _openAdd(tester, tab);
            await a11yTap(tester, find.byIcon(Icons.calendar_month).first);
          },
          shows: find.byType(DatePickerDialog),
        );
      }
    });
  }

  group('service record with a file and custom fields', () {
    // The first service card in the demo carries an invoice and a required custom
    // field, the two things the other forms do not show.
    final invoice = find.widgetWithText(RecordCard, 'Oil & filter change');

    a11ySurface(
      'existing service record with an attachment',
      location: _vehicle,
      arrange: (tester) => _openEdit(tester, VehicleTab.service, card: invoice),
      shows: find.text('invoice.jpg'),
    );

    a11ySurface(
      'attachment opened',
      location: _vehicle,
      arrange: (tester) async {
        await _openEdit(tester, VehicleTab.service, card: invoice);
        await a11yTap(tester, find.text('invoice.jpg'));
      },
      // The viewer is a page of its own; the avatar's image is on every screen.
      shows: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_ImageViewerPage',
      ),
    );

    a11ySurface(
      'custom date field picker',
      location: _vehicle,
      arrange: (tester) async {
        await _openEdit(tester, VehicleTab.service, card: invoice);
        await a11yTap(tester, find.text('Warranty until'));
      },
      shows: find.byType(DatePickerDialog),
    );
  });

  group('fuel form variants', () {
    for (final mode in FuelEntryMode.values) {
      a11ySurface(
        'new fuel record, entry mode ${mode.name}',
        location: _vehicle,
        prefs: {'fuel_entry_mode': mode.name},
        arrange: (tester) => _openAdd(tester, VehicleTab.fuel),
        shows: find.text(pl.formFuelTitle),
      );

      a11ySurface(
        'existing fuel record, entry mode ${mode.name}',
        location: _vehicle,
        prefs: {'fuel_entry_mode': mode.name},
        arrange: (tester) => _openEdit(tester, VehicleTab.fuel),
        shows: find.text(pl.formFuelEditTitle),
      );
    }

    a11ySurface(
      'new fuel record on the diesel vehicle',
      location: '/vehicle/2',
      arrange: (tester) => _openAdd(tester, VehicleTab.fuel),
      shows: find.text(pl.formFuelTitle),
    );
  });

  group('odometer form variants', () {
    a11ySurface(
      'a reading below the last one',
      location: _vehicle,
      arrange: (tester) async {
        await _openAdd(tester, VehicleTab.odometer);
        await a11yEnter(
          tester,
          find
              .descendant(
                of: find.byType(Form),
                matching: find.byType(TextFormField),
              )
              .first,
          '1',
        );
        await a11yTap(tester, byLogId('form.submit'));
      },
      shows: find.text(pl.formOdometerBackwardsTitle),
    );
  });

  group('plan form menus', () {
    for (final id in [
      'form.plan_type',
      'form.plan_priority',
      'form.plan_progress',
    ]) {
      a11ySurface(
        'plan menu $id open',
        location: _vehicle,
        arrange: (tester) async {
          await _openAdd(tester, VehicleTab.plan);
          await a11yTap(tester, byLogId(id));
        },
        // A `dashCombo` builds its entries only when it opens, each tagged
        // `<id>.option`; the closed field has none (audited by skipping the tap).
        shows: byLogId('$id.option').first,
      );
    }
  });

  group('reminder form variants', () {
    a11ySurface(
      'reminder metric menu open',
      location: _vehicle,
      arrange: (tester) async {
        await _openAdd(tester, VehicleTab.reminder);
        await a11yTap(tester, byLogId('form.reminder_metric'));
      },
      shows: find.text(pl.formReminderMetricBoth),
    );

    for (final metric in [
      pl.formReminderMetricOdometer,
      pl.formReminderMetricBoth,
    ]) {
      a11ySurface(
        'reminder due by "$metric"',
        location: _vehicle,
        arrange: (tester) async {
          await _openAdd(tester, VehicleTab.reminder);
          await a11yTap(tester, byLogId('form.reminder_metric'));
          await a11yTap(tester, find.text(metric).last);
        },
        shows: find.textContaining(_prefix(pl.formReminderDueOdometer)),
      );
    }
  });
}
