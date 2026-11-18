import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_util/app_util.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exceptions.dart';
import '../core/api/endpoints.dart';
import '../core/cache/offline_interceptor.dart';
import '../core/auth/whoami.dart';
import '../core/models/attachment.dart';
import '../core/models/equipment_record.dart';
import '../core/models/extra_field.dart';
import '../core/models/gas_record.dart';
import '../core/models/note_record.dart';
import '../core/models/odometer_record.dart';
import '../core/models/plan_record.dart';
import '../core/models/reminder_record.dart';
import '../core/models/server_info.dart';
import '../core/models/server_version.dart';
import '../core/models/supply_record.dart';
import '../core/models/vehicle.dart';
import '../core/models/vehicle_info.dart';
import '../core/models/vehicle_record.dart';

/// Reads vehicles and their aggregated info. Shares the authenticated Dio from
/// [ApiClient]; rebuilt on profile change.
class VehiclesRepository {
  VehiclesRepository(this._dio);

  final Dio _dio;

  /// The same endpoints over a client that tells [probe] what the offline cache
  /// did with each request, optionally answering from the stored copy without
  /// asking the server at all.
  ///
  /// A flag on the client rather than an argument on forty methods — and inert
  /// wherever the cache isn't installed (tests, demo mode), where this is just
  /// another handle on the same Dio.
  VehiclesRepository withCache(
    CacheProbe probe, {
    bool cacheFirst = false,
    bool revalidate = false,
  }) => VehiclesRepository(
    _dio.clone(
      options: _dio.options.copyWith(
        extra: {
          ..._dio.options.extra,
          kCacheProbe: probe,
          if (cacheFirst) kCacheFirst: true,
          if (revalidate) kRevalidate: true,
        },
      ),
    ),
  );

  /// `GET /api/vehicles` → the household's vehicles.
  Future<List<Vehicle>> list() => guard(() async {
    final res = await _dio.get<List<dynamic>>(Endpoints.vehicles);
    return _parseVehicles(res.data);
  });

  /// `POST /api/vehicles/add` → create a vehicle, returning its new id (or null
  /// if the server omitted it). The app always uses the `LicensePlate`
  /// identifier, so [licensePlate] is required; [fuelType] must be one of
  /// `Gasoline`, `Diesel`, `Electric`. Values go out as strings, matching the
  /// server's string-parsed import model.
  Future<int?> addVehicle({
    required int year,
    required String make,
    required String model,
    required String licensePlate,
    required String fuelType,
    bool useHours = false,
    bool odometerOptional = false,
    String tags = '',
    List<ExtraField> extraFields = const [],
  }) => guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.vehiclesAdd,
      options: Options(contentType: Headers.jsonContentType),
      data: _vehicleBody(
        year: year,
        make: make,
        model: model,
        licensePlate: licensePlate,
        fuelType: fuelType,
        useHours: useHours,
        odometerOptional: odometerOptional,
        tags: tags,
        identifier: 'LicensePlate',
        extraFields: extraFields,
      ),
    );
    _ensureSuccess(res.data);
    final extra = res.data?['additionalData'];
    if (extra is Map) return (extra['vehicleId'] as num?)?.toInt();
    return null;
  });

  /// `PUT /api/vehicles/update` → update an existing vehicle by [id]. The server
  /// replaces the identifier and extra fields with what's sent, so pass the
  /// vehicle's existing [identifier]/[extraFields] to preserve them. [fuelType]
  /// must be one of `Gasoline`, `Diesel`, `Electric`.
  ///
  /// Server caveat: it only *sets* the diesel/electric flag and never clears it,
  /// so switching a vehicle back to Gasoline (or Diesel↔Electric) won't take
  /// effect server-side — nothing the client can do about it.
  Future<void> updateVehicle({
    required int id,
    required int year,
    required String make,
    required String model,
    required String licensePlate,
    required String fuelType,
    required String identifier,
    required List<ExtraField> extraFields,
    bool useHours = false,
    bool odometerOptional = false,
    String tags = '',
  }) => _update(Endpoints.vehiclesUpdate, {
    'id': id.toString(),
    ..._vehicleBody(
      year: year,
      make: make,
      model: model,
      licensePlate: licensePlate,
      fuelType: fuelType,
      useHours: useHours,
      odometerOptional: odometerOptional,
      tags: tags,
      identifier: identifier,
      extraFields: extraFields,
    ),
  });

  /// `DELETE /api/vehicles/delete?id=` → delete a vehicle (LubeLogger 1.7.0+).
  /// The server cascades, wiping all of the vehicle's records first, so this is
  /// irreversible. Surfaces [AppErrorCode.unauthorized] when the key's household
  /// lacks the `Delete` permission (the server answers 401, not a logout signal).
  ///
  /// 1.6.9 has no such route and answers 404, which reaches the user as an
  /// "update your server" message rather than a bare HTTP code. The UI checks
  /// the version first (`ServerCapabilities`) — this is the path taken when it
  /// couldn't, because `/api/info` hadn't been read.
  Future<void> deleteVehicle(int id) async {
    try {
      await _delete(Endpoints.vehiclesDelete, id);
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      throw const ApiException(
        AppErrorCode.unsupportedByServer,
        statusCode: 404,
      );
    }
  }

  /// `GET /api/vehicle/info?vehicleId=` → aggregated info for one vehicle. The
  /// endpoint returns an array; we take the first (and only) element.
  Future<VehicleInfo> info(int vehicleId) => guard(() async {
    final res = await _dio.get<List<dynamic>>(
      Endpoints.vehicleInfo,
      queryParameters: {'vehicleId': vehicleId},
    );
    final list = res.data ?? const [];
    if (list.isEmpty) {
      throw const ApiException(AppErrorCode.malformedResponse);
    }
    return VehicleInfo.fromJson(list.first as Map<String, dynamic>);
  });

  /// `GET /api/vehicle/info` with no `vehicleId` → the same aggregate for every
  /// vehicle the key may view. This is the garage in one request; [list] plus
  /// one [info] per vehicle would return the same thing in 1+N.
  Future<List<VehicleInfo>> allInfo() => guard(() async {
    final res = await _dio.get<List<dynamic>>(Endpoints.vehicleInfo);
    return parseJsonList(res.data, VehicleInfo.fromJson);
  });

  /// `GET /api/vehicle/gasrecords?vehicleId=` → the vehicle's refuel log.
  Future<List<GasRecord>> gasRecords(int vehicleId) => guard(() async {
    final res = await _dio.get<List<dynamic>>(
      Endpoints.gasRecords,
      queryParameters: {'vehicleId': vehicleId},
    );
    return parseJsonList(res.data, GasRecord.fromJson);
  });

  /// `POST /api/vehicle/gasrecords/add?vehicleId=` → add a refuel. Decimals go
  /// out as JSON numbers, the rest as strings (see the note above `_gasRecordBody`).
  /// Throws [ApiException] when the server reports `success: false`.
  Future<void> addGasRecord({
    required int vehicleId,
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    int startingSoc = GasRecord.defaultStartingSoc,
    int endingSoc = GasRecord.defaultEndingSoc,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.gasRecordsAdd,
      queryParameters: {'vehicleId': vehicleId},
      options: Options(contentType: Headers.jsonContentType),
      data: _gasRecordBody(
        date: date,
        odometer: odometer,
        fuelConsumed: fuelConsumed,
        cost: cost,
        isFillToFull: isFillToFull,
        missedFuelUp: missedFuelUp,
        startingSoc: startingSoc,
        endingSoc: endingSoc,
        notes: notes,
        tags: tags,
        files: files,
        extraFields: extraFields,
      ),
    );
    _ensureSuccess(res.data);
  });

  /// `PUT /api/vehicle/gasrecords/update` → update an existing refuel by [id].
  /// No query params; `id` and `vehicleId` travel in the body (the server looks
  /// up the record's own vehicle, but the export model still expects the
  /// field).
  Future<void> updateGasRecord({
    required int vehicleId,
    required int id,
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    int startingSoc = GasRecord.defaultStartingSoc,
    int endingSoc = GasRecord.defaultEndingSoc,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => guard(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      Endpoints.gasRecordsUpdate,
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'id': id.toString(),
        'vehicleId': vehicleId.toString(),
        ..._gasRecordBody(
          date: date,
          odometer: odometer,
          fuelConsumed: fuelConsumed,
          cost: cost,
          isFillToFull: isFillToFull,
          missedFuelUp: missedFuelUp,
          startingSoc: startingSoc,
          endingSoc: endingSoc,
          notes: notes,
          tags: tags,
          files: files,
          extraFields: extraFields,
        ),
      },
    );
    _ensureSuccess(res.data);
  });

  /// `DELETE /api/vehicle/gasrecords/delete?id=` → delete a refuel.
  Future<void> deleteGasRecord(int id) => guard(() async {
    final res = await _dio.delete<Map<String, dynamic>>(
      Endpoints.gasRecordsDelete,
      queryParameters: {'id': id},
    );
    _ensureSuccess(res.data);
  });

  /// Full records for one vehicle from a generic (date + cost) record [kind]
  /// (service / repair / upgrade / tax) — the source for the per-type record
  /// tables and, trimmed to date + cost, for the monthly expense chart.
  Future<List<VehicleRecord>> records(RecordKind kind, int vehicleId) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          kind.endpoint,
          queryParameters: {'vehicleId': vehicleId},
        );
        return parseJsonList(res.data, VehicleRecord.fromJson);
      });

  /// `POST {kind}/add?vehicleId=` → add a generic (service / repair / upgrade /
  /// tax) record. The server requires date, description and cost — plus
  /// odometer for the odometer-bearing kinds; pass [odometer] as null for tax so
  /// it's omitted. Odometer goes out as a whole-number string for the server's
  /// `int.Parse`, cost as a JSON number (see the note above `_gasRecordBody`).
  Future<void> addRecord({
    required RecordKind kind,
    required int vehicleId,
    required DateTime date,
    required String description,
    required num cost,
    num? odometer,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      kind.addEndpoint,
      queryParameters: {'vehicleId': vehicleId},
      options: Options(contentType: Headers.jsonContentType),
      data: _recordBody(
        date: date,
        description: description,
        cost: cost,
        odometer: odometer,
        notes: notes,
        tags: tags,
        files: files,
        extraFields: extraFields,
      ),
    );
    _ensureSuccess(res.data);
  });

  /// `PUT {kind}/update` → update a generic record by [id]. No query params; the
  /// server resolves the record's vehicle from [id], so `vehicleId` isn't sent.
  Future<void> updateRecord({
    required RecordKind kind,
    required int id,
    required DateTime date,
    required String description,
    required num cost,
    num? odometer,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => guard(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      kind.updateEndpoint,
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'id': id.toString(),
        ..._recordBody(
          date: date,
          description: description,
          cost: cost,
          odometer: odometer,
          notes: notes,
          tags: tags,
          files: files,
          extraFields: extraFields,
        ),
      },
    );
    _ensureSuccess(res.data);
  });

  /// `DELETE {kind}/delete?id=` → delete a generic record.
  Future<void> deleteRecord(RecordKind kind, int id) => guard(() async {
    final res = await _dio.delete<Map<String, dynamic>>(
      kind.deleteEndpoint,
      queryParameters: {'id': id},
    );
    _ensureSuccess(res.data);
  });

  // ── Supply records ──────────────────────────────────────────────────────
  // Server requires date, description, quantity and cost; part number/supplier
  // are optional. Quantity and cost are decimals.
  Future<void> addSupplyRecord({
    required int vehicleId,
    required DateTime date,
    required String description,
    required num partQuantity,
    required num cost,
    String partNumber = '',
    String partSupplier = '',
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _add(
    Endpoints.supplyRecordsAdd,
    vehicleId,
    _supplyBody(
      date,
      description,
      partQuantity,
      cost,
      partNumber,
      partSupplier,
      notes,
      tags,
      files,
      extraFields,
    ),
  );

  Future<void> updateSupplyRecord({
    required int id,
    required DateTime date,
    required String description,
    required num partQuantity,
    required num cost,
    String partNumber = '',
    String partSupplier = '',
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _update(Endpoints.supplyRecordsUpdate, {
    'id': id.toString(),
    ..._supplyBody(
      date,
      description,
      partQuantity,
      cost,
      partNumber,
      partSupplier,
      notes,
      tags,
      files,
      extraFields,
    ),
  });

  Future<void> deleteSupplyRecord(int id) =>
      _delete(Endpoints.supplyRecordsDelete, id);

  // ── Plan (planner) records ──────────────────────────────────────────────
  // Server requires description, cost, type, priority and progress; there is no
  // date/odometer/tags. The API refuses to set Progress.done (see PlanProgress).
  Future<void> addPlanRecord({
    required int vehicleId,
    required String description,
    required num cost,
    required PlanType type,
    required PlanPriority priority,
    required PlanProgress progress,
    String notes = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _add(
    Endpoints.planRecordsAdd,
    vehicleId,
    _planBody(
      description,
      cost,
      type,
      priority,
      progress,
      notes,
      files,
      extraFields,
    ),
  );

  Future<void> updatePlanRecord({
    required int id,
    required String description,
    required num cost,
    required PlanType type,
    required PlanPriority priority,
    required PlanProgress progress,
    String notes = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _update(Endpoints.planRecordsUpdate, {
    'id': id.toString(),
    ..._planBody(
      description,
      cost,
      type,
      priority,
      progress,
      notes,
      files,
      extraFields,
    ),
  });

  Future<void> deletePlanRecord(int id) =>
      _delete(Endpoints.planRecordsDelete, id);

  // ── Reminders ───────────────────────────────────────────────────────────
  // Server requires description and metric; the due date and/or odometer are
  // required per the metric (date → dueDate, odometer → dueOdometer, both →
  // both). Urgency is computed server-side, never sent.
  Future<void> addReminder({
    required int vehicleId,
    required String description,
    required ReminderMetric metric,
    DateTime? dueDate,
    num? dueOdometer,
    String notes = '',
    String tags = '',
  }) => _add(
    Endpoints.remindersAdd,
    vehicleId,
    _reminderBody(description, metric, dueDate, dueOdometer, notes, tags),
  );

  Future<void> updateReminder({
    required int id,
    required String description,
    required ReminderMetric metric,
    DateTime? dueDate,
    num? dueOdometer,
    String notes = '',
    String tags = '',
  }) => _update(Endpoints.remindersUpdate, {
    'id': id.toString(),
    ..._reminderBody(description, metric, dueDate, dueOdometer, notes, tags),
  });

  Future<void> deleteReminder(int id) => _delete(Endpoints.remindersDelete, id);

  // ── Notes ───────────────────────────────────────────────────────────────
  // Server requires description (title) and noteText (body).
  Future<void> addNote({
    required int vehicleId,
    required String description,
    required String noteText,
    bool pinned = false,
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _add(
    Endpoints.notesAdd,
    vehicleId,
    _noteBody(description, noteText, pinned, tags, files, extraFields),
  );

  Future<void> updateNote({
    required int id,
    required String description,
    required String noteText,
    bool pinned = false,
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _update(Endpoints.notesUpdate, {
    'id': id.toString(),
    ..._noteBody(description, noteText, pinned, tags, files, extraFields),
  });

  Future<void> deleteNote(int id) => _delete(Endpoints.notesDelete, id);

  // ── Equipment ───────────────────────────────────────────────────────────
  // Server requires description and isEquipped.
  Future<void> addEquipmentRecord({
    required int vehicleId,
    required String description,
    required bool isEquipped,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _add(
    Endpoints.equipmentRecordsAdd,
    vehicleId,
    _equipmentBody(description, isEquipped, notes, tags, files, extraFields),
  );

  Future<void> updateEquipmentRecord({
    required int id,
    required String description,
    required bool isEquipped,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => _update(Endpoints.equipmentRecordsUpdate, {
    'id': id.toString(),
    ..._equipmentBody(description, isEquipped, notes, tags, files, extraFields),
  });

  Future<void> deleteEquipmentRecord(int id) =>
      _delete(Endpoints.equipmentRecordsDelete, id);

  /// `GET /api/vehicle/odometerrecords?vehicleId=` → odometer readings, source
  /// of the monthly distance line.
  Future<List<OdometerRecord>> odometerRecords(int vehicleId) =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(
          Endpoints.odometerRecords,
          queryParameters: {'vehicleId': vehicleId},
        );
        return parseJsonList(res.data, OdometerRecord.fromJson);
      });

  /// `POST /api/vehicle/odometerrecords/add?vehicleId=` → add an odometer
  /// reading. `initialOdometer` is omitted so the server defaults it to the
  /// previous reading. Values go out as integer strings (the server
  /// `int.Parse`s them).
  Future<void> addOdometerRecord({
    required int vehicleId,
    required DateTime date,
    required num odometer,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
  }) => guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.odometerRecordsAdd,
      queryParameters: {'vehicleId': vehicleId},
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'date': calendarDateToJson(date),
        'odometer': _intString(odometer),
        'notes': notes,
        'tags': tags,
        'files': _filesJson(files),
        'extraFields': ExtraField.jsonList(extraFields),
      },
    );
    _ensureSuccess(res.data);
  });

  /// `PUT /api/vehicle/odometerrecords/update` → update a reading by [id]. The
  /// endpoint requires [initialOdometer], so callers pass the value read back
  /// from the record to preserve it. [equipmentRecordId] likewise: the server
  /// replaces the reading's equipment link with whatever arrives.
  Future<void> updateOdometerRecord({
    required int id,
    required DateTime date,
    required num odometer,
    required num initialOdometer,
    String notes = '',
    String tags = '',
    List<Attachment> files = const [],
    List<ExtraField> extraFields = const [],
    String equipmentRecordId = '',
  }) => guard(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      Endpoints.odometerRecordsUpdate,
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'id': id.toString(),
        'date': calendarDateToJson(date),
        'odometer': _intString(odometer),
        'initialOdometer': _intString(initialOdometer),
        'notes': notes,
        'tags': tags,
        'files': _filesJson(files),
        'extraFields': ExtraField.jsonList(extraFields),
        'equipmentRecordId': equipmentRecordId,
      },
    );
    _ensureSuccess(res.data);
  });

  /// `DELETE /api/vehicle/odometerrecords/delete?id=` → delete a reading.
  Future<void> deleteOdometerRecord(int id) => guard(() async {
    final res = await _dio.delete<Map<String, dynamic>>(
      Endpoints.odometerRecordsDelete,
      queryParameters: {'id': id},
    );
    _ensureSuccess(res.data);
  });

  /// `GET /api/vehicle/supplyrecords?vehicleId=` → supply / part records.
  Future<List<SupplyRecord>> supplyRecords(int vehicleId) =>
      _list(Endpoints.supplyRecords, vehicleId, SupplyRecord.fromJson);

  /// `GET /api/vehicle/planrecords?vehicleId=` → planner items.
  Future<List<PlanRecord>> planRecords(int vehicleId) =>
      _list(Endpoints.planRecords, vehicleId, PlanRecord.fromJson);

  /// `GET /api/vehicle/reminders?vehicleId=` → reminders (with computed urgency).
  Future<List<ReminderRecord>> reminders(int vehicleId) =>
      _list(Endpoints.reminders, vehicleId, ReminderRecord.fromJson);

  /// `GET /api/vehicle/notes?vehicleId=` → free-text notes.
  Future<List<NoteRecord>> notes(int vehicleId) =>
      _list(Endpoints.notes, vehicleId, NoteRecord.fromJson);

  /// `GET /api/vehicle/equipmentrecords?vehicleId=` → equipment items.
  Future<List<EquipmentRecord>> equipmentRecords(int vehicleId) =>
      _list(Endpoints.equipmentRecords, vehicleId, EquipmentRecord.fromJson);

  /// Fetch and parse a `?vehicleId=` list endpoint into typed records, skipping
  /// any element that isn't a JSON object.
  Future<List<T>> _list<T>(
    String endpoint,
    int vehicleId,
    T Function(Map<String, dynamic>) fromJson,
  ) => guard(() async {
    final res = await _dio.get<List<dynamic>>(
      endpoint,
      queryParameters: {'vehicleId': vehicleId},
    );
    return parseJsonList(res.data, fromJson);
  });

  /// `POST {endpoint}?vehicleId=` with a JSON [body] → add a record. Shared by
  /// the per-type add methods (all uniform-CRUD endpoints, see §6).
  Future<void> _add(
    String endpoint,
    int vehicleId,
    Map<String, dynamic> body,
  ) => guard(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'vehicleId': vehicleId},
      options: Options(contentType: Headers.jsonContentType),
      data: body,
    );
    _ensureSuccess(res.data);
  });

  /// `PUT {endpoint}` with a JSON [body] (including `id`) → update a record. The
  /// server resolves the record's vehicle from its id, so no query params.
  Future<void> _update(String endpoint, Map<String, dynamic> body) =>
      guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          endpoint,
          options: Options(contentType: Headers.jsonContentType),
          data: body,
        );
        _ensureSuccess(res.data);
      });

  /// `DELETE {endpoint}?id=` → delete a record by [id].
  Future<void> _delete(String endpoint, int id) => guard(() async {
    final res = await _dio.delete<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'id': id},
    );
    _ensureSuccess(res.data);
  });

  /// `POST /api/documents/upload` (multipart, field `documents`) → upload one or
  /// more files and return the resulting [Attachment]s, which the caller stores
  /// in a record's `files` list on add/update.
  Future<List<Attachment>> uploadDocuments(
    List<({String path, String name})> files,
  ) => guard(() async {
    // Camel case because the lowercase spelling is what some proxies in
    // front of LubeLogger fail to parse; both are legal per RFC 7578.
    final form = FormData(camelCaseContentDisposition: true);
    for (final f in files) {
      form.files.add(
        MapEntry(
          'documents',
          await MultipartFile.fromFile(f.path, filename: f.name),
        ),
      );
    }
    final res = await _dio.post<List<dynamic>>(
      Endpoints.documentsUpload,
      data: form,
      options: Options(
        sendTimeout: kUploadSendTimeout,
        receiveTimeout: kUploadReceiveTimeout,
      ),
    );
    return parseJsonList(res.data, Attachment.fromJson);
  });

  /// Download an attachment to [savePath]. [location] is a record's
  /// `files[].location` (e.g. `/documents/<guid>.pdf`), resolved against the
  /// server base URL; the authenticated client's `x-api-key` is accepted for
  /// `/documents` paths (see the server's static-file auth).
  Future<void> downloadDocument(String location, String savePath) =>
      guard(() async {
        await _dio.download(location, savePath);
      });

  /// `GET /api/info` → server metadata (currency, locale, date format).
  Future<ServerInfo> serverInfo() => guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.info);
    return ServerInfo.fromJson(res.data ?? const {});
  });

  /// `GET /api/extrafields` → the household's custom-field template per record
  /// type. Types with nothing configured are absent from the response, so a
  /// missing key means "no custom fields", not "unknown".
  Future<Map<ExtraFieldRecordType, List<ExtraField>>> extraFieldTemplates() =>
      guard(() async {
        final res = await _dio.get<List<dynamic>>(Endpoints.extraFields);
        final templates = <ExtraFieldRecordType, List<ExtraField>>{};
        for (final entry in res.data ?? const []) {
          if (entry is! Map<String, dynamic>) continue;
          final type = ExtraFieldRecordType.parse(entry['recordType']);
          if (type == null) continue;
          templates[type] = ExtraField.listFrom(entry['extraFields']);
        }
        return templates;
      });

  /// `GET /api/whoami` → the authenticated account (username, email, roles).
  Future<WhoAmI> whoAmI() => guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.whoami);
    final me = WhoAmI.fromJson(res.data ?? const {});
    // The privilege level only, never who it belongs to — which is also why
    // this endpoint is the one the HTTP probe refuses to sample. LubeLogger
    // answers 401 both for a bad key and for a valid key without the scope,
    // so the account's rank is what separates "the app is broken" from "this
    // account may not do that", and it is the difference between a report
    // about a missing button and a report about a missing permission.
    DiagnosticRecorder.active?.add(
      LogSource.http,
      'account',
      fields: {
        'role': me.isRoot
            ? 'root'
            : me.isAdmin
            ? 'admin'
            : 'user',
      },
    );
    return me;
  });

  /// `GET /api/version?checkForUpdate=1` → running vs. latest release version.
  Future<ServerVersion> serverVersion() => guard(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      Endpoints.version,
      queryParameters: {'checkForUpdate': true},
    );
    return ServerVersion.fromJson(res.data ?? const {});
  });

  /// `GET /api/makebackup` → trigger a server-side backup (root only), returning
  /// the created file's path. Throws (403) for non-root callers.
  Future<String> makeBackup() => guard(() async {
    final res = await _dio.get<String>(Endpoints.makeBackup);
    return res.data ?? '';
  });

  List<Vehicle> _parseVehicles(List<dynamic>? data) =>
      parseJsonList(data, Vehicle.fromJson);

  // Decimals as JSON numbers: `cost`, `fuelConsumed` and `partQuantity` are
  // string properties the server reads with `decimal.Parse` under ITS culture,
  // and `culture-invariant` only governs responses. A "174.9" string is 1749 on a
  // server set to de-DE or pl-PL (the `.` is a thousands separator there). A JSON
  // number is turned into text and parsed back by the same culture, so it
  // survives any locale (docs.lubelogger.com: "Post bodies in JSON if you wish to
  // pass in numbers"). Held by test/contract on 1.6.9 to latest, default and de-DE.
  /// Shared field set for a gas record write (add or update). Decimals are JSON
  /// numbers (see the note above `_gasRecordBody`); everything else a string, per the
  /// server's string-parsed export model.
  ///
  /// `startingSoc`/`endingSoc` are always sent, never left empty: before
  /// LubeLogger 1.7.0 the server `int.Parse`d them with no guard, so an absent
  /// field threw a 500 ("input string '' was not in a correct format").
  static Map<String, dynamic> _gasRecordBody({
    required DateTime date,
    required num odometer,
    required num fuelConsumed,
    required num cost,
    required bool isFillToFull,
    required bool missedFuelUp,
    required int startingSoc,
    required int endingSoc,
    required String notes,
    required String tags,
    required List<Attachment> files,
    required List<ExtraField> extraFields,
  }) => {
    'date': calendarDateToJson(date),
    'odometer': _intString(odometer),
    'fuelConsumed': fuelConsumed,
    'cost': cost,
    'isFillToFull': isFillToFull.toString(),
    'missedFuelUp': missedFuelUp.toString(),
    'startingSoc': startingSoc.toString(),
    'endingSoc': endingSoc.toString(),
    'notes': notes,
    'tags': tags,
    'files': _filesJson(files),
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Shared field set for a generic record write (add or update). Odometer is
  /// omitted when null (tax records have none); it goes out as a whole-number
  /// string for the server's `int.Parse`, cost as a JSON number.
  static Map<String, dynamic> _recordBody({
    required DateTime date,
    required String description,
    required num cost,
    required num? odometer,
    required String notes,
    required String tags,
    required List<Attachment> files,
    required List<ExtraField> extraFields,
  }) => {
    'date': calendarDateToJson(date),
    if (odometer != null) 'odometer': _intString(odometer),
    'description': description,
    'cost': cost,
    'notes': notes,
    'tags': tags,
    'files': _filesJson(files),
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Supply write fields. Quantity and cost are decimals; part number/supplier
  /// are free-form and may be empty.
  static Map<String, dynamic> _supplyBody(
    DateTime date,
    String description,
    num partQuantity,
    num cost,
    String partNumber,
    String partSupplier,
    String notes,
    String tags,
    List<Attachment> files,
    List<ExtraField> extraFields,
  ) => {
    'date': calendarDateToJson(date),
    'description': description,
    'partNumber': partNumber,
    'partSupplier': partSupplier,
    'partQuantity': partQuantity,
    'cost': cost,
    'notes': notes,
    'tags': tags,
    'files': _filesJson(files),
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Plan write fields. Enums go out as their .NET names; there is no
  /// date/odometer/tags. The server sets DateCreated/DateModified itself.
  static Map<String, dynamic> _planBody(
    String description,
    num cost,
    PlanType type,
    PlanPriority priority,
    PlanProgress progress,
    String notes,
    List<Attachment> files,
    List<ExtraField> extraFields,
  ) => {
    'description': description,
    'cost': cost,
    'type': type.wireName,
    'priority': priority.wireName,
    'progress': progress.wireName,
    'notes': notes,
    'files': _filesJson(files),
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Reminder write fields. Metric goes out as its .NET name; the due date and
  /// odometer are sent only when set (the caller supplies whichever the metric
  /// requires). Urgency is computed server-side and never sent.
  static Map<String, String> _reminderBody(
    String description,
    ReminderMetric metric,
    DateTime? dueDate,
    num? dueOdometer,
    String notes,
    String tags,
  ) => {
    'description': description,
    'metric': metric.wireName,
    if (dueDate != null) 'dueDate': calendarDateToJson(dueDate),
    if (dueOdometer != null) 'dueOdometer': _intString(dueOdometer),
    'notes': notes,
    'tags': tags,
  };

  /// Note write fields: a title ([description]) + body ([noteText]) + pin flag.
  static Map<String, dynamic> _noteBody(
    String description,
    String noteText,
    bool pinned,
    String tags,
    List<Attachment> files,
    List<ExtraField> extraFields,
  ) => {
    'description': description,
    'noteText': noteText,
    'pinned': pinned.toString(),
    'tags': tags,
    'files': _filesJson(files),
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Equipment write fields: a name ([description]) + equipped flag.
  static Map<String, dynamic> _equipmentBody(
    String description,
    bool isEquipped,
    String notes,
    String tags,
    List<Attachment> files,
    List<ExtraField> extraFields,
  ) => {
    'description': description,
    'isEquipped': isEquipped.toString(),
    'notes': notes,
    'tags': tags,
    'files': _filesJson(files),
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Shared field set for a vehicle write (add or update). All values go out as
  /// strings (bools as "true"/"false", which the server's `bool.Parse` accepts),
  /// matching the string-parsed `VehicleImportModel`.
  static Map<String, dynamic> _vehicleBody({
    required int year,
    required String make,
    required String model,
    required String licensePlate,
    required String fuelType,
    required bool useHours,
    required bool odometerOptional,
    required String tags,
    required String identifier,
    required List<ExtraField> extraFields,
  }) => {
    'year': year.toString(),
    'make': make,
    'model': model,
    'licensePlate': licensePlate,
    'identifier': identifier,
    'fuelType': fuelType,
    'useEngineHours': useHours.toString(),
    'odometerOptional': odometerOptional.toString(),
    'tags': tags,
    'extraFields': ExtraField.jsonList(extraFields),
  };

  /// Serialize a record's attachments for a write body's `files` field.
  static List<Map<String, dynamic>> _filesJson(List<Attachment> files) => [
    for (final f in files) f.toJson(),
  ];

  /// Odometer values are stored as integers server-side (`int.Parse`); emit a
  /// whole-number string so a `317240.0`-style double never reaches the parser.
  static String _intString(num value) => value.round().toString();

  /// A write's `OperationResponse` reports failure in-band with HTTP 200
  /// (`{success:false, message}`); surface it as an [ApiException].
  static void _ensureSuccess(Map<String, dynamic>? body) {
    if (body != null && body['success'] == false) {
      throw ApiException(
        AppErrorCode.badResponse,
        detail: body['message'] as String?,
      );
    }
  }
}
