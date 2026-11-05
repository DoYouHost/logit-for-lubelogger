# LubeLogger API: records

How the app reads and writes LubeLogger record types over the REST API: wire format, required fields, write constraints, attachments, and the supply-requisition gap.
Read it before adding or changing a record form, a record model, or anything in [vehicles_repository.dart](../lib/data/vehicles_repository.dart).

Server facts below come from the upstream LubeLogger source (`Controllers/API/*Controller.cs`, `Models/Shared/ImportModel.cs`, tags 1.6.9 and 1.7.0) unless marked **observed**, meaning seen on a live server and not derivable from the source. Server-side routes are identical on 1.6.9 and 1.7.0 except `DELETE /api/vehicles/delete` (see [api-server.md](api-server.md)).

## Record types and routes

Eleven record types share one CRUD shape under `/api/vehicle/<type>`: `servicerecords`, `repairrecords`, `upgraderecords`, `taxrecords`, `gasrecords`, `odometerrecords`, `supplyrecords`, `planrecords`, `reminders`, `notes`, `equipmentrecords`.
All are wired in [endpoints.dart](../lib/core/api/endpoints.dart) and editable in the app.

| Operation | Route | Notes |
|---|---|---|
| list | `GET <type>?vehicleId=` | reminders also take `urgencies`, notes and equipment have no date range |
| add | `POST <type>/add?vehicleId=` + JSON | success returns `additionalData.recordId` |
| update | `PUT <type>/update` + JSON incl. `id` | no query params |
| delete | `DELETE <type>/delete?id=` | needs the `Delete` key scope |

- **Inspections have a server model but no API controller.** The web UI has them; the API does not, so an `x-api-key` client cannot read or write them. The app has no tab for them, and none can be built.
- Failures come back as `OperationResponse` `{success:false, message}`. Most validation failures carry HTTP 400, but some validation branches return **HTTP 200 with `success:false`** (for example reminder metric/due-date checks in `ReminderController`). The repository's `_ensureSuccess` therefore checks the body, not just the status. Keep every write behind it.

## Wire format

| Aspect | Rule | Where it lives |
|---|---|---|
| `culture-invariant: true` header | Always sent. Makes reads typed JSON with ISO dates (`"cost":381.67`, `"date":"2026-04-05"`). Without it the server emits locale-formatted strings. | [api_client.dart](../lib/core/api/api_client.dart) |
| Dates | ISO on read, parsed with the shared calendar-date helpers. **Observed** that this also holds for controllers that build the string with `ToShortDateString()` (service, plan, reminder, supply). | models in [../lib/core/models/](../lib/core/models/) |
| Enums | Arrive as .NET **names** (strings): `PlanPriority` Critical/Normal/Low, `PlanProgress` Backlog/InProgress/Testing/Done, `ReminderUrgency` NotUrgent/Urgent/VeryUrgent/PastDue, `ReminderMetric` Date/Odometer/Both. Source confirms `.ToString()` on the enum. Parse by lowercased name, accept the integer index defensively. | [plan_record.dart](../lib/core/models/plan_record.dart), [reminder_record.dart](../lib/core/models/reminder_record.dart) |
| Booleans | **Observed** as `"True"`/`"False"` strings for some fields (`isEquipped`, `pinned`) and real booleans for others. Parse tolerantly (`toBoolOrFalse`), never `== true`. | [equipment_record.dart](../lib/core/models/equipment_record.dart), [note_record.dart](../lib/core/models/note_record.dart) |
| Decimals under `culture-invariant` | Arrive as JSON **numbers**, not strings. A `json['partQuantity'] as String?` cast is always null; supply quantity is parsed tolerantly. | [supply_record.dart](../lib/core/models/supply_record.dart) |
| Write bodies | The server's export models are string-typed and parsed with `int.Parse` / `decimal.Parse` / `bool.Parse` / `DateTime.Parse`. Send strings: odometer as a whole-number string, cost and quantity as plain `.`-decimals, dates as ISO, bools as `"true"`/`"false"`. | `_recordBody`, `_intString` in [vehicles_repository.dart](../lib/data/vehicles_repository.dart) |
| Write bodies are `Map<String, dynamic>` | `files` and `extraFields` are JSON arrays, not strings. | same file |

## Required fields on add / update

Server `IsNullOrWhiteSpace` checks. Update additionally requires `id` everywhere.

| Type | Required |
|---|---|
| service, repair, upgrade | date, description, **odometer**, cost |
| tax | date, description, cost (no odometer) |
| gas | date, odometer, fuelConsumed, cost, isFillToFull, missedFuelUp |
| odometer | add: date, odometer. update: date, odometer, **initialOdometer** |
| supply | date, description, partQuantity, cost |
| plan | description, cost, type, priority, progress |
| reminder | description, metric, plus `dueDate` and/or `dueOdometer` as the metric demands |
| note | description, noteText |
| equipment | description, isEquipped |

## Write constraints by type

- **Reminders have no recurrence over the API.** The web UI has recurring reminders, but the write model (`ReminderExportModel`) carries only description, urgency, metric, notes, dueDate, dueOdometer and tags. Urgency is computed by the server and never sent. A reminder created in the app is one-shot, and an update does not touch a recurrence set in the web UI. Reminders also carry **no `files` and no `extraFields`**.
- **Plans cannot be saved as `Done`.** Add and update both answer 400 ("Progress cannot be set to Done"); a plan reaches Done only through the planner board in the web UI. `PlanProgress.isWritable` is false for `done`, the plan form disables that choice, and a plan already Done opens read-only. No substitute value is sent, because any other state would silently demote a finished plan. Covered by [plan_done_test.dart](../test/plan_done_test.dart). Plans also have no date, odometer or tags; the server sets DateCreated/DateModified itself.
- **Odometer update requires `initialOdometer`** (add does not: the server defaults it to the previous reading). The read model keeps `initialOdometer` so an edit can resend it. The value is `int.Parse`d server-side, hence integer strings. The update also **replaces** the reading's `equipmentRecordId` with whatever arrives, so it is round-tripped too. Forms convert the displayed unit back to the stored unit (`toStoredDistance` in [vehicle_units.dart](../lib/core/format/vehicle_units.dart)) before sending.
- **Gas state of charge** (`startingSoc`/`endingSoc`): always send both. 1.6.9 `int.Parse`s them without an empty guard (an absent field is a 500); 1.7.0 defaults to 20/80. See `_gasRecordBody` and [server_capabilities.dart](../lib/core/api/server_capabilities.dart).
- **Update replaces lists wholesale** (`files`, `extraFields`): omitting them on update erases them. Resend what the record holds.
- Read models carry `id` (for update/delete) and `tags`; plan also carries `type` (`ServiceRecord`/`RepairRecord`/`UpgradeRecord`, the server's `ImportMode` name).

## File attachments

- Upload: `POST /api/documents/upload`, multipart, field **`documents`**, one or more files. Returns `[{name, location, isPending}]` (`UploadedFiles`), with `location` like `/documents/<guid>.pdf`. Implemented by `VehiclesRepository.uploadDocuments`; model in [attachment.dart](../lib/core/models/attachment.dart).
- The multipart `Content-Disposition` is written in camel-case spelling (`camelCaseContentDisposition: true`): the lowercase spelling is legal but some reverse proxies in front of LubeLogger fail to parse it.
- Attach by putting that array in the record's `files` on add/update. **Every writable type supports `files` except reminders.** The update resends the full list and the server replaces it, so removing a chip and saving deletes the attachment. A cancelled form can orphan an already-uploaded server file; this is accepted.
- UI: [attachments_field.dart](../lib/features/vehicle/forms/attachments_field.dart) (pick, upload immediately, chips) is used by every form whose type supports files.
- Viewing: [attachment_viewer.dart](../lib/features/vehicle/attachments/attachment_viewer.dart). The server's `Authen` middleware accepts the key as the `x-api-key` header or the `?apiKey=` query, and `/documents` and `/images` are among the paths that allow it, so `{baseUrl}{location}` is fetchable with the key. Images open in-app with the key as a **header** (the key stays out of URLs); other types are downloaded through the authenticated client to the temp directory and handed to the OS.
- Build trap: `file_picker` is pinned to **8.x** in [pubspec.yaml](../pubspec.yaml). The 11.x Android module fails to link (`GeneratedPluginRegistrant` cannot resolve `FilePickerPlugin`). 8.x hardcodes `compileSdk 34` but pulls `flutter_plugin_android_lifecycle`, which needs 36, hence the `subprojects { afterEvaluate { ... } }` override in [android/build.gradle.kts](../android/build.gradle.kts). Do not bump `file_picker` without a release build.

## Supply requisition is not available over the API

The web UI can attach supplies to a service, repair, upgrade, plan or fuel record ("requisition": stock is decremented and the record stores a `RequisitionHistory`). The app cannot.

- The web MVC controllers (`Controllers/Vehicle/*Controller.cs`, session auth) take inputs with a `Supplies` list and call `RequisitionSupplyRecordsByUsage`.
- The API controllers (`Controllers/API/*Controller.cs`, key auth) take `GenericRecordExportModel`, which has no supplies field, and there is no requisition endpoint. The web endpoints are out of reach for a key-only client (see [api-server.md](api-server.md#authentication)).
- `GET /api/vehicle/supplyrecords/all` is read-only. It could fill a picker but has no write path to attach the selection.
- The API **delete** path does restore requisitioned supplies, so deleting from the app does not corrupt stock accounting.
- A client-side workaround (decrement supplies via `supplyrecords/update` on save) is possible but unfaithful: the record never gets a `RequisitionHistory`, so it will not list its supplies and delete-time restore will not fire. Not done.

So the record forms have no supply picker. Revisit only if upstream adds supplies to the API write model. The same note sits in the doc comment of `showGenericRecordForm` in [add_generic_record_form.dart](../lib/features/vehicle/forms/add_generic_record_form.dart).
