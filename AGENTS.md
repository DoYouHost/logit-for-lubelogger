# lubelogger-mobile — instructions for coding agents

Flutter app (Android) for a self-hosted [LubeLogger](https://lubelogger.com) server.
Everything it shows comes from that server's REST API, with an API key the user
generates; there is no cloud service of our own. Unofficial, not affiliated with
LubeLogger.

## CI is the answer to most questions

Every pull request into `main` runs [.github/workflows/ci.yml](.github/workflows/ci.yml):
`flutter pub get --enforce-lockfile`, `dart format --output=none
--set-exit-if-changed lib test tool`, `flutter analyze`, `flutter test` and a debug
APK compile. A pull request that touches only docs, `site/`, `store-assets/` or
`*.md` skips the build and still reports green.

**Before you ask a question, check the CI result and fix what is red** (`gh run list
--branch <branch>`, `gh run view <id> --log-failed`). **Ask only about product
decisions** — what a feature should do, which trade-off is wanted. Reproduce the
checks locally before pushing:

```sh
dart format lib test tool
flutter analyze
flutter test          # or: just test
```

A question about the server's contract is answered by the server source
([hargata/lubelog](https://github.com/hargata/lubelog)), not by the user: cite the
file and line. The GitHub Action has it checked out at `/tmp/lubelog-server-ref`;
locally make a read-only clone outside the repository and never create a copy
inside it (`reference/` is git-excluded).

## Stop and ask: compatibility

The app is published on Google Play and talks to servers the maintainer does not
control. **Do not break what already works.** Stop and ask before anything that
would:

- change how an API request is shaped or stop handling a response shape that the
  supported servers (1.6.9 and 1.7.0) still send;
- break stored state written by an earlier version — SharedPreferences keys, the
  credentials store, cached models, the offline write queue, notification state —
  without a migration that keeps existing installs working;
- change `applicationId` (`page.codeberg.doyouhost.lubelogger_mobile`), launcher
  shortcuts, minSdk, or anything else that would strand users mid-upgrade;
- rewrite or delete a working solution because a different approach looks cleaner.

Describe the situation, lay out the options with pros and cons — including "leave
it as is" — and wait for the decision.

## Stop and ask: security

**Never weaken security on your own judgement.** Loosening TLS validation, storing
the API key anywhere less protected than `flutter_secure_storage`, logging
credentials or tokens, adding a permission, exporting a component, disabling
R8/shrinking or broadening the keep rules — all of it needs an explicit, spoken
"yes" first. "It unblocks the feature" is exactly the case where you ask.

**If you notice a potential vulnerability while working, report it and wait**: what
it is, how it could be exploited, what fixing it would cost. Do not patch it quietly
inside an unrelated change and do not stay silent.

## Project layout

- `lib/core/` — API client (`api/`), auth, models, cache, background work,
  notifications, diagnostics, demo backend, settings, theme. `lib/data/` holds the
  repository on top of the client.
- `lib/features/<feature>/` — one directory per screen: garage, vehicle (record
  forms and attachments), dashboard, quick actions, settings, setup, sync, bug
  report.
- `lib/l10n/` — `app_en.arb` (the template) and `app_pl.arb`, plus generated
  `app_localizations*.dart`. User-visible text goes through `AppLocalizations`,
  never hardcoded.
- `test/` mirrors `lib/`. `tool/` holds guard configs and `scroll_bench.sh`.
- `justfile` — `just test`, `l10n-check`, `l10n-glue`, `run`, `build`, `ship X.Y.Z`,
  `ship-dev`. **`just hooks` once per clone** points git at `.githooks/`, which
  refuses a commit message that is not one Conventional Commits line.
- One Android flavor (no `--flavor`), one `main` entry point.

## Documentation

- [docs/api-records.md](docs/api-records.md) — the record routes and wire format,
  required fields and write constraints per record type, file attachments, and why
  supply requisition is not available over the API. **Read it before touching a
  record form, a repository write or an attachment.**
- [docs/api-server.md](docs/api-server.md) — authentication and its traps, identity
  and version, vehicles (add, edit, delete and the version gate), tab configuration,
  launcher shortcuts, background reminders. **Read it before touching auth,
  `ServerCapabilities`, the garage or the background pass.**
- [docs/dashboard.md](docs/dashboard.md) — chart ranges, the palette and its
  colour-blind constraint. **Read it before touching `chart_range.dart` or
  `chart_palette.dart`.**
- [docs/demo.md](docs/demo.md) — the demo backend: what it must show.
- [docs/diagnostics.md](docs/diagnostics.md) — the bug-report log, the relay
  contract and the redaction rules that are easy to break. **Read it before adding a
  log field, a control or a report path.**
- [docs/performance.md](docs/performance.md) — measuring before claiming, and the
  scroll benchmark harness.
- [docs/release.md](docs/release.md) — `ship`, `ship-dev`, the version-code scheme,
  R8 and resource-shrinking traps that only show in a release build. **Read it
  before touching a recipe, the proguard rules or adding a plugin.**
- [docs/shared-packages.md](docs/shared-packages.md) — the `app-shared` packages in
  use, how refs are pinned and bumped, and what is still duplicated.

## Conventions

- Comments and commit messages in **English**, always. Commits follow
  [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) and
  `.githooks/commit-msg` holds them to **one line and nothing else**: no body, no
  attribution trailers. Prefer self-documenting code; comment the non-obvious
  "why", not the "what".
- **`dart format` is the style and CI enforces it.** Run `dart format lib test tool`
  before pushing and never hand-tune spacing to fight it; the one-off reformat is in
  `.git-blame-ignore-revs`. Strings use single quotes (`prefer_single_quotes`).
- **Authentication is `x-api-key` only** — no Basic auth, no login form — and every
  request sends `culture-invariant: true`. LubeLogger answers 401 both for a bad key
  and for a key without the scope, so **a 401 never logs the user out**
  ([docs/api-server.md](docs/api-server.md)).
- **Write bodies are string-typed and a 200 can mean failure**: check the
  `OperationResponse` body, not only the status, and resend `files` and
  `extraFields` on an update because the server replaces them
  ([docs/api-records.md](docs/api-records.md)).
- **A route only newer servers have goes through `ServerCapabilities`**; an unknown
  version fails open.
- **Strings:** English and Polish. After editing an `.arb`, run `just l10n-check`
  (LanguageTool on the strings this branch changed; set `LANGUAGETOOL_URL` to your
  own instance) and `just l10n-glue` (no line ends on a one-letter word). It does
  not catch a phrase that parses and means nothing, so read the copy too.
- **Anything reflective, or any Android resource referenced by a name string, must
  be tried on a release build**: CI builds debug only, and R8 and resource shrinking
  break things only there ([docs/release.md](docs/release.md)).
- **Release only through `just ship` / `just ship-dev`.** Never push a tag by hand
  and never change `applicationId`.
- **Bump every `app-shared` ref together**; `app_report_client` must match the ref
  `app_diagnostics` names ([docs/shared-packages.md](docs/shared-packages.md)).
- **Diagnostics:** `relayBaseUrl` must not end in a slash; every new log field with
  an app-defined value needs an entry in `lubeloggerOurKeys`; only allowlisted
  paths may be response-sampled ([docs/diagnostics.md](docs/diagnostics.md)).
- Do not reorder or re-tint `chartCategoryOrder` / `chart_palette.dart` without
  re-running a colour-blind check ([docs/dashboard.md](docs/dashboard.md)).
