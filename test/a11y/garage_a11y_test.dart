import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/cache/write_queue.dart';
import 'package:lubelogger_mobile/core/models/server_info.dart';
import 'package:lubelogger_mobile/features/garage/widgets/vehicle_card.dart';
import 'package:lubelogger_mobile/providers.dart';

import 'a11y_harness.dart';

/// Swipes the first card open the way a finger does, then lets the pane settle.
Future<void> _swipeOpen(WidgetTester tester) async {
  final card = find.byType(VehicleCard).first;
  await tester.drag(card, Offset(-tester.getSize(card).width / 2, 0));
  await a11ySettle(tester, const Duration(milliseconds: 700));
}

Future<void> _openAddForm(WidgetTester tester) =>
    a11yTap(tester, find.byType(AddVehicleTile));

Future<void> _openEditForm(WidgetTester tester) async {
  await _swipeOpen(tester);
  await a11yTap(tester, find.text(pl.actionEdit));
}

/// A server that is older than the vehicle-delete route.
final _oldServer = serverInfoProvider.overrideWith(
  (ref) async => const ServerInfo(
    currentVersion: '1.6.9',
    locale: 'en-US',
    currencySymbol: r'$',
    decimalSeparator: '.',
    dateFormat: 'M/d/yyyy',
  ),
);

void main() {
  a11ySurface('garage', shows: find.byType(VehicleCard));

  a11ySurface(
    'garage: no vehicles',
    overrides: [garageProvider.overrideWith((ref) async => [])],
    shows: find.text(pl.garageEmpty),
  );

  a11ySurface(
    'garage: load failed',
    overrides: [
      garageProvider.overrideWith((ref) async => throw Exception('offline')),
    ],
    shows: find.text(pl.garageLoadError),
  );

  a11ySurface(
    'garage: card swiped open',
    arrange: _swipeOpen,
    shows: find.text(pl.actionEdit),
  );

  a11ySurface(
    'garage: writes waiting for the server',
    overrides: [
      syncStateProvider.overrideWith(
        () => A11yFixedSync(
          SyncState(
            pending: [
              PendingWrite(
                id: 'a',
                method: 'POST',
                path: '/api/vehicle/gasrecords/add',
                query: const {},
                body: const {},
                queuedAt: DateTime(2026, 3, 1),
              ),
            ],
          ),
        ),
      ),
    ],
    shows: find.byTooltip(pl.syncPendingTooltip),
  );

  a11ySurface(
    'garage: server not answering',
    overrides: [
      syncStateProvider.overrideWith(
        () => A11yFixedSync(const SyncState(offline: true)),
      ),
    ],
    shows: find.byTooltip(pl.syncOfflineTooltip),
  );

  group('add vehicle form', () {
    a11ySurface(
      'add vehicle',
      arrange: _openAddForm,
      shows: find.text(pl.formVehicleTitle),
    );

    a11ySurface(
      'add vehicle: empty form saved',
      arrange: (tester) async {
        await _openAddForm(tester);
        await a11yTap(tester, byLogId('form.submit'));
      },
      shows: a11yValidationError,
    );

    a11ySurface(
      'add vehicle: fuel type menu open',
      arrange: (tester) async {
        await _openAddForm(tester);
        await a11yTap(tester, find.text(pl.fuelTypeGasoline));
      },
      shows: find.text(pl.fuelTypeElectric),
    );
  });

  group('edit vehicle form', () {
    a11ySurface(
      'edit vehicle',
      arrange: _openEditForm,
      shows: find.text(pl.formVehicleEditTitle),
    );

    a11ySurface(
      'edit vehicle: first delete confirmation',
      arrange: (tester) async {
        await _openEditForm(tester);
        await a11yTap(tester, byLogId('form.delete'));
      },
      shows: find.text(pl.confirmDeleteVehicleTitle),
    );

    a11ySurface(
      'edit vehicle: final delete confirmation',
      arrange: (tester) async {
        await _openEditForm(tester);
        await a11yTap(tester, byLogId('form.delete'));
        await a11yTap(tester, find.text(pl.actionDelete));
      },
      shows: find.text(pl.actionDeletePermanently),
    );

    a11ySurface(
      'edit vehicle: delete unsupported on this server',
      overrides: [_oldServer],
      arrange: (tester) async {
        await _openEditForm(tester);
        await a11yTap(tester, byLogId('form.delete'));
      },
      shows: find.text(pl.vehicleDeleteUnsupportedTitle),
    );
  });
}
