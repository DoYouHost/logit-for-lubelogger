/// LubeLogger REST API endpoints in one place.
///
/// Contract: LubeLogger (CarCareTracker) `x-api-key` API, verified against a
/// live v1.6.9 instance + the server source (`reference/lubelog`). All paths
/// are under `/api` on the server root (no version prefix). See
/// docs/api-records.md and docs/api-server.md for the contract, including the
/// `culture-invariant` header requirement and the overloaded-401 behaviour.
abstract final class Endpoints {
  static const apiPrefix = '/api';

  /// Upload attachments: `POST` multipart form-data, field `documents` (one or
  /// more files). Returns an array of `UploadedFiles` (`{name, location,
  /// isPending}`) to attach to a record's `files` on add/update.
  static const documentsUpload = '$apiPrefix/documents/upload';

  /// Identity of the authenticated caller: `{username, emailAddress, isAdmin,
  /// isRoot}`. Cheapest authenticated read — used to validate credentials on
  /// the login screen.
  static const whoami = '$apiPrefix/whoami';

  /// Server info: `{currentVersion, locale, currencySymbol, decimalSeparator,
  /// dateFormat}`. No auth-sensitive data; useful for a version/locale banner.
  static const info = '$apiPrefix/info';

  /// Custom-field templates, one entry per record type:
  /// `[{recordType, extraFields:[{name, isRequired, fieldType}]}]`. `recordType`
  /// is the server's `ImportMode` name and `fieldType` the `ExtraFieldType`
  /// **name** — records themselves report `fieldType` as the enum's integer
  /// (see [ExtraField]). Types with no fields configured are omitted entirely.
  static const extraFields = '$apiPrefix/extrafields';

  /// Server version: `{currentVersion, latestVersion}`. Pass `?checkForUpdate=1`
  /// to have the server fetch the latest release tag from GitHub (otherwise
  /// latest == current). Works with the api key.
  static const version = '$apiPrefix/version';

  /// Create a server-side backup: `GET` (root only). Without params returns the
  /// backup file path as a JSON string; `?output=download` streams the zip.
  static const makeBackup = '$apiPrefix/makebackup';

  /// Household vehicles (array of [Vehicle]).
  static const vehicles = '$apiPrefix/vehicles';

  /// Add a vehicle: `POST /api/vehicles/add` + JSON `VehicleImportModel`. The
  /// server requires year, make, model, an identifier and a fuel type
  /// (`Gasoline`/`Diesel`/`Electric`); the app always uses the `LicensePlate`
  /// identifier, so a license plate is required too. Returns an
  /// `OperationResponse` with `additionalData:{vehicleId}`.
  static const vehiclesAdd = '$vehicles/add';

  /// Update a vehicle: `PUT /api/vehicles/update` + JSON `VehicleImportModel`
  /// including `id`. Same required fields as add; the server **replaces** the
  /// vehicle's identifier and extra fields with whatever is sent, so callers
  /// resend the existing values to avoid clobbering them.
  static const vehiclesUpdate = '$vehicles/update';

  /// Delete a vehicle: `DELETE /api/vehicles/delete?id=` (LubeLogger 1.7.0+).
  /// Cascades — the server deletes every record type for the vehicle before
  /// removing it, so this is irreversible. Requires the api key's household to
  /// hold the `Delete` permission; a key without it gets a 401.
  static const vehiclesDelete = '$vehicles/delete';

  /// Aggregated info for one vehicle: `?vehicleId=`. Returns an ARRAY of
  /// VehicleInfo (odometer, record counts/costs, reminder counts) — one element
  /// even for a single vehicle.
  static const vehicleInfo = '$apiPrefix/vehicle/info';

  /// Refuel log for one vehicle: `?vehicleId=`. Returns an array of gas records.
  /// The server's per-record `fuelEconomy` is ignored (see [GasRecord]); the
  /// app recomputes economy locally from odometer + fuel.
  static const gasRecords = '$apiPrefix/vehicle/gasrecords';

  /// Add a refuel: `POST ?vehicleId=` + JSON body. Returns an
  /// `OperationResponse` (`{success, message, additionalData:{recordId}}`).
  static const gasRecordsAdd = '$gasRecords/add';

  /// Update a refuel: `PUT` + JSON body including `id`. No query params.
  static const gasRecordsUpdate = '$gasRecords/update';

  /// Delete a refuel: `DELETE ?id=`.
  static const gasRecordsDelete = '$gasRecords/delete';

  // Record types with a date + cost, aggregated into the monthly expense chart.
  static const serviceRecords = '$apiPrefix/vehicle/servicerecords';
  static const repairRecords = '$apiPrefix/vehicle/repairrecords';
  static const upgradeRecords = '$apiPrefix/vehicle/upgraderecords';
  static const taxRecords = '$apiPrefix/vehicle/taxrecords';

  /// Odometer readings: `?vehicleId=`. Source of the monthly distance line.
  static const odometerRecords = '$apiPrefix/vehicle/odometerrecords';

  /// Add an odometer reading: `POST ?vehicleId=` + JSON body. Requires
  /// `date` + `odometer`; omitting `initialOdometer` lets the server default it
  /// to the previous reading.
  static const odometerRecordsAdd = '$odometerRecords/add';

  /// Update an odometer reading: `PUT` + JSON body including `id`. Requires
  /// `id, date, initialOdometer, odometer` (all non-empty).
  static const odometerRecordsUpdate = '$odometerRecords/update';

  /// Delete an odometer reading: `DELETE ?id=`.
  static const odometerRecordsDelete = '$odometerRecords/delete';

  // Additional record types with their own shapes. Each is a uniform-CRUD list
  // endpoint under `/api/vehicle/` (POST `/add?vehicleId=`, PUT `/update`,
  // DELETE `/delete?id=`); see docs/api-records.md.
  static const supplyRecords = '$apiPrefix/vehicle/supplyrecords';
  static const supplyRecordsAdd = '$supplyRecords/add';
  static const supplyRecordsUpdate = '$supplyRecords/update';
  static const supplyRecordsDelete = '$supplyRecords/delete';

  static const planRecords = '$apiPrefix/vehicle/planrecords';
  static const planRecordsAdd = '$planRecords/add';
  static const planRecordsUpdate = '$planRecords/update';
  static const planRecordsDelete = '$planRecords/delete';

  /// Reminders: `?vehicleId=&tags=&urgencies=` (no date range, unlike the
  /// cost records). The read model adds computed `dueDays`/`dueDistance`.
  static const reminders = '$apiPrefix/vehicle/reminders';
  static const remindersAdd = '$reminders/add';
  static const remindersUpdate = '$reminders/update';
  static const remindersDelete = '$reminders/delete';

  /// Notes: `?vehicleId=&tags=` only. No date/cost; carry a title + body.
  static const notes = '$apiPrefix/vehicle/notes';
  static const notesAdd = '$notes/add';
  static const notesUpdate = '$notes/update';
  static const notesDelete = '$notes/delete';

  /// Equipment: `?vehicleId=&tags=` only. Read model adds `distanceTraveled`.
  static const equipmentRecords = '$apiPrefix/vehicle/equipmentrecords';
  static const equipmentRecordsAdd = '$equipmentRecords/add';
  static const equipmentRecordsUpdate = '$equipmentRecords/update';
  static const equipmentRecordsDelete = '$equipmentRecords/delete';
}
