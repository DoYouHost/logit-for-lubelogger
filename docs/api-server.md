# LubeLogger API: server, identity, vehicles and app features on top

How the app authenticates against LubeLogger, which server-level endpoints it uses (identity, version, backup, vehicle add/edit/delete), and the app features built on them (tab configuration, launcher shortcuts, background reminder notifications).
Read it before touching authentication, the Settings screen, the vehicle form, or the background worker.

Server facts come from the upstream LubeLogger source (`Controllers/APIController.cs`, `Filter/`, `Middleware/Authen.cs`, tags 1.6.9 and 1.7.0) unless marked **observed**. Record-level API rules live in [api-records.md](api-records.md).

## Authentication

- The app uses an **API key only**, sent as the `x-api-key` header ([api_client.dart](../lib/core/api/api_client.dart)). There is no username/password or Basic-auth path and no auth-mode switch; do not reintroduce one without a product decision. (The server also accepts the key as `?apiKey=` and supports Basic auth; the app deliberately uses neither.) User-facing summary: [README.md](../README.md#authentication).
- Every request also sends `culture-invariant: true` (typed JSON, ISO dates; see [api-records.md](api-records.md#wire-format)).
- **401 is overloaded.** LubeLogger answers 401 both for a missing/invalid key and for a valid key that lacks the scope (View/Edit/Delete) or access to the vehicle, with a `{success:false,...}` body for the latter. The client therefore **never logs out on 401**; it surfaces `AppErrorCode.unauthorized` and lets the caller decide ([api_exceptions.dart](../lib/core/api/api_exceptions.dart)).
- Key scopes map to routes: reads need `View`, add/update `Edit`, delete `Delete`.
- `CollaboratorFilter` (used by some routes) only checks that the already-authenticated user may edit the vehicle; it does not need a session cookie, so key requests pass it. Endpoints with no filter at all (`whoami`, `version`, `extrafields`, `calendar`) rely on the global `Authen` middleware, which accepts the key.
- Web MVC endpoints (cookie/session auth) are not reachable with a key.

## Identity, version, backup (Settings screen)

All in [settings_screen.dart](../lib/features/settings/settings_screen.dart); repository calls `whoAmI()`, `serverVersion()`, `makeBackup()` in [vehicles_repository.dart](../lib/data/vehicles_repository.dart).

| Feature | Endpoint | Behaviour and traps |
|---|---|---|
| Signed-in user | `GET /api/whoami` -> `{username, emailAddress, isAdmin, isRoot}` | Works with any key. Shown as "signed in as" plus Admin/Root chips. Model: [whoami.dart](../lib/core/auth/whoami.dart); booleans parsed tolerantly. |
| Update hint | `GET /api/version?checkForUpdate=1` -> `{currentVersion, latestVersion}` | Server fetches the latest tag from GitHub. `ServerVersion.updateAvailable` strips a leading `v` before comparing (GitHub tags are `v1.7.0`, the server reports `1.7.0`). If the GitHub call fails the server answers `OperationResponse` `success:false` with HTTP 200, so the fields parse empty and no hint is shown. [server_version.dart](../lib/core/models/server_version.dart). |
| Server version | `GET /api/info` -> `{currentVersion, locale, currencySymbol, decimalSeparator, dateFormat}` | `currentVersion` feeds the capability gate below. |
| Backup | `GET /api/makebackup` | **Root only** (`[Authorize(Roles=IsRootUser)]`, not the key filter): a non-root caller is refused (**observed** as 403). The button is shown only when `who.isRoot`. Trigger-only: returns the server-side backup path as a JSON string. `?output=download` (zip) and `?output=email` exist and are not used. |

Other endpoints the app does not use: cross-vehicle `<type>/all` lists, `reminders/send` (root, mails a digest), `calendar` (ICS), `tempfiles`, `cleanup`, `demo/restore` (destructive, never call it).

## Version gate

The app supports servers **1.6.9 and 1.7.0**. The only client-visible route difference is `DELETE /api/vehicles/delete` (1.7.0+); the other is the gas state-of-charge default noted in [api-records.md](api-records.md#write-constraints-by-type).

- [server_capabilities.dart](../lib/core/api/server_capabilities.dart) derives `vehicleDelete` from `/api/info.currentVersion` with `versionAtLeast` ([version.dart](../lib/core/util/version.dart)). An unknown or unparsed version **fails open** (allow the attempt).
- If the version is below 1.7.0 the form shows an explanatory dialog and fires no request. If the version was unknown and the server is old, the 404 from the missing route is mapped to `AppErrorCode.unsupportedByServer` ("update your server"); a 404 anywhere else stays a plain bad response, because there it means a wrong base URL.
- Tests: [server_capabilities_test.dart](../test/server_capabilities_test.dart), [version_test.dart](../test/version_test.dart). The demo backend reports 1.7.0, so delete stays enabled in demo mode.

## Vehicles: add, edit, delete

Routes: `GET /api/vehicles`, `GET /api/vehicle/info` (returns an **array** even for one vehicle), `POST /api/vehicles/add`, `PUT /api/vehicles/update`, `DELETE /api/vehicles/delete?id=`. Repository: `addVehicle` (returns the new id from `additionalData.vehicleId`), `updateVehicle`, `deleteVehicle`. Form: [add_vehicle_form.dart](../lib/features/garage/add_vehicle_form.dart) (`showVehicleForm`, add when `existing == null`, else edit).

**Write model (`VehicleImportModel`)**, all values sent as strings, camelCase keys (server JSON binding is case-insensitive):

| Field | Rule |
|---|---|
| `year`, `make`, `model`, `identifier`, `fuelType` | Required, non-empty. `year` must parse as an integer. |
| `fuelType` | Exactly `Gasoline`, `Diesel` or `Electric`, otherwise 400. The read model reports it as `isDiesel`/`isElectric` booleans (gasoline = both false). |
| `identifier` | Names which field labels the vehicle. The app **always sends `LicensePlate`**, which makes `licensePlate` required (empty plate with that identifier is a 400). Any other identifier must match an entry in `extraFields` that has a value. |
| `useEngineHours`, `odometerOptional` | Optional; `"true"`/`"false"` strings. |
| `tags` | Optional, space-separated. |
| `extraFields` | List of `{name, value, isRequired, fieldType}`; the form edits them like record forms do. |

**Edit traps (server side, not fixable in the client):**

- Update **replaces** `identifier` and `extraFields` with what is sent, so the form resends the vehicle's existing values. `GET /api/vehicles` returns the full vehicle, so `Vehicle` parses `vehicleIdentifier` and `extraFields` ([vehicle.dart](../lib/core/models/vehicle.dart)).
- Update only **sets** `IsDiesel`/`IsElectric` and never clears them, so switching a vehicle back to Gasoline (or Diesel to Electric) has no effect server-side.

**Delete:**

- Server cascades: every record type is wiped, then the vehicle. Irreversible. The key's household needs the `Delete` permission; without it the server answers **401**, which surfaces as `unauthorized` and is not a logout.
- The in-app flow is a **double confirmation** (generic warning, then a final dialog naming the vehicle) before the call, then the garage and vehicle-info providers are invalidated.
- The garage list uses `flutter_slidable` cards with an edit action; the list sits in a `SlidableAutoCloseBehavior` and each card owns a `SlidableController`, and taps on controls outside the list (settings gear, add tile) close any open action first and are consumed if one was open ([garage_screen.dart](../lib/features/garage/garage_screen.dart)).

## Tab configuration (app-side, no server involvement)

Record tabs ([vehicle_tab.dart](../lib/core/models/vehicle_tab.dart), enum `VehicleTab`) have two independent settings in `SharedPreferences` via [settings_repository.dart](../lib/core/settings/settings_repository.dart):

| Setting | Key | Default and robustness |
|---|---|---|
| Visibility (`Set<VehicleTab>`) | `visible_tabs` | All visible. Unknown persisted ids are dropped. |
| Order (full permutation) | `tab_order` | Enum order. Unknown ids are dropped and any tab missing from the stored list is **appended**, so a tab added in a newer version cannot vanish. |

- The Dashboard is always first and is not in the enum, so it is neither hideable nor reorderable.
- The vehicle tab bar and the FAB add sheet consume the **same** ordered-and-filtered list (`showAddRecordSheet` takes the pre-ordered `List<VehicleTab>`).
- Settings UI: one `ReorderableListView` with `buildDefaultDragHandles: false` and a `ReorderableDragStartListener`, so a drag starts only from the handle.
- **Trap:** the list uses `onReorderItem`, not the deprecated `onReorder`. `onReorderItem` already adjusts `newIndex` for the removal, so `TabOrderNotifier.move` in [providers.dart](../lib/providers.dart) does a plain `insert(newIndex, removeAt(oldIndex))`. Switching back to `onReorder` would need the classic `if (newIndex > oldIndex) newIndex -= 1` again.

## Launcher shortcuts (app-side)

Two dynamic Android App Shortcuts via `quick_actions`: **Add fuel** (`add_fuel`) and **Add odometer** (`add_odometer`). Published only while signed in, cleared on logout; no manifest change is needed for dynamic shortcuts.

- Tap flow: resolve a vehicle (auto-select when the garage has exactly one, otherwise a picker sheet), then open `showAddFuelForm` / `showAddOdometerForm`. Works from a cold or warm start and from any screen, because all UI goes through `rootNavigatorKey`.
- Cold start: the plugin fires the callback before any UI exists, so [main.dart](../lib/main.dart) calls `init` before `runApp` and the callback only sets the top-level `pendingQuickAction` notifier. `QuickActionHandler` (mounted in `MaterialApp.router`'s `builder` in [app.dart](../lib/app.dart)) consumes it, and drops the action if the user is signed out.
- Guard each `rootNavigatorKey.currentContext` use after an `await` with `context.mounted` (the `BuildContext` one, not `State.mounted`) to satisfy `use_build_context_synchronously`.
- Labels are localized at publish time (outside the widget tree) from the system locale; `ServerProfileNotifier.save` republishes, `clear` removes.
- Files: [quick_actions_service.dart](../lib/core/quick_actions_service.dart), [quick_action_handler.dart](../lib/features/quick_actions/quick_action_handler.dart), [vehicle_picker_sheet.dart](../lib/features/quick_actions/vehicle_picker_sheet.dart), icons `ic_shortcut_fuel` / `ic_shortcut_odometer` in `android/app/src/main/res/drawable/`. Android's dynamic-shortcut ceiling is about 4-5; the app uses 2.
- The forms invalidate their own providers on save, so adding from a shortcut refreshes state. Not verified on a physical device with a live server.

## Background reminder notifications (app-side)

A periodic background pass posts a local notification for each reminder that becomes past due. Opt-in (off by default); enabling it requests the Android 13+ `POST_NOTIFICATIONS` permission.

- **The server does the "past due" math.** The pass fetches `repo.reminders(vehicleId)` for every vehicle and keeps `urgency == ReminderUrgency.pastDue`; urgency is computed server-side from date **and** odometer. No local date/odometer logic. ([reminder_worker.dart](../lib/core/notifications/reminder_worker.dart), `runReminderPass`.)
- **One WorkManager task for all background work.** [background_worker.dart](../lib/core/background/background_worker.dart) runs `runBackgroundPass`: deliver the queued writes, warm the cache (if enabled), then the reminder pass (if enabled). Every 3 hours, network required, `ExistingPeriodicWorkPolicy.update`. WorkManager's floor is 15 minutes and firing is best-effort under Doze/OEM battery managers, which is fine for day-scale reminders. The task's unique name stays `lubelogger.reminderCheck` on purpose: an installed app already has a task registered under it, and a new name would leave the old one scheduled forever.
- **The isolate rebuilds the API stack itself** (`SettingsRepository`, `SecureCredentialsStore`, `ApiClient`, `VehiclesRepository`); it shares no state with the UI and uses no Riverpod.
- **Once-per-reminder dedup** ([reminder_notifications.dart](../lib/core/notifications/reminder_notifications.dart), pure and unit-tested in [reminder_notifications_test.dart](../test/reminder_notifications_test.dart)):
  - Key = `v{vehicleId}:r{reminderId}:{dueDate}:{dueOdometer}`. The due target is in the key on purpose: a recurring reminder is rolled forward by the server **on the same `id`** (`GetUpdatedRecurringReminderRecord`, triggered by the web UI's auto-refresh), so keying on `id` alone would suppress every future cycle.
  - After each pass the persisted set (`reminder_notified_keys` in `SharedPreferences`, written only by the background isolate) is set to **exactly the current past-due keys**, not the union. It is self-pruning: a reminder that is serviced or rolled forward drops out and can alert again if it returns.
- Registration: on every app start when signed in and enabled, on login (`ServerProfileNotifier.save`) and on toggle-on; cancelled on logout and toggle-off (`reminderNotificationsProvider` in [providers.dart](../lib/providers.dart)).
- Tapping a notification carries the vehicle id as payload and navigates to `/vehicle/<id>` (live, or after the first frame on a cold start).
- Build requirements: `flutter_local_notifications` needs core library desugaring (`desugar_jdk_libs` in [android/app/build.gradle.kts](../android/app/build.gradle.kts)) and the `POST_NOTIFICATIONS` permission in the manifest; the status-bar icon is `res/drawable/ic_stat_reminder.xml`.
- Reminders written over the API cannot recur (see [api-records.md](api-records.md#write-constraints-by-type)); a recurring reminder created in the web UI keeps working with the dedup above.
