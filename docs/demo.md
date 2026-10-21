# Demo mode

The store-review mode: an in-process fake LubeLogger server, so a reviewer (or
anyone without a self-hosted instance) can use every screen. **Read it before
adding a feature that talks to a new endpoint, changing sign-in, or touching
anything that must behave differently for a demo profile.**

## Using it

On the sign-in screen enter server address `demo` and API key `demodemodemo`
(also in the [README](../README.md); the Play Console "App access" instructions
use the same pair). Recognition is local: no network probe runs, and no traffic
leaves the device.

## Moving parts

- [`lib/core/demo/demo_config.dart`](../lib/core/demo/demo_config.dart): the magic
  token, the canonical profile URL `http://demo`, and `DemoConfig.isDemoUrl`
  (host `demo` or `demo.lubelogger.app`, any scheme). A single-label host never
  resolves publicly, so an accidentally un-intercepted request fails locally
  instead of leaking.
- [`lib/core/demo/demo_backend.dart`](../lib/core/demo/demo_backend.dart): the
  mutable fake server, one instance per process. `_seed()` creates two vehicles
  (a petrol Corolla and a diesel Passat) with every record type. Adds, updates and
  deletes mutate it; `/vehicle/info` and reminder urgency are computed from the
  current records, so the dashboard always agrees with the tabs.
- The Dio adapter is `DemoHttpClientAdapter` from `app_util`
  ([shared-packages.md](shared-packages.md)). It takes the backend's `handle` and,
  for multipart bodies, `DemoBackend.upload`, which answers with fake attachments.
- `ServerProfile.isDemo` is the switch. `ApiClient`
  ([`api_client.dart`](../lib/core/api/api_client.dart)) installs the adapter when
  it is set, which covers the UI and the reminder background isolate alike (each
  isolate gets its own freshly seeded backend, with the same shape).
  `SetupController.connect` ([`features/setup/providers.dart`](../lib/features/setup/providers.dart))
  checks the token, stores it, and saves a profile labelled `Demo`.

## Rules and traps

- **Add demo data in `DemoBackend._seed()`** for any new record type or screen
  state. A feature without demo data is invisible to a reviewer.
- **The demo answers with the real contract's shapes**: typed JSON under the
  culture-invariant header, ISO dates, .NET enum *names* (`fieldType: 'Text'`).
  A wire-shape mismatch otherwise surfaces as empty screens.
- **It reports server version 1.7.0**, because it implements the 1.7.0-only
  vehicle-delete route and the delete action is gated on the version. A route
  added for a newer server contract needs the version reported accordingly.
- The demo user is root (`whoami` returns `isRoot: true`), so admin-only actions
  such as the backup button show. `makebackup` returns a fake path.
- **The offline cache and write queue are bypassed for a demo profile**
  (`ApiClient` skips `OfflineInterceptor`): the data is already in memory and
  caching it would leave a real server's directory layout on disk for a profile
  that is not a server. `cachedRead` in `providers.dart` depends on that being
  inert.
- **Demo never publishes a bug report.** `reportSenderProvider` passes
  `demoMode: () => profile.isDemo` and the sender answers `RelayFailure.demo`
  without calling out ([diagnostics.md](diagnostics.md)).
- **The demo host is not registered as a secret** in the log redactor
  (`sessionSecrets` in [`session_facts.dart`](../lib/core/diagnostics/session_facts.dart)):
  it is a constant shipped in the APK, and masking `demo` would blank that word
  everywhere it legitimately appears, starting with control ids on the setup screen.
  The session header carries `demo: true` instead.
- Vehicle photos for the demo are bundled assets (`assets/demo/`, declared in
  `pubspec.yaml`); the photo cache is skipped for a demo profile.

## Test

[`test/demo_backend_test.dart`](../test/demo_backend_test.dart) is the end-to-end
contract test: real Dio, the demo adapter, the production repository and the
model parsers, so a mismatch between the fake and the parsers fails there.
