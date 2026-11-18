import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/models/plan_record.dart';
import 'package:lubelogger_mobile/core/models/reminder_record.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';

import 'contract_server.dart';

/// What a real LubeLogger does with the requests the app builds: every record
/// type, add / read back / update / delete, against a container per server
/// version and locale (`just test-contract`).
///
/// The unit tests assert the shape of a request; only a server can say whether
/// it reads that request the way the app means it. The case that matters is a
/// server whose culture writes decimals with a comma (de-DE, pl-PL): it reads a
/// "174.9" string as 1749, so money has to travel as a JSON number (issue #30).
/// Without `LUBELOGGER_URL` the whole file is skipped and `flutter test` stays
/// offline.
void main() {
  final server = ContractServer.fromEnvironment();
  final date = DateTime(2026, 11, 17);

  /// A whole number as `parseUserDecimal` hands it over (a double, so a string
  /// would read "189.0"), a fraction, one under 1, one with thousands, and cents.
  const amounts = <double>[189.0, 174.9, 0.5, 1234.5, 0.01];
  final expected = {for (final a in amounts) '$a': a};

  group(
    'LubeLogger ${server?.version} (locale "${server?.locale}")',
    skip: server == null
        ? 'LUBELOGGER_URL is not set (see just test-contract)'
        : null,
    () {
      late VehiclesRepository repo;
      late int vehicleId;

      setUp(() async {
        repo = server!.repository;
        vehicleId = (await repo.addVehicle(
          year: 2020,
          make: 'Contract',
          model: 'Test',
          licensePlate: 'CT-${DateTime.now().microsecondsSinceEpoch}',
          fuelType: 'Gasoline',
        ))!;
      });

      tearDown(() async {
        // 1.6.9 has no vehicle delete; its data dies with the container.
        try {
          await repo.deleteVehicle(vehicleId);
        } on Object {
          // Nothing to clean up on an older server.
        }
      });

      /// Adds one record per amount, labelled with it, and returns what the
      /// server stored as label -> value.
      Future<Map<String, double>> stored(
        Future<void> Function(double amount, String label) add,
        Future<Map<String, double>> Function() read,
      ) async {
        for (final amount in amounts) {
          await add(amount, '$amount');
        }
        return read();
      }

      test('reports the version under test', () async {
        // Not `repo.serverVersion()`: its `checkForUpdate` makes the server ask
        // the GitHub API, which answers 403 once the unauthenticated rate limit
        // is gone (shared CI runners hit it) and drops `currentVersion`.
        final res = await server!.dio.get<Map<String, dynamic>>('/api/version');
        final current = res.data!['currentVersion'] as String;
        expect(current, isNotEmpty);
        // `latest` is a moving tag: nothing to compare it to.
        if (RegExp(r'^v\d').hasMatch(server.version)) {
          expect(current, server.version.substring(1));
        }
      });

      test(
        'serves the account and server info the app reads on login',
        () async {
          expect((await repo.whoAmI()).username, isNotEmpty);
          expect(await repo.serverInfo(), isNotNull);
        },
      );

      group('money', () {
        for (final kind in RecordKind.values) {
          test('${kind.name} cost round-trips', () async {
            final back = await stored(
              (amount, label) => repo.addRecord(
                kind: kind,
                vehicleId: vehicleId,
                date: date,
                description: label,
                cost: amount,
                odometer: kind.hasOdometer ? 1000 : null,
              ),
              () async => {
                for (final r in await repo.records(kind, vehicleId))
                  r.description: r.cost,
              },
            );
            expect(back, expected);
          });
        }

        test('fuel litres and cost round-trip', () async {
          final back = await stored(
            (amount, label) => repo.addGasRecord(
              vehicleId: vehicleId,
              date: date,
              odometer: 1000,
              fuelConsumed: amount,
              cost: amount,
              isFillToFull: true,
              missedFuelUp: false,
              notes: label,
            ),
            // NaN when litres and cost disagree, so one wrong field fails.
            () async => {
              for (final r in await repo.gasRecords(vehicleId))
                r.notes: r.cost == r.fuelConsumed ? r.cost : double.nan,
            },
          );
          expect(back, expected);
        });

        test('supply quantity and cost round-trip', () async {
          final back = await stored(
            (amount, label) => repo.addSupplyRecord(
              vehicleId: vehicleId,
              date: date,
              description: label,
              partQuantity: amount,
              cost: amount,
            ),
            () async => {
              for (final r in await repo.supplyRecords(vehicleId))
                r.description: double.parse(r.partQuantity) == r.cost
                    ? r.cost
                    : double.nan,
            },
          );
          expect(back, expected);
        });

        test('plan cost round-trips', () async {
          final back = await stored(
            (amount, label) => repo.addPlanRecord(
              vehicleId: vehicleId,
              description: label,
              cost: amount,
              type: PlanType.service,
              priority: PlanPriority.normal,
              progress: PlanProgress.backlog,
            ),
            () async => {
              for (final r in await repo.planRecords(vehicleId))
                r.description: r.cost,
            },
          );
          expect(back, expected);
        });

        test('an edit keeps its decimals too', () async {
          await repo.addRecord(
            kind: RecordKind.service,
            vehicleId: vehicleId,
            date: date,
            description: 'edit',
            cost: 10,
            odometer: 1000,
          );
          final id = (await repo.records(
            RecordKind.service,
            vehicleId,
          )).single.id;
          await repo.updateRecord(
            kind: RecordKind.service,
            id: id,
            date: date,
            description: 'edit',
            cost: 174.9,
            odometer: 1000,
          );
          expect(
            (await repo.records(RecordKind.service, vehicleId)).single.cost,
            174.9,
          );
        });
      });

      group('update and delete', () {
        for (final kind in RecordKind.values) {
          test('${kind.name} record', () async {
            Future<VehicleRecord> only() async =>
                (await repo.records(kind, vehicleId)).single;
            await repo.addRecord(
              kind: kind,
              vehicleId: vehicleId,
              date: date,
              description: 'before',
              cost: 10,
              odometer: kind.hasOdometer ? 1000 : null,
            );
            final id = (await only()).id;
            await repo.updateRecord(
              kind: kind,
              id: id,
              date: date,
              description: 'after',
              cost: 20,
              odometer: kind.hasOdometer ? 1000 : null,
            );
            expect((await only()).description, 'after');
            await repo.deleteRecord(kind, id);
            expect(await repo.records(kind, vehicleId), isEmpty);
          });
        }

        test('fuel record', () async {
          await repo.addGasRecord(
            vehicleId: vehicleId,
            date: date,
            odometer: 1000,
            fuelConsumed: 40,
            cost: 50,
            isFillToFull: true,
            missedFuelUp: false,
            notes: 'before',
          );
          final id = (await repo.gasRecords(vehicleId)).single.id;
          await repo.updateGasRecord(
            vehicleId: vehicleId,
            id: id,
            date: date,
            odometer: 1000,
            fuelConsumed: 41.5,
            cost: 50,
            isFillToFull: true,
            missedFuelUp: false,
            notes: 'after',
          );
          final r = (await repo.gasRecords(vehicleId)).single;
          expect((r.notes, r.fuelConsumed), ('after', 41.5));
          await repo.deleteGasRecord(id);
          expect(await repo.gasRecords(vehicleId), isEmpty);
        });

        test('supply record', () async {
          await repo.addSupplyRecord(
            vehicleId: vehicleId,
            date: date,
            description: 'before',
            partQuantity: 1,
            cost: 5,
          );
          final id = (await repo.supplyRecords(vehicleId)).single.id;
          await repo.updateSupplyRecord(
            id: id,
            date: date,
            description: 'after',
            partQuantity: 2.5,
            cost: 6.5,
          );
          final r = (await repo.supplyRecords(vehicleId)).single;
          expect(
            (r.description, double.parse(r.partQuantity), r.cost),
            ('after', 2.5, 6.5),
          );
          await repo.deleteSupplyRecord(id);
          expect(await repo.supplyRecords(vehicleId), isEmpty);
        });

        // The API refuses `Done` (400); the other progress values are its to take.
        test('plan record', () async {
          await repo.addPlanRecord(
            vehicleId: vehicleId,
            description: 'before',
            cost: 5,
            type: PlanType.repair,
            priority: PlanPriority.low,
            progress: PlanProgress.backlog,
          );
          final id = (await repo.planRecords(vehicleId)).single.id;
          await repo.updatePlanRecord(
            id: id,
            description: 'after',
            cost: 6.5,
            type: PlanType.upgrade,
            priority: PlanPriority.critical,
            progress: PlanProgress.testing,
          );
          final r = (await repo.planRecords(vehicleId)).single;
          expect(
            (r.description, r.cost, r.type, r.priority, r.progress),
            (
              'after',
              6.5,
              PlanType.upgrade,
              PlanPriority.critical,
              PlanProgress.testing,
            ),
          );
          await repo.deletePlanRecord(id);
          expect(await repo.planRecords(vehicleId), isEmpty);
        });

        test('odometer record', () async {
          await repo.addOdometerRecord(
            vehicleId: vehicleId,
            date: date,
            odometer: 1000,
          );
          final first = (await repo.odometerRecords(vehicleId)).single;
          await repo.updateOdometerRecord(
            id: first.id,
            date: date,
            odometer: 2000,
            initialOdometer: first.initialOdometer,
          );
          expect((await repo.odometerRecords(vehicleId)).single.odometer, 2000);
          await repo.deleteOdometerRecord(first.id);
          expect(await repo.odometerRecords(vehicleId), isEmpty);
        });

        test('reminder', () async {
          await repo.addReminder(
            vehicleId: vehicleId,
            description: 'before',
            metric: ReminderMetric.both,
            dueDate: DateTime(2027, 1, 2),
            dueOdometer: 5000,
          );
          final id = (await repo.reminders(vehicleId)).single.id;
          await repo.updateReminder(
            id: id,
            description: 'after',
            metric: ReminderMetric.odometer,
            dueOdometer: 6000,
          );
          final r = (await repo.reminders(vehicleId)).single;
          expect(
            (r.description, r.metric, r.dueOdometer),
            ('after', ReminderMetric.odometer, 6000),
          );
          await repo.deleteReminder(id);
          expect(await repo.reminders(vehicleId), isEmpty);
        });

        test('note', () async {
          await repo.addNote(
            vehicleId: vehicleId,
            description: 'before',
            noteText: 'text',
          );
          final id = (await repo.notes(vehicleId)).single.id;
          await repo.updateNote(
            id: id,
            description: 'after',
            noteText: 'changed',
            pinned: true,
          );
          final n = (await repo.notes(vehicleId)).single;
          expect(
            (n.description, n.noteText, n.pinned),
            ('after', 'changed', true),
          );
          await repo.deleteNote(id);
          expect(await repo.notes(vehicleId), isEmpty);
        });

        test('equipment record', () async {
          await repo.addEquipmentRecord(
            vehicleId: vehicleId,
            description: 'before',
            isEquipped: false,
          );
          final id = (await repo.equipmentRecords(vehicleId)).single.id;
          await repo.updateEquipmentRecord(
            id: id,
            description: 'after',
            isEquipped: true,
          );
          final e = (await repo.equipmentRecords(vehicleId)).single;
          expect((e.description, e.isEquipped), ('after', true));
          await repo.deleteEquipmentRecord(id);
          expect(await repo.equipmentRecords(vehicleId), isEmpty);
        });
      });
    },
  );
}
