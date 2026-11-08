# Shared packages (`DoYouHost/app-shared`)

Which code lives in the shared repository instead of here, how its refs are
pinned, and what is still duplicated between this app and bambuddy-mobile.
**Read it before changing the `app-shared` refs in `pubspec.yaml`, before moving
code between the apps, or before writing a helper that may already exist
upstream.**

The shared repository keeps its own list of extraction candidates and the
evidence for each (`docs/candidates.md` there). Its rule: a package takes what
both apps mean identically and requires everything they mean differently as a
parameter; where the parameter list would be longer than the code, the code stays
in the apps.

## What comes from where

All pinned in [`pubspec.yaml`](../pubspec.yaml) as git dependencies on
`https://github.com/DoYouHost/app-shared.git`, by tag:

| Package | Holds | Local half |
|---|---|---|
| `app_report_client` (v0.2.0) | relay client, outbox, sender, log redactor | `report_config.dart` (relay URL, redactor keys) |
| `app_diagnostics` | recording session, log record, disk mirror, isolate merge, probes (tap, route, HTTP, error, lifecycle), device facts, session store | `diagnostics_wiring.dart`, `session_facts.dart`, `image_probe.dart`, `log_form.dart` |
| `app_report_ui` | the guided report screens, recording banner, review | `features/bug_report/report_wiring.dart` (`ReportBindings`) |
| `dash_kit` (re-exports `dash_ui`) | design system, tokens, confirm dialog, sheets, error/empty views, content width cap | `core/theme/dash_theme.dart` (`lubeLoggerBrand`, re-exports `dash_kit`) |
| `app_util` | JSON coercion, user-typed numbers, server-address handling, `DioFailure` classification, byte formatting, `DemoHttpClientAdapter` | `AppErrorCode` and the exception classes, `DemoBackend` |
| `app_guards` (dev) | source-scan tests (spacing scale, `Wrap` run spacing, short words, finder strings) and executables: `l10n_sync`, `l10n_language`, `glue_short_words`, `aab_versions`, `play` (all run from the justfile), `commit_msg` (the `.githooks/commit-msg` hook) and `log_coverage` | `tool/*.toml` configuration, the thin tests |

The tool scripts that used to be copied into `tool/` (`aab_versions.py`,
`check_l10n_sync.py`) are gone; the justfile calls the `app_guards` executables
(`dart run app_guards:…`). Only configuration stays here:
[`tool/play.toml`](../tool/play.toml),
[`tool/l10n_language.toml`](../tool/l10n_language.toml),
[`tool/log_coverage.toml`](../tool/log_coverage.toml).

## Pinning rules

- **Pinned by tag, so a change upstream reaches a release here only through a
  commit in this repo.** The history shows the pattern: `build: bump app-shared to
  vX.Y.Z`.
- **One package must resolve from one ref.** A package that two others name at
  different refs fails version solving, so `app_report_client` must be the ref
  `app_diagnostics` names for its own copy, and `app_diagnostics`, `app_report_ui`,
  `dash_kit`, `app_util` and `app_guards` move together (all `v0.13.1` at the time
  of writing; `app_report_client` stays at its own tag). Bump all of them in one
  commit, after the tag exists upstream.
- **While a tag does not exist yet**, resolve through a local
  `pubspec_overrides.yaml` (gitignored). None may remain once the lock names the
  tag.
- `pubspec.lock` is committed and CI runs `flutter pub get --enforce-lockfile`,
  after an uncommitted lock let CI resolve a newer plugin than any developer had.

## Seams this app has to fill

- **Diagnostics**: the recorder's session store, redactor, limits and session
  listener (`diagnostics_wiring.dart`); the HTTP probe config
  (`lubeloggerHttpProbe`) which by default samples nothing; and `LogSource` /
  `LogStream` values, whose file suffixes are already on disk and must not be
  renamed. Details in [diagnostics.md](diagnostics.md).
- **Report UI**: `ReportBindings` (recorder, sender, root navigator, home route,
  log file prefix) and the consent lines.
- **Demo**: the backend's `handle` and `upload` callbacks, see [demo.md](demo.md).
- **Errors**: the shared package only classifies a Dio failure (`DioFailure`);
  this app owns the codes and exception classes (`core/api/api_exceptions.dart`).

## Deliberately not shared

From the shared repository's own list, still true:

- `demo_config`, `report_config`, `dash_theme` brand, report wiring: they are the
  app's half of a shared contract, constants and nothing else.
- Charts: this app paints its own with `CustomPainter` ([dashboard.md](dashboard.md));
  bambuddy uses `fl_chart`.
- Server version comparison: the meanings differ.
- The offline cache, write queue and `RetryInterceptor` (`lib/core/cache/`,
  `lib/core/api/retry_interceptor.dart`): generic, but there is no second consumer.
- Notifications: the models differ (reminders from WorkManager here, a foreground
  service in bambuddy).

## Still duplicated, candidates for the next extraction

Verified against the current tree:

- **`session_facts.dart` against bambuddy's copy**: the same shape, differing only
  in what is excluded for the demo host and in the `extra` fields.
- **The relay, outbox and sender providers block in `providers.dart`**: parallel
  construction in both apps.
- **Relay timeouts are the app's job.** `RelayClient.send` sets none, so this app
  passes a dedicated Dio with upload timeouts (`relayDioProvider`), while
  bambuddy's relay client currently runs on its default bare Dio with a 15 s send
  timeout. A candidate is per-request timeouts inside `RelayClient.send`, so no
  app has to remember it ([diagnostics.md](diagnostics.md)).
- **The justfile** release and purge recipes are copies of bambuddy's with the
  same structure; `just` imports only local paths, so sharing means a submodule or
  a fetch step, which has not been worth it. Differences to keep: no flavors, and
  the `versionCode` scheme ([release.md](release.md)).
- **File-extension helpers** are written three times in this app:
  `_extensionOf` and `_renamed` in
  [`upload_prep.dart`](../lib/core/files/upload_prep.dart) and `_extension` in
  [`attachment_viewer.dart`](../lib/features/vehicle/attachments/attachment_viewer.dart).
  A single helper here would do; it does not need a package.
