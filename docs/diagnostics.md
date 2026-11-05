# Diagnostics and the bug-report relay

The in-app recording, its redaction, and how a report reaches a GitHub issue
through the relay. The recording, the report screens and the relay client are
shared packages ([shared-packages.md](shared-packages.md)); this app supplies the
configuration. **Read it before changing `lib/core/diagnostics/`, the relay URL,
what the log may contain, or the report flow.**

## What lives here

- [`report_config.dart`](../lib/core/diagnostics/report_config.dart): the whole
  app-side contract. Recording limits (`recordingLimit` 15 minutes,
  `recordingSizeLimit` 10 MiB), `relayBaseUrl`, `reportLogSchema`, the HTTP probe
  config (`lubeloggerHttpProbe`) and the redactor (`lubeloggerRedactor`,
  `lubeloggerOurKeys`). Asserted by `test/http_probe_test.dart` and
  `test/log_redactor_test.dart`.
- [`diagnostics_wiring.dart`](../lib/core/diagnostics/diagnostics_wiring.dart):
  `lubeloggerRecorder` builds the one `DiagnosticRecorder`; its session listener
  writes a `settings` record and opens the image probe when a recording starts.
- [`session_facts.dart`](../lib/core/diagnostics/session_facts.dart): the exact
  secret values the redactor must catch (API key, server host) and the session
  header facts. `sessionSecrets` is split out because the background isolate
  needs the secrets but not the rest.
- [`image_probe.dart`](../lib/core/diagnostics/image_probe.dart) and
  [`log_form.dart`](../lib/core/diagnostics/log_form.dart): app-specific probes.
- [`features/bug_report/report_wiring.dart`](../lib/features/bug_report/report_wiring.dart):
  hands the shared report screens this app's recorder, sender, navigator and home
  route. Providers (`diagnosticRecorderProvider`, `relayClientProvider`,
  `relayDioProvider`, `reportOutboxProvider`, `reportSenderProvider`) are in
  [`lib/providers.dart`](../lib/providers.dart).

## Relay contract

`relayBaseUrl` points at one relay that serves several apps.

- **The path prefix picks the target repository**, from the prefix the challenge
  was issued under. **It must not end in a slash**: both endpoints hang off it.
- The client (`RelayClient` in `app_report_client`) uses two endpoints:
  `POST {base}/challenge` with `{installId}` returns `{ticket, nbf, exp, seed,
  bits}` (a proof-of-work challenge), and `POST {base}/report` with
  `{installId, kind, header, description, logSchema, logGz, ticket, powNonce}`
  returns `201 {url}` of the created issue.
- Status mapping in `RelayFailure`: `/report` 403 and 503 are `notYet` (retry
  later), 409 is `duplicate`, 502 and transport errors are `unreachable`, anything
  else is `rejected`; `/challenge` 503 is `refused`; `demo` is produced by the app
  itself, never by the relay.
- **`reportLogSchema` is `LogHeader.formatVersion`** and must stay inside the
  schema window the relay accepts. Bumping the log format means checking the relay
  first.
- **`kind` is `bug`, `change` or `feature`** (`ReportKind`) and is the only thing
  telling the relay which sort of issue to open. A `change` or `feature` request
  has **no recording**: `logGz` and `logSchema` are **absent**, not empty, so the
  relay can tell it from a bug report whose recording came out blank, and the
  `header` is cut to `{v, ts, app, server?, locale?}` with no device, time zone,
  screen or server fingerprint. There is one free-text `description` for all
  kinds and no title field, so the relay titles the issue.
- The relay is not part of this repository: its deployment and its handling of
  `kind` cannot be verified from here. If it is unreachable the sender reports
  `RelayFailure.unreachable`, and the report screens show the matching message.
- Demo mode never publishes ([demo.md](demo.md)).
- The privacy policy ([`site/privacy.html`](../site/privacy.html)) describes the
  relay, the redaction and the public-issue path; keep it in step with anything
  that changes what leaves the device.

## Why the relay gets its own Dio

`relayDioProvider` is a bare Dio (`createBareDio`) with upload timeouts
(`kUploadSendTimeout` 3 min, `kUploadReceiveTimeout` 1 min, in
[`api_client.dart`](../lib/core/api/api_client.dart)):

- The relay is not the LubeLogger server and must see none of the auth
  interceptors, credentials or configured base URL.
- Dio spends `sendTimeout` on the whole body, and a report carries the gzipped log
  (up to a couple of MB from a 10 MB session). The 15 s an API call gets would
  fail it on a slow mobile link. `RelayClient.send` sets no timeouts of its own, so
  the app has to remember this.

## Redaction rules that are easy to break

- **An allowlist, not a denylist, for response bodies**: `_sampledPaths` samples
  only `/api/vehicles`, `/api/vehicle/{id}`, `/api/info` and `/api/version`.
  `whoami` answers with a person and `documents/upload` echoes the stored file
  name, so neither may ever be sampled.
- **`sampleRequests: true`**: every write leaves the phone as strings the app
  formatted itself, so "the date came back a day early" is answered by what was
  sent.
- **`lubeloggerOurKeys`** exempts the app's own vocabulary (control ids, routes,
  `kind`, `state`, …) from the scrub: a server host called `garage` or `vehicle`
  would otherwise eat them. A new log field with an app-defined value belongs
  here with a pattern.
- **Free-text keys** (`_freeTextKeys`: `notes`, `description`, `licenseplate`,
  `make`, `model`, `tags`, …) are user content and always scrubbed; `partNumber`
  is the user's, `partQuantity` is a number. Extra fields (`name`/`value`) are
  free text on both sides. A key matching `email` is a secret everywhere, because
  an instance is often shared by a household or a small fleet.
- **`_schemaKeys`** (currency symbol, date format, decimal separator, locale,
  versions, `message`) are server configuration a formatting report needs, and
  would not survive the shape rule (`MM/dd/yyyy` is not a date). `message` is
  written by the server ("Access Denied"); without it every refusal would read
  `<str:13>`.
- The session secrets include the API key as an exact value (caught even inside a
  message the app did not format, such as a server echoing it back) and the
  server host, except for a demo profile. A `SocketException` reads "Failed host
  lookup: '…'", which is not a URL, so only an exact value catches it.
- The reminder/sync background isolate continues the UI's recording through
  `DiagnosticRecorder.startBackground` (in `background_worker.dart`) and must be
  given the same `lubeloggerRedactor` and `sessionSecrets`; with an empty
  redactor its first records are the ones carrying secrets.
