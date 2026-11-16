import 'package:app_test_kit/app_test_kit.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/cache/write_queue.dart';
import 'package:lubelogger_mobile/providers.dart';

import 'a11y_harness.dart';

PendingWrite _write(String path, {String method = 'POST', int attempts = 0}) =>
    PendingWrite(
      id: '$method $path',
      method: method,
      path: path,
      query: const {},
      body: const {},
      queuedAt: DateTime(2026, 3, 1),
      attempts: attempts,
      lastError: attempts > 0 ? 'Connection refused' : null,
    );

Override _sync(SyncState state) =>
    syncStateProvider.overrideWith(() => A11yFixedSync(state));

Future<void> _openSheet(WidgetTester tester) =>
    a11yTap(tester, byLogId('sync.open'));

void main() {
  a11ySurface(
    'sync sheet: one write waiting',
    overrides: [
      _sync(SyncState(pending: [_write('/api/vehicle/gasrecords/add')])),
    ],
    arrange: _openSheet,
    shows: find.text(pl.syncSendNow),
  );

  a11ySurface(
    'sync sheet: several writes, some retried',
    overrides: [
      _sync(
        SyncState(
          pending: [
            _write('/api/vehicle/gasrecords/add'),
            _write(
              '/api/vehicle/servicerecords/update',
              method: 'PUT',
              attempts: 3,
            ),
            _write('/api/vehicle/notes/delete', method: 'DELETE'),
            _write('/api/vehicles/add'),
          ],
          offline: true,
          lastContact: DateTime(2026, 3, 1, 12),
        ),
      ),
    ],
    arrange: _openSheet,
    shows: find.text(pl.syncSendNow),
  );

  a11ySurface(
    'sync sheet: sending',
    overrides: [
      _sync(
        SyncState(
          pending: [_write('/api/vehicle/gasrecords/add')],
          syncing: true,
        ),
      ),
    ],
    arrange: _openSheet,
    shows: find.text(pl.syncSending),
  );

  a11ySurface(
    'sync sheet: writes the server refused',
    overrides: [
      _sync(
        SyncState(
          rejected: [
            _write('/api/vehicle/gasrecords/add', attempts: 1),
            _write('/api/vehicle/odometerrecords/add', attempts: 1),
          ],
        ),
      ),
    ],
    arrange: _openSheet,
    shows: find.text(pl.syncRejectedTitle),
  );

  a11ySurface(
    'sync sheet: waiting and refused together',
    overrides: [
      _sync(
        SyncState(
          pending: [_write('/api/vehicle/notes/add')],
          rejected: [_write('/api/vehicle/gasrecords/add', attempts: 1)],
        ),
      ),
    ],
    arrange: _openSheet,
    shows: find.text(pl.syncRejectedTitle),
  );

  a11ySurface(
    'sync sheet: server not answering, nothing waiting',
    overrides: [_sync(const SyncState(offline: true))],
    arrange: _openSheet,
    shows: find.text(pl.syncNothingPending),
  );

  a11ySurface(
    'sync sheet: sent, but the server is still away',
    overrides: [
      _sync(
        SyncState(
          pending: [_write('/api/vehicle/gasrecords/add')],
          offline: true,
        ),
      ),
    ],
    arrange: (tester) async {
      await _openSheet(tester);
      await a11yTap(tester, byLogId('sync.send'));
    },
    shows: find.text(pl.syncStillOffline),
  );
}
