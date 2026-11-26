import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/api/api_client.dart';
import 'package:lubelogger_mobile/core/api/api_exceptions.dart';
import 'package:lubelogger_mobile/core/api/endpoints.dart';
import 'package:lubelogger_mobile/core/models/attachment.dart';
import 'package:lubelogger_mobile/core/models/extra_field.dart';
import 'package:lubelogger_mobile/core/models/plan_record.dart';
import 'package:lubelogger_mobile/core/models/reminder_record.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';

/// The write half of the API contract, asserted field by field.
///
/// Every value LubeLogger accepts on a write is a **string it parses itself**
/// (`int.Parse`, `decimal.Parse`, `bool.Parse`, `DateTime.Parse`) — see
/// `reference/lubelog/Controllers/API/`. A parse that fails is an HTTP 500 with
/// a .NET message, and the only place the app can get it wrong is the body
/// builders in [VehiclesRepository]: a `317240.0` where the server wants an
/// integer, a locale-formatted date, an omitted field the server dereferences.
/// None of it is visible from the app's own types, so it is asserted here
/// against the shape the controllers actually read.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.status = 200, Map<String, dynamic>? response})
    : response = response ?? const {'success': true, 'message': ''};

  final int status;
  final Map<String, dynamic> response;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The upload endpoint is the one write that answers with a bare array rather
/// than an `OperationResponse`.
class _ArrayResponseAdapter implements HttpClientAdapter {
  _ArrayResponseAdapter(this.response);

  final List<Map<String, dynamic>> response;
  RequestOptions? captured;

  /// The multipart body as it goes on the wire. Drained here for the same
  /// reason a real adapter drains it — an upload's defects live in the bytes,
  /// not in [RequestOptions].
  List<int>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    if (requestStream != null) {
      body = await requestStream.expand((chunk) => chunk).toList();
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

typedef _Fixture = ({VehiclesRepository repo, _CapturingAdapter adapter});

_Fixture _repo({int status = 200, Map<String, dynamic>? response}) {
  final adapter = _CapturingAdapter(status: status, response: response);
  final dio = Dio(BaseOptions(baseUrl: 'http://server'))
    ..httpClientAdapter = adapter;
  return (repo: VehiclesRepository(dio), adapter: adapter);
}

RequestOptions _request(_CapturingAdapter adapter) => adapter.captured!;

Map<String, dynamic> _body(_CapturingAdapter adapter) =>
    adapter.captured!.data as Map<String, dynamic>;

/// One write, named, so the shared-encoding tests can drive every record type
/// through the same assertion instead of restating it per method.
typedef _Write = ({
  String what,
  Future<void> Function(VehiclesRepository) call,
});

final _date = DateTime(2026, 4, 5, 23, 59);

/// Writes that carry a date, each with the same `2026-04-05` late-evening value.
final List<_Write> _dateWrites = [
  (
    what: 'gas add',
    call: (repo) => repo.addGasRecord(
      vehicleId: 1,
      date: _date,
      odometer: 1000,
      fuelConsumed: 40,
      cost: 12,
      isFillToFull: true,
      missedFuelUp: false,
    ),
  ),
  (
    what: 'service add',
    call: (repo) => repo.addRecord(
      kind: RecordKind.service,
      vehicleId: 1,
      date: _date,
      description: 'Oil change',
      cost: 12,
      odometer: 1000,
    ),
  ),
  (
    what: 'tax update',
    call: (repo) => repo.updateRecord(
      kind: RecordKind.tax,
      id: 7,
      date: _date,
      description: 'Road tax',
      cost: 12,
    ),
  ),
  (
    what: 'odometer add',
    call: (repo) =>
        repo.addOdometerRecord(vehicleId: 1, date: _date, odometer: 1000),
  ),
  (
    what: 'supply add',
    call: (repo) => repo.addSupplyRecord(
      vehicleId: 1,
      date: _date,
      description: 'Filters',
      partQuantity: 2,
      cost: 12,
    ),
  ),
  (
    what: 'reminder add',
    call: (repo) => repo.addReminder(
      vehicleId: 1,
      description: 'Service',
      metric: ReminderMetric.date,
      dueDate: _date,
    ),
  ),
];

/// Writes that carry an odometer, all fed the same fractional reading — what a
/// mile-displaying vehicle produces after the km round-trip.
final List<_Write> _odometerWrites = [
  (
    what: 'gas add',
    call: (repo) => repo.addGasRecord(
      vehicleId: 1,
      date: _date,
      odometer: 62137.44,
      fuelConsumed: 40,
      cost: 12,
      isFillToFull: true,
      missedFuelUp: false,
    ),
  ),
  (
    what: 'gas update',
    call: (repo) => repo.updateGasRecord(
      vehicleId: 1,
      id: 7,
      date: _date,
      odometer: 62137.44,
      fuelConsumed: 40,
      cost: 12,
      isFillToFull: true,
      missedFuelUp: false,
    ),
  ),
  (
    what: 'service add',
    call: (repo) => repo.addRecord(
      kind: RecordKind.service,
      vehicleId: 1,
      date: _date,
      description: 'Oil change',
      cost: 12,
      odometer: 62137.44,
    ),
  ),
  (
    what: 'odometer add',
    call: (repo) =>
        repo.addOdometerRecord(vehicleId: 1, date: _date, odometer: 62137.44),
  ),
  (
    what: 'reminder add',
    call: (repo) => repo.addReminder(
      vehicleId: 1,
      description: 'Service',
      metric: ReminderMetric.odometer,
      dueOdometer: 62137.44,
    ),
  ),
];

/// Writes that carry a cost, all fed the same two-decimal amount.
final List<_Write> _costWrites = [
  (
    what: 'gas add',
    call: (repo) => repo.addGasRecord(
      vehicleId: 1,
      date: _date,
      odometer: 1000,
      fuelConsumed: 40,
      cost: 1234.56,
      isFillToFull: true,
      missedFuelUp: false,
    ),
  ),
  (
    what: 'repair add',
    call: (repo) => repo.addRecord(
      kind: RecordKind.repair,
      vehicleId: 1,
      date: _date,
      description: 'Brakes',
      cost: 1234.56,
      odometer: 1000,
    ),
  ),
  (
    what: 'supply add',
    call: (repo) => repo.addSupplyRecord(
      vehicleId: 1,
      date: _date,
      description: 'Filters',
      partQuantity: 2,
      cost: 1234.56,
    ),
  ),
  (
    what: 'plan add',
    call: (repo) => repo.addPlanRecord(
      vehicleId: 1,
      description: 'Winter tyres',
      cost: 1234.56,
      type: PlanType.upgrade,
      priority: PlanPriority.normal,
      progress: PlanProgress.backlog,
    ),
  ),
];

/// One of everything the app can create, for the assertions that hold for every
/// write regardless of type.
final List<_Write> _allAdds = [
  ..._dateWrites,
  (
    what: 'plan add',
    call: (repo) => repo.addPlanRecord(
      vehicleId: 1,
      description: 'Winter tyres',
      cost: 12,
      type: PlanType.upgrade,
      priority: PlanPriority.normal,
      progress: PlanProgress.backlog,
    ),
  ),
  (
    what: 'note add',
    call: (repo) =>
        repo.addNote(vehicleId: 1, description: 'Key code', noteText: '1234'),
  ),
  (
    what: 'equipment add',
    call: (repo) => repo.addEquipmentRecord(
      vehicleId: 1,
      description: 'Winter tyres',
      isEquipped: true,
    ),
  ),
  (
    what: 'vehicle add',
    call: (repo) => repo.addVehicle(
      year: 2019,
      make: 'Skoda',
      model: 'Octavia',
      licensePlate: 'WX 1234A',
      fuelType: 'Diesel',
    ),
  ),
];

void main() {
  group('shared scalar encodings', () {
    for (final write in _dateWrites) {
      test(
        '${write.what} sends an unambiguous ISO date, time of day dropped',
        () async {
          // The server parses with the invariant culture but stores a date only;
          // a "4/5/2026" would read as a different day under `M/d/yyyy` vs
          // `d/M/yyyy`, and a trailing time survives into the stored record.
          final (:repo, :adapter) = _repo();

          await write.call(repo);

          final sent = _body(adapter)['date'] ?? _body(adapter)['dueDate'];
          expect(sent, '2026-04-05');
        },
      );
    }

    for (final write in _odometerWrites) {
      test(
        '${write.what} rounds the odometer to what int.Parse accepts',
        () async {
          // Every odometer field on the server is `int.Parse`d (gas records
          // included: GasController `Mileage = int.Parse(input.Odometer)`), so a
          // "62137.44" from the mi→km round-trip is a 500, not a rounded record.
          final (:repo, :adapter) = _repo();

          await write.call(repo);

          final sent =
              (_body(adapter)['odometer'] ?? _body(adapter)['dueOdometer'])
                  as String;
          expect(sent, '62137');
          expect(int.tryParse(sent), isNotNull, reason: 'sent "$sent"');
        },
      );
    }

    for (final write in _costWrites) {
      test(
        '${write.what} sends the cost as a JSON number, not a string',
        () async {
          // A "1234.56" string is 123456 on a server whose culture groups with
          // "." (de-DE, pl-PL); a number is read back by the culture that wrote
          // it. test/contract holds this against a real server.
          final (:repo, :adapter) = _repo();

          await write.call(repo);

          expect(_body(adapter)['cost'], 1234.56);
        },
      );
    }

    test('a whole-number cost is still a number', () async {
      final (:repo, :adapter) = _repo();

      await repo.addRecord(
        kind: RecordKind.service,
        vehicleId: 1,
        date: _date,
        description: 'Oil change',
        cost: 480,
        odometer: 1000,
      );

      expect(_body(adapter)['cost'], 480);
    });

    test('flags go out as words bool.Parse accepts', () async {
      final flagWrites = <String, Future<void> Function(VehiclesRepository)>{
        'isFillToFull': (repo) => repo.addGasRecord(
          vehicleId: 1,
          date: _date,
          odometer: 1000,
          fuelConsumed: 40,
          cost: 12,
          isFillToFull: true,
          missedFuelUp: false,
        ),
        'pinned': (repo) => repo.addNote(
          vehicleId: 1,
          description: 'Key code',
          noteText: '1234',
          pinned: true,
        ),
        'isEquipped': (repo) => repo.addEquipmentRecord(
          vehicleId: 1,
          description: 'Winter tyres',
          isEquipped: true,
        ),
        'useEngineHours': (repo) => repo.addVehicle(
          year: 2019,
          make: 'Kubota',
          model: 'L1501',
          licensePlate: 'WX 1234A',
          fuelType: 'Diesel',
          useHours: true,
        ),
      };

      for (final entry in flagWrites.entries) {
        final (:repo, :adapter) = _repo();
        await entry.value(repo);
        expect(
          _body(adapter)[entry.key],
          anyOf('true', 'True'),
          reason: entry.key,
        );
      }
    });

    for (final write in _allAdds) {
      test('${write.what} sends a body that is JSON with no nulls in it', () async {
        // A null reaches the server as JSON null, which the string-typed export
        // models bind as an empty field — the required-field check then answers
        // 400 for a value the user did fill in.
        final (:repo, :adapter) = _repo();

        await write.call(repo);

        final body = _body(adapter);
        expect(body.values, everyElement(isNotNull));
        expect(() => jsonEncode(body), returnsNormally);
      });
    }
  });

  group('gas records', () {
    test('an add posts the whole export model under ?vehicleId=', () async {
      final (:repo, :adapter) = _repo();

      await repo.addGasRecord(
        vehicleId: 3,
        date: _date,
        odometer: 317240.0,
        fuelConsumed: 41.53,
        cost: 221.50,
        isFillToFull: true,
        missedFuelUp: false,
        notes: 'Motorway',
        tags: 'trip work',
      );

      final request = _request(adapter);
      expect(request.method, 'POST');
      expect(request.path, Endpoints.gasRecordsAdd);
      expect(request.uri.queryParameters, {'vehicleId': '3'});
      expect(request.contentType, Headers.jsonContentType);
      expect(_body(adapter), {
        'date': '2026-04-05',
        'odometer': '317240',
        'fuelConsumed': 41.53,
        'cost': 221.5,
        'isFillToFull': 'true',
        'missedFuelUp': 'false',
        'startingSoc': '20',
        'endingSoc': '80',
        'notes': 'Motorway',
        'tags': 'trip work',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
      });
    });

    test(
      'an update carries id and vehicleId in the body, not the query',
      () async {
        final (:repo, :adapter) = _repo();

        await repo.updateGasRecord(
          vehicleId: 3,
          id: 7,
          date: _date,
          odometer: 317240,
          fuelConsumed: 41.53,
          cost: 221.50,
          isFillToFull: false,
          missedFuelUp: true,
          startingSoc: 18,
          endingSoc: 92,
        );

        final request = _request(adapter);
        expect(request.method, 'PUT');
        expect(request.path, Endpoints.gasRecordsUpdate);
        expect(request.uri.queryParameters, isEmpty);
        expect(_body(adapter), {
          'id': '7',
          'vehicleId': '3',
          'date': '2026-04-05',
          'odometer': '317240',
          'fuelConsumed': 41.53,
          'cost': 221.5,
          'isFillToFull': 'false',
          'missedFuelUp': 'true',
          'startingSoc': '18',
          'endingSoc': '92',
          'notes': '',
          'tags': '',
          'files': <Map<String, dynamic>>[],
          'extraFields': <Map<String, dynamic>>[],
        });
      },
    );
  });

  group('generic records', () {
    for (final kind in RecordKind.values) {
      test('a ${kind.name} add posts to its own endpoint', () async {
        final (:repo, :adapter) = _repo();

        await repo.addRecord(
          kind: kind,
          vehicleId: 3,
          date: _date,
          description: 'Work',
          cost: 470,
          odometer: kind.hasOdometer ? 320447 : null,
        );

        final request = _request(adapter);
        expect(request.method, 'POST');
        expect(request.path, '${kind.endpoint}/add');
        expect(request.uri.queryParameters, {'vehicleId': '3'});
        expect(_body(adapter), {
          'date': '2026-04-05',
          if (kind.hasOdometer) 'odometer': '320447',
          'description': 'Work',
          'cost': 470,
          'notes': '',
          'tags': '',
          'files': <Map<String, dynamic>>[],
          'extraFields': <Map<String, dynamic>>[],
        });
      });
    }

    test('a tax record omits the odometer key entirely', () async {
      // `TaxRecordExportModel` has no Odometer, and the app has no reading to
      // send for one — an empty string would be a field the model can't bind.
      final (:repo, :adapter) = _repo();

      await repo.addRecord(
        kind: RecordKind.tax,
        vehicleId: 3,
        date: _date,
        description: 'Road tax',
        cost: 120,
      );

      expect(_body(adapter).containsKey('odometer'), isFalse);
    });

    test(
      'an update sends id and lets the server resolve the vehicle',
      () async {
        final (:repo, :adapter) = _repo();

        await repo.updateRecord(
          kind: RecordKind.service,
          id: 12,
          date: _date,
          description: 'Oil change',
          cost: 470,
          odometer: 320447,
        );

        final request = _request(adapter);
        expect(request.method, 'PUT');
        expect(request.path, '${Endpoints.serviceRecords}/update');
        expect(request.uri.queryParameters, isEmpty);
        expect(_body(adapter)['id'], '12');
        expect(_body(adapter).containsKey('vehicleId'), isFalse);
      },
    );
  });

  group('odometer records', () {
    test('an add omits initialOdometer so the server backfills it', () async {
      // OdometerController: an empty InitialOdometer means "use the previous
      // reading"; sending 0 instead would make this record the vehicle's first.
      final (:repo, :adapter) = _repo();

      await repo.addOdometerRecord(
        vehicleId: 3,
        date: _date,
        odometer: 320447,
        notes: 'MOT',
      );

      expect(_request(adapter).path, Endpoints.odometerRecordsAdd);
      expect(_body(adapter), {
        'date': '2026-04-05',
        'odometer': '320447',
        'notes': 'MOT',
        'tags': '',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
      });
    });

    test('an update resends initialOdometer and the equipment link', () async {
      // Both are replaced by whatever arrives, so an omission is a data loss:
      // the update path requires a non-empty InitialOdometer and overwrites
      // EquipmentRecordId with the (space-joined) ids sent.
      final (:repo, :adapter) = _repo();

      await repo.updateOdometerRecord(
        id: 7,
        date: _date,
        odometer: 320447,
        initialOdometer: 319000,
        equipmentRecordId: '3 4',
      );

      expect(_request(adapter).method, 'PUT');
      expect(_body(adapter), {
        'id': '7',
        'date': '2026-04-05',
        'odometer': '320447',
        'initialOdometer': '319000',
        'notes': '',
        'tags': '',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
        'equipmentRecordId': '3 4',
      });
    });
  });

  group('supply records', () {
    test('an add sends quantity and cost as decimals', () async {
      final (:repo, :adapter) = _repo();

      await repo.addSupplyRecord(
        vehicleId: 3,
        date: _date,
        description: 'Oil filter',
        partQuantity: 2.5,
        cost: 89.99,
        partNumber: 'W 712/95',
        partSupplier: 'Mann',
      );

      expect(_request(adapter).path, Endpoints.supplyRecordsAdd);
      expect(_body(adapter), {
        'date': '2026-04-05',
        'description': 'Oil filter',
        'partNumber': 'W 712/95',
        'partSupplier': 'Mann',
        'partQuantity': 2.5,
        'cost': 89.99,
        'notes': '',
        'tags': '',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
      });
    });

    test('an update sends id and the same fields', () async {
      final (:repo, :adapter) = _repo();

      await repo.updateSupplyRecord(
        id: 9,
        date: _date,
        description: 'Oil filter',
        partQuantity: 1,
        cost: 89.99,
      );

      expect(_request(adapter).method, 'PUT');
      expect(_request(adapter).path, Endpoints.supplyRecordsUpdate);
      expect(_body(adapter)['id'], '9');
      expect(_body(adapter)['partQuantity'], 1);
    });
  });

  group('plan records', () {
    test('an add sends the .NET enum names and no date', () async {
      // Type parses as `ImportMode` server-side, so it is "UpgradeRecord" and
      // not "Upgrade"; dateCreated/dateModified are the server's to set.
      final (:repo, :adapter) = _repo();

      await repo.addPlanRecord(
        vehicleId: 3,
        description: 'Winter tyres',
        cost: 480,
        type: PlanType.upgrade,
        priority: PlanPriority.critical,
        progress: PlanProgress.inProgress,
        notes: 'Before November',
      );

      expect(_request(adapter).path, Endpoints.planRecordsAdd);
      expect(_body(adapter), {
        'description': 'Winter tyres',
        'cost': 480,
        'type': 'UpgradeRecord',
        'priority': 'Critical',
        'progress': 'InProgress',
        'notes': 'Before November',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
      });
    });

    test('a plan write carries no date, odometer or tags', () async {
      final (:repo, :adapter) = _repo();

      await repo.updatePlanRecord(
        id: 5,
        description: 'Winter tyres',
        cost: 480,
        type: PlanType.service,
        priority: PlanPriority.low,
        progress: PlanProgress.testing,
      );

      final body = _body(adapter);
      expect(body['id'], '5');
      expect(body['type'], 'ServiceRecord');
      for (final absent in ['date', 'odometer', 'tags']) {
        expect(body.containsKey(absent), isFalse, reason: absent);
      }
    });
  });

  group('reminders', () {
    test('a date reminder sends dueDate and no odometer', () async {
      final (:repo, :adapter) = _repo();

      await repo.addReminder(
        vehicleId: 3,
        description: 'Insurance',
        metric: ReminderMetric.date,
        dueDate: _date,
        tags: 'legal',
      );

      expect(_request(adapter).path, Endpoints.remindersAdd);
      expect(_body(adapter), {
        'description': 'Insurance',
        'metric': 'Date',
        'dueDate': '2026-04-05',
        'notes': '',
        'tags': 'legal',
      });
    });

    test('an odometer reminder sends dueOdometer and no date', () async {
      final (:repo, :adapter) = _repo();

      await repo.addReminder(
        vehicleId: 3,
        description: 'Timing belt',
        metric: ReminderMetric.odometer,
        dueOdometer: 400000,
      );

      expect(_body(adapter), {
        'description': 'Timing belt',
        'metric': 'Odometer',
        'dueOdometer': '400000',
        'notes': '',
        'tags': '',
      });
    });

    test('a both-metric reminder sends both, as the server demands', () async {
      // ReminderController answers `success:false` unless DueDate *and*
      // DueOdometer parse when the metric is Both.
      final (:repo, :adapter) = _repo();

      await repo.updateReminder(
        id: 4,
        description: 'Service',
        metric: ReminderMetric.both,
        dueDate: _date,
        dueOdometer: 400000,
      );

      expect(_request(adapter).method, 'PUT');
      expect(_body(adapter), {
        'id': '4',
        'description': 'Service',
        'metric': 'Both',
        'dueDate': '2026-04-05',
        'dueOdometer': '400000',
        'notes': '',
        'tags': '',
      });
    });

    test('a reminder write has no files or extra fields', () async {
      // `ReminderExportModel` has neither, so there is nowhere for them to go.
      final (:repo, :adapter) = _repo();

      await repo.addReminder(
        vehicleId: 3,
        description: 'Insurance',
        metric: ReminderMetric.date,
        dueDate: _date,
      );

      expect(_body(adapter).containsKey('files'), isFalse);
      expect(_body(adapter).containsKey('extraFields'), isFalse);
    });
  });

  group('notes', () {
    test('an add sends title, body and pin state', () async {
      final (:repo, :adapter) = _repo();

      await repo.addNote(
        vehicleId: 3,
        description: 'Wheel torque',
        noteText: '120 Nm',
        pinned: true,
        tags: 'howto',
      );

      expect(_request(adapter).path, Endpoints.notesAdd);
      expect(_body(adapter), {
        'description': 'Wheel torque',
        'noteText': '120 Nm',
        'pinned': 'true',
        'tags': 'howto',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
      });
    });
  });

  group('equipment', () {
    test('an add sends the equipped flag', () async {
      final (:repo, :adapter) = _repo();

      await repo.addEquipmentRecord(
        vehicleId: 3,
        description: 'Winter tyres',
        isEquipped: false,
        notes: 'In the garage',
      );

      expect(_request(adapter).path, Endpoints.equipmentRecordsAdd);
      expect(_body(adapter), {
        'description': 'Winter tyres',
        'isEquipped': 'false',
        'notes': 'In the garage',
        'tags': '',
        'files': <Map<String, dynamic>>[],
        'extraFields': <Map<String, dynamic>>[],
      });
    });
  });

  group('vehicles', () {
    test('an add sends the import model and reads back the new id', () async {
      final (:repo, :adapter) = _repo(
        response: {
          'success': true,
          'message': 'Vehicle Added',
          'additionalData': {'vehicleId': 42},
        },
      );

      final id = await repo.addVehicle(
        year: 2019,
        make: 'Skoda',
        model: 'Octavia',
        licensePlate: 'WX 1234A',
        fuelType: 'Diesel',
        tags: 'family',
      );

      expect(id, 42);
      expect(_request(adapter).path, Endpoints.vehiclesAdd);
      expect(_body(adapter), {
        'year': '2019',
        'make': 'Skoda',
        'model': 'Octavia',
        'licensePlate': 'WX 1234A',
        'identifier': 'LicensePlate',
        'fuelType': 'Diesel',
        'useEngineHours': 'false',
        'odometerOptional': 'false',
        'tags': 'family',
        'extraFields': <Map<String, dynamic>>[],
      });
    });

    test('an add without an id in the response is not an error', () async {
      final (:repo, adapter: _) = _repo();

      final id = await repo.addVehicle(
        year: 2019,
        make: 'Skoda',
        model: 'Octavia',
        licensePlate: 'WX 1234A',
        fuelType: 'Gasoline',
      );

      expect(id, isNull);
    });

    test('an update resends the identifier so the server keeps it', () async {
      // The server overwrites VehicleIdentifier and ExtraFields with whatever
      // arrives; a vehicle identified by a custom field would lose that link.
      final (:repo, :adapter) = _repo();

      await repo.updateVehicle(
        id: 8,
        year: 2019,
        make: 'Skoda',
        model: 'Octavia',
        licensePlate: 'WX 1234A',
        fuelType: 'Electric',
        identifier: 'VIN',
        extraFields: const [
          ExtraField(name: 'VIN', value: 'TMBJJ7NE0K0123456'),
        ],
      );

      expect(_request(adapter).method, 'PUT');
      expect(_request(adapter).path, Endpoints.vehiclesUpdate);
      expect(_body(adapter)['id'], '8');
      expect(_body(adapter)['identifier'], 'VIN');
      expect(_body(adapter)['extraFields'], [
        {
          'name': 'VIN',
          'value': 'TMBJJ7NE0K0123456',
          'isRequired': false,
          'fieldType': 0,
        },
      ]);
    });
  });

  group('attachments', () {
    test('a record sends its files as the server\'s UploadedFiles', () async {
      // `isPending` must be a real JSON bool: UploadedFiles is a typed class,
      // not one of the stringly export models.
      final (:repo, :adapter) = _repo();

      await repo.addRecord(
        kind: RecordKind.service,
        vehicleId: 3,
        date: _date,
        description: 'Oil change',
        cost: 470,
        odometer: 320447,
        files: const [
          Attachment(name: 'invoice.pdf', location: '/documents/abc.pdf'),
        ],
      );

      expect(_body(adapter)['files'], [
        {
          'name': 'invoice.pdf',
          'location': '/documents/abc.pdf',
          'isPending': false,
        },
      ]);
    });
  });

  group('document upload', () {
    ({VehiclesRepository repo, _ArrayResponseAdapter adapter}) uploader(
      List<Map<String, dynamic>> response,
    ) {
      final adapter = _ArrayResponseAdapter(response);
      final dio = Dio(BaseOptions(baseUrl: 'http://server'))
        ..httpClientAdapter = adapter;
      return (repo: VehiclesRepository(dio), adapter: adapter);
    }

    File tempPdf(String name) {
      final dir = Directory.systemTemp.createTempSync('lubelogger_upload');
      addTearDown(() => dir.deleteSync(recursive: true));
      return File('${dir.path}/$name')..writeAsStringSync('%PDF');
    }

    test('files go up as multipart entries all named "documents"', () async {
      // The server binds `List<IFormFile> documents`; under any other field
      // name it receives nothing and answers 400 "No files to upload".
      final (:repo, :adapter) = uploader(const []);
      final file = tempPdf('invoice.pdf');

      await repo.uploadDocuments([(path: file.path, name: 'invoice.pdf')]);

      final request = adapter.captured!;
      expect(request.method, 'POST');
      expect(request.path, Endpoints.documentsUpload);
      final form = request.data as FormData;
      expect(form.files.map((e) => e.key), ['documents']);
      expect(form.files.single.value.filename, 'invoice.pdf');
    });

    test(
      'the uploaded files come back as attachments to send on a write',
      () async {
        // The endpoint answers with a bare array of UploadedFiles — no
        // `success` envelope — and omits `isPending` for API uploads.
        final (:repo, adapter: _) = uploader(const [
          {'name': 'invoice.pdf', 'location': '/documents/abc.pdf'},
        ]);
        final file = tempPdf('invoice.pdf');

        final attachments = await repo.uploadDocuments([
          (path: file.path, name: 'invoice.pdf'),
        ]);

        expect(attachments.single.name, 'invoice.pdf');
        expect(attachments.single.location, '/documents/abc.pdf');
        expect(attachments.single.isPending, isFalse);
      },
    );

    test('the part header is camel-case Content-Disposition', () async {
      // Both spellings are legal per RFC 7578 and LubeLogger parses either, but
      // a proxy in front of it may not — see issue #15.
      final (:repo, :adapter) = uploader(const []);
      final file = tempPdf('invoice.pdf');

      await repo.uploadDocuments([(path: file.path, name: 'invoice.pdf')]);

      final wire = utf8.decode(adapter.body!);
      expect(wire, contains('Content-Disposition: form-data'));
      expect(wire, isNot(contains('content-disposition:')));
    });

    test(
      'the declared Content-Length matches the bytes actually sent',
      () async {
        // A body shorter than its Content-Length is the one client-side defect
        // that would produce issue #15's edge-generated 502 on a request the
        // server never sees.
        final (:repo, :adapter) = uploader(const []);
        final file = tempPdf('invoice.pdf');

        await repo.uploadDocuments([(path: file.path, name: 'invoice.pdf')]);

        final declared = adapter.captured!.headers[Headers.contentLengthHeader];
        expect(int.parse('$declared'), adapter.body!.length);
      },
    );

    test('the upload gets its own timeouts, not the global 15s', () async {
      // Dio spends `sendTimeout` on the whole body in one go, so the global
      // budget is a cap on file size disguised as a network timeout: 7 MB up a
      // 3 Mbps link needs ~20s and used to surface as "server unreachable".
      final (:repo, :adapter) = uploader(const []);
      final file = tempPdf('invoice.pdf');

      await repo.uploadDocuments([(path: file.path, name: 'invoice.pdf')]);

      expect(adapter.captured!.sendTimeout, kUploadSendTimeout);
      expect(adapter.captured!.receiveTimeout, kUploadReceiveTimeout);
      expect(kUploadSendTimeout, greaterThan(const Duration(seconds: 15)));
    });
  });

  group('deletes', () {
    final deletes =
        <
          String,
          ({String path, Future<void> Function(VehiclesRepository) call})
        >{
          'gas': (
            path: Endpoints.gasRecordsDelete,
            call: (repo) => repo.deleteGasRecord(7),
          ),
          'service': (
            path: '${Endpoints.serviceRecords}/delete',
            call: (repo) => repo.deleteRecord(RecordKind.service, 7),
          ),
          'odometer': (
            path: Endpoints.odometerRecordsDelete,
            call: (repo) => repo.deleteOdometerRecord(7),
          ),
          'supply': (
            path: Endpoints.supplyRecordsDelete,
            call: (repo) => repo.deleteSupplyRecord(7),
          ),
          'plan': (
            path: Endpoints.planRecordsDelete,
            call: (repo) => repo.deletePlanRecord(7),
          ),
          'reminder': (
            path: Endpoints.remindersDelete,
            call: (repo) => repo.deleteReminder(7),
          ),
          'note': (
            path: Endpoints.notesDelete,
            call: (repo) => repo.deleteNote(7),
          ),
          'equipment': (
            path: Endpoints.equipmentRecordsDelete,
            call: (repo) => repo.deleteEquipmentRecord(7),
          ),
          'vehicle': (
            path: Endpoints.vehiclesDelete,
            call: (repo) => repo.deleteVehicle(7),
          ),
        };

    for (final entry in deletes.entries) {
      test('a ${entry.key} delete is DELETE ?id=', () async {
        final (:repo, :adapter) = _repo();

        await entry.value.call(repo);

        final request = _request(adapter);
        expect(request.method, 'DELETE');
        expect(request.path, entry.value.path);
        expect(request.uri.queryParameters, {'id': '7'});
      });
    }
  });

  group('the operation response', () {
    test('a 200 saying success:false is still a failure', () async {
      // LubeLogger reports most validation failures in-band with HTTP 200.
      final (:repo, adapter: _) = _repo(
        response: {'success': false, 'message': 'Input object invalid'},
      );

      await expectLater(
        repo.addNote(vehicleId: 3, description: 'x', noteText: 'y'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', AppErrorCode.badResponse)
              .having((e) => e.detail, 'detail', 'Input object invalid'),
        ),
      );
    });

    test('a response without a success field is accepted', () async {
      final (:repo, adapter: _) = _repo(response: const {});

      await expectLater(
        repo.addNote(vehicleId: 3, description: 'x', noteText: 'y'),
        completes,
      );
    });

    test('a 401 on delete is a permission problem, not a bad body', () async {
      // The api key's household may lack the Delete permission; the server says
      // 401 for that, and the app must not read it as a logout signal.
      final (:repo, adapter: _) = _repo(
        status: 401,
        response: {'success': false, 'message': 'Access Denied'},
      );

      await expectLater(
        repo.deleteVehicle(7),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.unauthorized,
          ),
        ),
      );
    });

    test('a 404 on vehicle delete reads as an old server', () async {
      // LubeLogger 1.6.9 has no /api/vehicles/delete route at all, so the
      // request 404s. The app supports both versions, and the difference has to
      // reach the user as "update your server", not as an HTTP code.
      final (:repo, adapter: _) = _repo(status: 404);

      await expectLater(
        repo.deleteVehicle(7),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.unsupportedByServer,
          ),
        ),
      );
    });

    test('a 404 elsewhere stays a plain bad response', () async {
      // Nothing else the app calls is version-gated, so a 404 there means a
      // wrong base URL — mislabelling it "old server" would send the user
      // upgrading a server that is fine.
      final (:repo, adapter: _) = _repo(status: 404);

      await expectLater(
        repo.deleteNote(7),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', AppErrorCode.badResponse)
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('a 400 surfaces as a bad response with its status', () async {
      final (:repo, adapter: _) = _repo(
        status: 400,
        response: {'success': false, 'message': 'Progress cannot be Done'},
      );

      await expectLater(
        repo.addPlanRecord(
          vehicleId: 3,
          description: 'x',
          cost: 1,
          type: PlanType.service,
          priority: PlanPriority.normal,
          progress: PlanProgress.done,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', AppErrorCode.badResponse)
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });
}
