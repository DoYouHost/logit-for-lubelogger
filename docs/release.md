# Release pipeline

How a version leaves this repository, the version-code scheme, and the Android
shrinker rules that only bite in a release build. **Read it before touching
`ship`, `ship-dev`, `release-publish`, `play-internal`, the version scheme,
`android/app/proguard-rules.pro` or `android/app/src/main/res/raw/keep.xml`, and
before adding a plugin or referencing an Android resource by name.**

## `just ship X.Y.Z`

Runs, in this order: `_bump`, `test`, `build` (APK), `build-aab`,
`release-publish`, `aab-show`, `play-internal` (see [`justfile`](../justfile)).
The APK goes to a GitHub Release (users update through Obtainium); the Play
bundle goes to **internal testing**. Promoting to production stays a click in
the Play Console. `repo` in the justfile is `DoYouHost/lubelogger-mobile`; the
recipes call `gh --repo`.

- **Both artifacts are built before anything is published**, so a bundle that
  fails to build cannot leave a GitHub release with nothing to promote.
- **`versionCode = (major*10000 + minor*100 + patch) * 1000`** (0.4.3 → 403000).
  The trailing three digits are the dev slots, see `ship-dev`. Obtainium and Play
  update only when `versionCode` rises; a tag or a `versionName` is not enough.
- **The version always reaches gradle explicitly** (`--build-name`,
  `--build-number`, both or neither, in `_build`). Without arguments it is read
  from `pubspec.yaml`. A dev build must pass its own, because it deliberately
  leaves `pubspec.yaml` alone, and building from it would silently produce the
  previous release again, which Play answers with "version code already in use".
- **`_clean-artifacts` runs before every release build** (`build/app` and
  `.dart_tool/flutter_build`). Incremental release builds have reused an outdated
  kernel snapshot, shipping the old code under a new version. Artifacts land in
  `build/dist`, which the clean step does not touch.
- **The server creates the tag.** Never push a tag separately.
  `release-publish` pushes the commit, then `gh release create vX.Y.Z --target
  <SHA>` creates tag and release in one call. Use the SHA, not the branch name:
  the tip can move between the push and the call. Notes are empty on purpose;
  the Play/Obtainium changelog is written by hand afterwards.
- **A release goes out from the checked-out branch, not from a fixed one.**
  `_branch` (shared by `_bump` and `release-publish`) refuses a detached HEAD.
  `_bump` rebases onto `origin <that branch>` and skips the rebase only when
  `ls-remote --exit-code` returns **2** (no such branch yet); it aborts on any
  other code, so an unreachable origin cannot yield a release built on a stale
  tree.
- **Every step is resumable.** `_bump` skips the edit and commit when the version
  is already bumped; `release-publish` skips an existing release;
  `_upload-asset` skips an asset that is already attached. Re-run the same
  command after a partial failure.
- **`aab-show` reads the manifest out of the bundle**, not the values handed to
  gradle: what gradle baked in is the only number Play judges.
- **Capture `gh` output into a variable, then filter it.** `gh … | grep -q` under
  `set -o pipefail` dies on SIGPIPE (141) and the `if` takes the wrong branch.
  `gh` deletes one release or asset per call, hence the loops in the purge
  recipes.
- `just` passes no arguments to dependencies, so `ship` calls the steps in order
  by hand.
- The release keystore is outside the repository and referenced from
  `android/key.properties` (gitignored). Without it the build falls back to the
  debug key and gradle only warns: such an APK is not distributable.

## `just ship-dev [X.Y.Z | X.Y.Z-dev.N] [bundle=yes|no]`

Publishes prerelease `vX.Y.Z-dev.N` with `--generate-notes`. No commit, and
`pubspec.yaml` is untouched: the version travels as a build flag, so no branch
ever carries a `-dev` version and the release names a SHA. Obtainium hides
prereleases by default, so only testers who opt in see them.

- `versionCode = code(X.Y.Z) - 1000 + N`: dev builds sit in the 999 slots **below**
  their target, above the previous release, so a dev build can never block the
  release it precedes. `N` must be in 1..999.
- `N` is counted from the tags (the first is `dev.1`), not from a file that would
  drift when a run fails halfway. A dev tag already on `HEAD` is reused, so a
  failed run resumes as the same build. `--exclude '*-dev.*'` is needed when
  finding the last release: `--match` is a glob and its trailing `*` would
  otherwise swallow `-dev.3`.
- It refuses a dirty tree (untracked files count, a new `.dart` file compiles in),
  a target not newer than the last release (`sort -V`, numeric), a `HEAD` that is
  not on the remote, and a tag number that already belongs to another commit.
- `bundle=no` skips the Play bundle for a build meant only for Obtainium. The
  parameter is `bundle` and not `aab` because a recipe parameter shadows the
  global of the same name.
- `just purge-dev-tags [KEEP]` deletes all but the newest KEEP (default 5) dev
  prereleases together with their tags. `purge-assets` and `purge-releases` never
  match a `-dev` tag; the latter keeps tags. All three show a preview and demand
  a typed `yes`; `_at-or-below` is the single predicate deciding what gets
  destroyed, so do not grow a second copy.

## Google Play

- `just play-tracks` is read-only; `just play-internal [--dry-run]` uploads the
  bundle in `build/dist` to internal testing and skips a versionCode already on
  the track. Both run `dart run app_guards:play`, configured by
  [`tool/play.toml`](../tool/play.toml) (service-account key stored outside the
  repository, path overridable with `PLAY_SA_KEY`).
- The `applicationId` is `page.codeberg.doyouhost.lubelogger_mobile`, and
  `tool/play.toml` calls it frozen: it is the identity of the Play listing, so
  changing it makes a different app. Do not "tidy" it.
- Store listing assets live in [`store-assets/`](store-assets); the project page
  and privacy policy are served from `site/` by `.github/workflows/pages.yml`.

## R8 and resource shrinking: crashes that appear only in release

Flutter's Gradle plugin enables R8 minification and resource shrinking for
release builds by default (`isMinifyEnabled = true`, `isShrinkResources` for an
app module, see `FlutterPlugin.kt` in the Flutter SDK), and appends
`android/app/proguard-rules.pro` to the R8 configuration when the file exists.
`android/app/build.gradle.kts` sets neither flag itself, so the behaviour follows
the Flutter version. Debug builds do not shrink, so anything reached only by
reflection or by a name string works in `flutter run` and breaks in the shipped
APK.

**CI does not catch this**: the compile check in `.github/workflows/ci.yml` is a
`--debug` build. Verify on a release build (`just build`) installed on a device.

Two crashes this caused, both fixed:

- **WorkManager failed at startup** (`Unable to get provider
  androidx.startup.InitializationProvider`, caused by `NoSuchMethodException:
  androidx.work.impl.WorkDatabase_Impl.<init> []`). WorkManager's Room database
  is instantiated reflectively through its no-arg constructor; Room's consumer
  rule keeps the class name but not the constructor, and R8 full mode strips
  members reached only by reflection. The rule in `proguard-rules.pro` is
  `-keep class * extends androidx.room.RoomDatabase { <init>(); }`; `extends`
  matches indirect subclasses.
- **Notification and shortcut icons "could not be found"**
  (`PlatformException(invalid_icon, …)`). `ic_stat_reminder`,
  `ic_shortcut_fuel` and `ic_shortcut_odometer` are referenced only by string, in
  `lib/core/notifications/notification_service.dart` and
  `lib/core/quick_actions_service.dart`, so the resource shrinker removed them.
  They are force-kept with `tools:keep` in `res/raw/keep.xml`.

When you add a plugin that instantiates classes reflectively, or reference an
Android resource by a runtime name string, add the matching rule
(`proguard-rules.pro` for code, `res/raw/keep.xml` for resources) and test the
release build.

`main()` additionally wraps notification and quick-action setup in a
try/catch (`lib/main.dart`), so a non-essential init failure cannot prevent
`runApp()`.
