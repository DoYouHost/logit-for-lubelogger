# Recipe naming: a bare verb is earned by the ones typed weekly and safe to run
# twice (test, run, build, ship); a variant appends only what differs from the
# silent defaults — APK, stable channel (build-aab, ship-dev). Machines and
# objects read <subject>-<verb> (emu-boot, release-publish). Anything
# irreversible on GitHub is purge-<deepest thing lost>, so `just purge<TAB>`
# enumerates every no-undo command and nothing else.
#
# The listed description is the [doc] attribute, not the comment above it: just
# shows only the LAST comment line. Attributes must touch the recipe line — a
# comment between them is `error: extraneous attribute`, and it breaks the whole
# file, not one recipe. Group names are numbered because bare `just` (via
# --unsorted) reads in source order while `just --list` re-sorts alphabetically;
# the digits are what keep the two agreeing.

# Release artifacts live in build/dist (survives _clean-artifacts, which only
# wipes build/app) so a later rebuild doesn't take them out from under
# `release-publish`.
apk := "build/dist/app-release.apk"
aab := "build/dist/app-release.aab"
repo := "DoYouHost/lubelogger-mobile"

emulator_bin := "$HOME/Android/Sdk/emulator/emulator"
# Default local AVD (Pixel 7, API 35). Every local recipe takes an `avd=`
# argument, so `just emu-list` shows the alternatives. Serials are resolved by
# AVD name, not hardcoded — the port depends on boot order.
avd := "pixel35"

[doc('show available commands')]
default:
    @just --list --unsorted

# ---- 1-develop — runs the app and the tests, publishes nothing ----

[doc('run unit and widget tests')]
[group('1-develop')]
test:
    flutter test

# Every screen of the app on the demo server, in both themes and at 150 / 200 %
# text, held to Flutter's contrast, tap-target and label guidelines. One run with
# the parallelism inside it: several `flutter test` processes share build/test_cache
# and corrupt it. See docs/a11y-guideline-tests.md.
# usage: just test-a11y [FILES…]
[doc('run the rendered accessibility suite')]
[group('1-develop')]
test-a11y *files='test/a11y':
    systemd-run --user --scope -q -p MemoryMax=12G -p MemorySwapMax=0 -p RuntimeMaxSec=1800 flutter test --concurrency=4 {{files}}

# Compare .arb files against the English template: find missing, outdated or mismatched keys.
# usage: just l10n-status [*ARGS]
[doc('check translation status and missing keys against app_en.arb')]
[group('1-develop')]
l10n-status *args:
    dart run app_guards:l10n_sync {{args}}

# core.hooksPath is per-clone local config, so a fresh clone has no hooks until
# this runs. Points git at .githooks/, which holds the commit-message check.
[doc('point this clone at the versioned git hooks')]
[group('1-develop')]
hooks:
    git config core.hooksPath .githooks
    @echo "hooks: core.hooksPath = $(git config core.hooksPath)"

# Spelling and grammar for the strings the user actually reads. Checks only what
# this branch changed; `just l10n-check-all` sweeps every locale file. Set
# LANGUAGETOOL_URL to a self-hosted instance to skip the public rate limit and
# keep the copy off someone else's server. Configured by tool/l10n_language.toml.
# usage: just l10n-check [BASE_REF]
[doc('spell-check the .arb strings this branch changed')]
[group('1-develop')]
l10n-check base='dev':
    dart run app_guards:l10n_language --base {{base}}

[doc('spell-check every .arb string, not only this branch')]
[group('1-develop')]
l10n-check-all:
    dart run app_guards:l10n_language --all

# A one-letter word ("i", "w", "a") must not end a line in any language:
# turns the space after each into a no-break space, then regenerates.
# test/short_words_test.dart fails until this has run.
[doc('glue one-letter words to the next word in every .arb, then gen-l10n')]
[group('1-develop')]
l10n-glue:
    dart run app_guards:glue_short_words
    flutter gen-l10n

# Boots the AVD first if needed, then builds, installs and runs with hot reload.
# This is the primary pre-commit verify loop.
# usage: just run [AVD]
[doc('run the app on a local AVD, booting it first')]
[group('1-develop')]
run avd=avd: (emu-boot avd)
    #!/usr/bin/env bash
    set -euo pipefail
    flutter run -d "$(just _emu-serial {{avd}})"

# ---- 2-emulator — boots the emulator ----

# An emulator takes whatever port is free, so the serial is looked up by name via
# `emu avd name` rather than assumed to be 5554.
_emu-serial avd:
    #!/usr/bin/env bash
    set -euo pipefail
    for serial in $(adb devices | awk '/^emulator-/ {print $1}'); do
        if [ "$(adb -s "$serial" emu avd name 2>/dev/null | head -1 | tr -d '\r')" = "{{avd}}" ]; then
            echo "$serial"
            exit 0
        fi
    done
    exit 1

# Idempotent (no-op if the AVD is already online); boots in the background and
# blocks until Android finishes booting, so local recipes can depend on it.
# usage: just emu-boot [AVD]
[doc('boot a local AVD and wait for it to finish booting')]
[group('2-emulator')]
emu-boot avd=avd:
    #!/usr/bin/env bash
    set -euo pipefail
    if serial=$(just _emu-serial {{avd}} 2>/dev/null); then
        echo "{{avd}} already running ($serial)"
        exit 0
    fi
    if ! "{{emulator_bin}}" -list-avds | grep -qx "{{avd}}"; then
        echo "No such AVD: {{avd}}. Available:" >&2
        just emu-list >&2
        exit 1
    fi
    "{{emulator_bin}}" -avd {{avd}} >/dev/null 2>&1 &
    disown
    echo "Booting {{avd}}..."
    for _ in $(seq 1 60); do
        serial=$(just _emu-serial {{avd}} 2>/dev/null || true)
        [ -n "${serial:-}" ] && break
        sleep 2
    done
    [ -n "${serial:-}" ] || { echo "{{avd}} did not come up" >&2; exit 1; }
    adb -s "$serial" wait-for-device
    until [ "$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
        sleep 2
    done
    echo "{{avd}} ready ($serial)"

[doc('list local AVDs, marking which are running')]
[group('2-emulator')]
emu-list:
    #!/usr/bin/env bash
    set -euo pipefail
    for name in $("{{emulator_bin}}" -list-avds); do
        serial=$(just _emu-serial "$name" 2>/dev/null || true)
        if [ -n "$serial" ]; then
            printf '  %-16s running   %s\n' "$name" "$serial"
        else
            printf '  %-16s stopped\n' "$name"
        fi
    done

# ---- 3-build — produces the bytes that get published ----
#
# Both build recipes take the same optional version pair, e.g.
# `just build-aab 0.3.3-dev.1 302001`.

# Wipe build outputs + the Dart kernel snapshot so a release build can't pack a
# stale snapshot (incremental release builds have been known to repeatably reuse
# an outdated one — same code shipped, wrong bytes). Cheap insurance before any
# release build.
_clean-artifacts:
    rm -rf build/app .dart_tool/flutter_build

# The one implementation behind `build` and `build-aab`: resolve the version,
# announce it, clean, build, leave the artifact in build/dist under a fixed name.
#
# The version always reaches gradle explicitly. Without arguments it comes from
# pubspec.yaml, which is what a stable release wants (`ship` bumps it first);
# `ship-dev` passes its own, because a dev build deliberately leaves pubspec
# alone, and building from it silently produces the *previous* release again —
# that is what makes Play answer "version code already in use".
#
# Announced before the build so you see which version is going out before gradle
# spends a minute on it, rather than after Play refuses the upload.
_build kind name code:
    #!/usr/bin/env bash
    set -euo pipefail
    name='{{name}}'
    code='{{code}}'
    # Both or neither: half a pair would build a version nobody asked for.
    if { [ -n "$name" ] && [ -z "$code" ]; } || { [ -z "$name" ] && [ -n "$code" ]; }; then
        echo "Pass both a name and a code, or neither." >&2
        exit 1
    fi
    if [ -z "$name" ]; then
        pubspec=$(grep '^version: ' pubspec.yaml | cut -d' ' -f2)
        name=${pubspec%%+*}
        code=${pubspec##*+}
    fi
    if [ '{{kind}}' = appbundle ]; then
        ext=aab
        src="build/app/outputs/bundle/release/app-release.aab"
    else
        ext=apk
        src="build/app/outputs/flutter-apk/app-release.apk"
    fi
    echo "Building $ext $name (versionCode $code)"
    just _clean-artifacts
    flutter build {{kind}} --release --build-name="$name" --build-number="$code"
    mkdir -p build/dist
    cp "$src" "build/dist/app-release.$ext"
    echo "-> build/dist/app-release.$ext"

[doc('build the release APK')]
[group('3-build')]
build name='' code='': (_build "apk" name code)

[doc('build the Play bundle')]
[group('3-build')]
build-aab name='' code='': (_build "appbundle" name code)

# Reads the manifest out of the bundle instead of echoing back what we handed to
# gradle: what it baked in is the only number Play will judge. Takes explicit
# paths from `ship`/`ship-dev` so it can only ever report the bundle that run
# just built, never a leftover in build/dist.
# usage: just aab-show [BUNDLE...]
[doc('print the versions baked into the built Play bundles')]
[group('3-build')]
aab-show *paths:
    @dart run app_guards:aab_versions {{paths}}

# Read-only. Needs uv and the service-account key (tool/play.toml says where).
[doc('list the Google Play tracks and the releases on them')]
[group('3-build')]
play-tracks:
    @dart run app_guards:play tracks

[doc('delete local build outputs')]
[group('3-build')]
clean:
    flutter clean

# ---- 4-release — writes to the checked-out branch, to GitHub and to Google Play ----
#
# `ship` and `ship-dev` produce the same two artifacts in the same order; they
# differ only in where the version comes from. Both build the Play bundle
# *before* publishing the GitHub release, so a bundle that fails to build cannot
# leave a published release with nothing to promote.

# A release is cut from whatever is checked out: `_bump` commits here and
# `release-publish` pushes here. `ship` insists on `release/X.Y.Z`, so main and
# dev never receive a bump directly. One definition for both, because a bump
# landing on a different branch than the push would publish a release without its
# own version commit.
[no-exit-message]
_branch:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! branch=$(git symbolic-ref --short -q HEAD); then
        echo "HEAD is detached — check out the branch you are releasing from." >&2
        exit 1
    fi
    echo "$branch"

# The branch name carries the version, so a typo in either one stops here instead
# of publishing a release whose bump belongs to another version.
[no-exit-message]
_require-release-branch ver:
    #!/usr/bin/env bash
    set -euo pipefail
    branch=$(just _branch)
    if [ "$branch" != "release/{{ver}}" ]; then
        echo "ship {{ver}} runs from release/{{ver}}, not '$branch'. Start it with: just release-start {{ver}}" >&2
        exit 1
    fi

# Opens the draft PR into main for release/<ver>; a no-op when one is open.
# Fails when the branch has no commit over main — `release-start` tolerates
# that (the bump commit is still to come), `release-publish` cannot.
[no-exit-message]
_release-pr ver:
    #!/usr/bin/env bash
    set -euo pipefail
    branch="release/{{ver}}"
    open=$(gh pr list --repo {{repo}} --base main --head "$branch" --state open --json number --jq '.[0].number // empty')
    if [ -n "$open" ]; then
        echo "PR #$open already open for $branch"
        exit 0
    fi
    gh pr create --repo {{repo}} --base main --head "$branch" --draft \
        --title "chore: release {{ver}}" \
        --body "Release {{ver}}: merges release/{{ver}} into main."

# Cuts release/<ver> from <base> (default: the pushed tip of dev; a SHA or
# origin/main for a hotfix works too), pushes it and opens its draft PR, so CI
# runs on every change that is merged into the release from then on.
# usage: just release-start X.Y.Z [BASE]
[doc('cut release/X.Y.Z, push it and open its draft PR')]
[group('4-release')]
[no-exit-message]
release-start ver base='origin/dev':
    #!/usr/bin/env bash
    set -euo pipefail
    if ! [[ {{ quote(ver) }} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "release-start takes X.Y.Z, got '{{ver}}'" >&2
        exit 1
    fi
    branch="release/{{ver}}"
    git fetch --quiet origin
    if git show-ref --verify --quiet "refs/heads/$branch" || \
        git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        echo "$branch already exists; check it out instead." >&2
        exit 1
    fi
    git switch --no-track -c "$branch" {{ quote(base) }}
    git push -u origin "$branch"
    just _release-pr {{ver}} || echo "No PR yet (nothing ahead of main?); \`just ship {{ver}}\` opens it."

# versionCode = (major*10000 + minor*100 + patch) * 1000 (e.g. 1.2.3 → 10203000)
# The trailing three zeros are the dev slots: `ship-dev` numbers the builds
# between two releases into them (1.2.3-dev.7 → 10203007 - 1000, i.e. just under
# 1.2.3 and just over 1.2.2), so a dev build can never block the release it
# precedes.
#
# Idempotent: safe to re-run after a partially-completed `ship` — it skips the
# edit/commit when the version is already bumped, so the pipeline can resume.
_bump ver:
    #!/usr/bin/env bash
    set -euo pipefail
    branch=$(just _branch)
    # A branch that exists only here has nothing to catch up with, and `git pull`
    # would fail on the missing ref. `--exit-code` says 2 for that and 128 for
    # "could not reach origin": only the first is a reason to skip the pull, and
    # swallowing the second would build the release on a tree that never caught
    # up with the remote.
    rc=0
    git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 || rc=$?
    case $rc in
        # --ff-only, not --rebase: a release branch carries merge commits from
        # dev, and a rebase on a diverged branch would flatten them.
        0) git pull --ff-only --autostash origin "$branch" ;;
        2) echo "origin has no $branch yet — first release from this branch" ;;
        *) echo "Cannot read origin (git ls-remote exited $rc)." >&2; exit 1 ;;
    esac
    major=$(echo "{{ver}}" | cut -d. -f1)
    minor=$(echo "{{ver}}" | cut -d. -f2)
    patch=$(echo "{{ver}}" | cut -d. -f3)
    code=$(((major * 10000 + minor * 100 + patch) * 1000))
    target="version: {{ver}}+${code}"
    if [ "$(grep '^version: ' pubspec.yaml)" = "$target" ]; then
        echo "pubspec.yaml already at {{ver}}+${code}, skipping bump"
    else
        sed -i "s/^version: .*/${target}/" pubspec.yaml
    fi
    git add pubspec.yaml
    if git diff --cached --quiet; then
        echo "Nothing to commit — version {{ver}} already committed, resuming"
    else
        git commit -m "chore: bump version to {{ver}}"
    fi

# Upload the APK to a release, skipping it if already attached so a resumed run
# cannot duplicate it. One fixed file and never a variadic: that is what keeps
# the Play bundle off the GitHub release.
#
# Capture the asset list before filtering it: `gh ... | grep -q` deadlocks
# against `set -o pipefail` — grep closes the pipe on its first match, gh dies
# with SIGPIPE (141), and the `if` wrongly takes the "not found" branch.
[no-exit-message]
_upload-asset tag file:
    #!/usr/bin/env bash
    set -euo pipefail
    tag={{ quote(tag) }}
    file={{ quote(file) }}
    assets=$(gh release view "$tag" --repo {{repo}} --json assets --jq '.assets[].name')
    name=$(basename "$file")
    if grep -qxF "$name" <<<"$assets"; then
        echo "Asset $name already uploaded, skipping"
    else
        gh release upload "$tag" --repo {{repo}} "$file"
    fi

# Produces everything a stable version needs: the APK for the GitHub release (and
# Obtainium), plus the Play bundle released to internal testing. Promoting it
# to production stays a click in the Play Console.
# usage: just ship X.Y.Z
[doc('bump, test, build and publish a stable release')]
[group('4-release')]
ship ver:
    just _require-release-branch {{ver}}
    just _bump {{ver}}
    just test
    just build
    just build-aab
    just release-publish {{ver}}
    just aab-show {{aab}}
    just play-internal

# Test, build and publish the current commit as a dev prerelease.
#
#   versionName  X.Y.Z-dev.N    versionCode  (X.Y.Z as in _bump) - 1000 + N
#
# X.Y.Z is the release this build is heading for (default: the next patch after
# the last tag) and N counts the dev builds of that target — so every dev build
# is above the last release and below the next one. Passing the whole
# `X.Y.Z-dev.N` pins N instead of counting it, as long as that slot is free.
#
# pubspec.yaml is not touched and nothing is committed: the version travels as a
# build flag, so the branch never carries a `-dev` version and the release
# points at a SHA. Obtainium hides prereleases by default, so a tester opts in
# with one switch and everyone else keeps seeing stable only.
#
# The Play bundle goes out to internal testing as the last step; pass
# `bundle=no` when a build is only meant for Obtainium. The parameter is `bundle`
# and not `aab` because a parameter shadows the global of the same name for the
# whole recipe, which would expand `{{aab}}` to `yes`.
#
# usage: just ship-dev [X.Y.Z | X.Y.Z-dev.N] [bundle=yes|no]
[doc('publish a dev prerelease from the current commit')]
[group('4-release')]
ship-dev target='' bundle='yes':
    #!/usr/bin/env bash
    set -euo pipefail
    # A dev release names a commit, so the build has to *be* that commit —
    # untracked files included, since a new .dart file compiles in whether or not
    # git knows about it.
    if [ -n "$(git status --porcelain)" ]; then
        echo "Working tree is dirty; commit or stash before shipping a dev build." >&2
        exit 1
    fi
    # The counter is read off the dev tags, so a build published from another
    # machine has to be visible here or it gets its number handed out twice.
    git fetch --tags --quiet origin
    # --exclude, because --match takes a glob and not a regex: the trailing `*`
    # of the patch component happily swallows `-dev.3`, so without this the
    # second dev build of a cycle would measure itself against the first one.
    last=$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' --exclude '*-dev.*')
    base=${last#v}
    if [ "$(git rev-list --count "$last..HEAD")" -eq 0 ]; then
        echo "Nothing new since $last." >&2
        exit 1
    fi
    target='{{target}}'
    # The full dev version is accepted as well as the bare target, because that
    # is the string you have in hand — off the release page or the phone's about
    # screen — when you re-run a build. Its N then replaces the counter below.
    want_n=''
    case "$target" in
        *-dev.*)
            want_n=${target##*-dev.}
            target=${target%-dev.*}
            ;;
    esac
    if [ -z "$target" ]; then
        IFS=. read -r lmaj lmin lpat <<<"$base"
        target="$lmaj.$lmin.$((lpat + 1))"
    fi
    if ! grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' <<<"$target"; then
        echo "Target must be X.Y.Z or X.Y.Z-dev.N, got '{{target}}'." >&2
        exit 1
    fi
    if [ -n "$want_n" ]; then
        if ! grep -qE '^[0-9]+$' <<<"$want_n"; then
            echo "Dev number must be a number, got '{{target}}'." >&2
            exit 1
        fi
        # 10# so a padded `-dev.08` is decimal eight and not an octal error.
        want_n=$((10#$want_n))
    fi
    # The dev slots sit *under* the target, so a target at or below the last
    # release would hand out a versionCode the phone has already installed.
    # `sort -V` compares numerically (0.9.0 < 0.10.0, which sorting by text gets
    # backwards); the target loses when it sorts first.
    if [ "$(printf '%s\n%s\n' "$target" "$base" | sort -V | head -1)" = "$target" ]; then
        echo "Target $target is not newer than the last release $base." >&2
        exit 1
    fi
    # N counts dev builds of this target, so the first one is always dev.1 and
    # the sequence has no gaps. Read from the tags rather than kept in a file:
    # the tags are the record of what was published, and a counter on disk would
    # drift from them the first time a run failed halfway.
    #
    # `sed -n .../p` keeps only tags whose suffix really is a number, so a
    # hand-made `-dev.rc1` cannot silently count as zero.
    dev_n() { git tag "$@" --list "v$target-dev.*" | sed -n 's/.*-dev\.\([0-9]\+\)$/\1/p' | sort -n | tail -1; }
    # A dev tag already on this commit means an earlier run of this recipe got
    # as far as publishing it. Reuse it — same commit is the same build, and the
    # steps below skip whatever that run finished.
    n=$(dev_n --points-at HEAD)
    if [ -n "$want_n" ]; then
        # A number spelled out by hand may only name this commit's own build or a
        # free slot; taking another commit's would republish under its name.
        if [ -n "$n" ] && [ "$n" != "$want_n" ]; then
            echo "HEAD is already published as v$target-dev.$n, not dev.$want_n." >&2
            exit 1
        fi
        if [ -z "$n" ] && [ -n "$(git tag --list "v$target-dev.$want_n")" ]; then
            echo "v$target-dev.$want_n already exists on another commit." >&2
            exit 1
        fi
        n=$want_n
    elif [ -z "$n" ]; then
        highest=$(dev_n)
        n=$(( ${highest:-0} + 1 ))
    fi
    # dev.0 would take the release's own code minus a thousand, i.e. the slot
    # the previous release series ends on.
    if [ "$n" -lt 1 ] || [ "$n" -gt 999 ]; then
        echo "Dev number $n under $target is outside the 1..999 slots." >&2
        exit 1
    fi
    maj=$(cut -d. -f1 <<<"$target")
    min=$(cut -d. -f2 <<<"$target")
    pat=$(cut -d. -f3 <<<"$target")
    code=$(( (maj * 10000 + min * 100 + pat) * 1000 - 1000 + n ))
    name="$target-dev.$n"
    sha=$(git rev-parse HEAD)
    # The release is created around a commit, so the server needs it first. Said
    # rather than pushed: which branch a dev build comes off is the user's call.
    if [ -z "$(git branch -r --contains HEAD 2>/dev/null)" ]; then
        echo "HEAD is not on the remote yet. Push it first: git push origin HEAD" >&2
        exit 1
    fi
    echo "Dev build $name (versionCode $code) from ${sha:0:8}"
    just test
    just build "$name" "$code"
    # Renamed only here: unlike the bundle, this APK is published as a release
    # asset a tester downloads, so the file has to say which build it holds.
    mv {{apk}} "build/dist/app-$name.apk"
    if [ '{{bundle}}' != 'no' ]; then
        just build-aab "$name" "$code"
    fi
    tag="v$name"
    # Resumable like `release-publish`: skip whatever a failed earlier run did.
    if gh release view "$tag" --repo {{repo}} >/dev/null 2>&1; then
        echo "Release $tag already exists, skipping create"
    else
        # --generate-notes, unlike in `release-publish`: raw commit subjects are
        # exactly the changelog a dev channel wants. Play's own notes are the
        # handwritten ones, and internal testing does not ask for them at all.
        gh release create "$tag" --repo {{repo}} --target "$sha" \
            --title "$tag" --prerelease --generate-notes
    fi
    just _upload-asset "$tag" "build/dist/app-$name.apk"
    git fetch --tags origin
    echo "Published $tag"
    if [ '{{bundle}}' != 'no' ]; then
        just aab-show {{aab}}
        just play-internal
    fi

# Assumes the APK is already built.
# usage: just release-publish X.Y.Z
[doc('publish the GitHub release for an already-built version')]
[group('4-release')]
release-publish ver:
    #!/usr/bin/env bash
    set -euo pipefail
    branch=$(just _branch)
    sha=$(git rev-parse HEAD)
    # Push the bump commit first; let GitHub create the tag together with the
    # release in one server-side call. This avoids the race where we push a tag
    # and immediately reference it before the server has indexed it.
    git push origin "HEAD:refs/heads/$branch"
    # Normally opened by `release-start`; this covers a branch cut when it had
    # nothing ahead of main, and a PR closed by hand.
    just _release-pr {{ver}}
    # Skip creating the release if it already exists (e.g. a previous run got
    # this far before failing), so the pipeline can be resumed safely.
    if gh release view "v{{ver}}" --repo {{repo}} >/dev/null 2>&1; then
        echo "Release v{{ver}} already exists, skipping create"
    else
        # Empty notes on purpose: the Play/Obtainium changelog is written by hand
        # afterwards, and --generate-notes would fill it with raw commit subjects.
        gh release create "v{{ver}}" --repo {{repo}} --target "$sha" \
            --title "v{{ver}}" --notes ""
    fi
    just _upload-asset "v{{ver}}" {{apk}}
    # Published, so the draft PR is now the only thing left to merge.
    if [ "$(gh pr view "$branch" --repo {{repo}} --json isDraft --jq .isDraft)" = "true" ]; then
        gh pr ready "$branch" --repo {{repo}}
    fi
    # Sync the server-created tag back to the local repo.
    git fetch --tags origin

# Releases the Play bundle in build/dist to internal testing. Safe to re-run:
# a versionCode already on the track is skipped.
# Needs uv and the service-account key (tool/play.toml says where).
# usage: just play-internal [--dry-run]
[doc('release the built Play bundle to internal testing')]
[group('4-release')]
play-internal *flags:
    dart run app_guards:play internal {{flags}} {{aab}}

# ---- 5-danger — deletes what cannot be restored ----
#
# All three are irreversible on the server side, hence the preview + typed
# confirmation. What is left is housekeeping, so old releases stay findable
# without carrying binaries nobody installs.

# Echo the subset of `tags` older than or EQUAL to `cutoff`, in input order.
# `sort -V` orders versions numerically (v0.9.0 < v0.10.0, which a plain lexical
# sort gets backwards). A tag is doomed when it sorts first against the cutoff;
# the callers' contract is "VER and below", so equality is included. This
# predicate decides which releases get destroyed — do not grow a second copy.
[no-exit-message]
_at-or-below cutoff tags:
    #!/usr/bin/env bash
    set -euo pipefail
    cutoff={{ quote(cutoff) }}
    tags={{ quote(tags) }}
    for tag in $tags; do
        v="${tag#v}"
        if [ "$(printf '%s\n%s\n' "$v" "$cutoff" | sort -V | head -1)" = "$v" ]; then
            echo "$tag"
        fi
    done

# Preview an irreversible list and demand a typed `yes`. The Keeping line is what
# catches an off-by-one in the cutoff before it executes.
#
# `printf ... $doomed` is deliberately unquoted: $doomed is a newline-separated
# blob and the word split is what puts one item per line.
#
# Call it as a bare statement — never `|| true`, never inside an `if`: the
# `exit 1` below IS the abort, and a caller that swallows it walks straight into
# the deletion loop.
[no-exit-message]
_confirm headline doomed keeping:
    #!/usr/bin/env bash
    set -euo pipefail
    doomed={{ quote(doomed) }}
    keeping={{ quote(keeping) }}
    echo {{ quote(headline) }}
    printf '  %s\n' $doomed
    echo "Keeping: $keeping"
    read -r -p "Type 'yes' to confirm: " answer
    if [ "$answer" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi

# Without VER the cutoff is the current minor series: "older" = a smaller
# major.minor than the newest release's, so the whole latest minor (e.g. all of
# v0.3.x) keeps its APKs while v0.2.x and earlier lose theirs. With VER
# everything at or below that release is stripped, the newest minor included.
# usage: just purge-assets [X.Y.Z]
[doc('DELETE the APKs of old releases, releases and tags stay')]
[group('5-danger')]
purge-assets ver='':
    #!/usr/bin/env bash
    set -euo pipefail
    # Capture the list first (piping gh straight into a filter risks a pipefail
    # abort). Keep only real vMAJOR.MINOR.PATCH tags; a high --limit grabs every
    # release in one page.
    releases=$(gh release list --repo {{repo}} --limit 50 --json tagName --jq '.[].tagName')
    tags=$(grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' <<<"$releases" || true)
    if [ -z "$tags" ]; then
        echo "No version releases found; nothing to clean."
        exit 0
    fi
    if [ -n "{{ver}}" ]; then
        doomed=$(just _at-or-below "{{ver}}" "$tags")
        if [ -z "$doomed" ]; then
            echo "No releases at or below v{{ver}}; nothing to clean."
            exit 0
        fi
        headline="About to strip artifacts from releases at or below v{{ver}} (irreversible; releases and tags stay):"
    else
        # Latest minor = the max (major, minor) across all tags.
        latest_major=-1; latest_minor=-1
        for tag in $tags; do
            v="${tag#v}"; major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"
            if (( major > latest_major )) || { (( major == latest_major )) && (( minor > latest_minor )); }; then
                latest_major=$major; latest_minor=$minor
            fi
        done
        # Keep the current minor (and anything newer); clean only older minors.
        doomed=$(for tag in $tags; do
            v="${tag#v}"; major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"
            if (( major < latest_major )) || { (( major == latest_major )) && (( minor < latest_minor )); }; then
                echo "$tag"
            fi
        done)
        if [ -z "$doomed" ]; then
            echo "Only v${latest_major}.${latest_minor}.x releases exist; nothing to clean."
            exit 0
        fi
        headline="Latest minor: v${latest_major}.${latest_minor}.x (kept). About to strip artifacts from older releases (irreversible; releases and tags stay):"
    fi
    just _confirm "$headline" "$doomed" "$(comm -23 <(sort <<<"$tags") <(sort <<<"$doomed") | tr '\n' ' ')"
    for tag in $doomed; do
        mapfile -t assets < <(gh release view "$tag" --repo {{repo}} --json assets --jq '.assets[].name')
        if (( ${#assets[@]} == 0 )); then
            echo "  $tag: no artifacts"
            continue
        fi
        echo "  $tag: deleting ${assets[*]}"
        # One call per asset: gh takes a single asset name.
        for name in "${assets[@]}"; do
            gh release delete-asset "$tag" "$name" --repo {{repo}} -y
        done
    done
    echo "Cleanup done."

# Deletes whole releases (entry, title, notes and artifacts), unlike
# purge-assets. Tags are kept, so history and `git describe` still work and a
# release can be recreated from one; pass --cleanup-tag to gh by hand if you
# really want the tags gone too.
# usage: just purge-releases X.Y.Z
[doc('DELETE whole releases at VER and below, tags stay')]
[group('5-danger')]
purge-releases ver:
    #!/usr/bin/env bash
    set -euo pipefail
    # Capture first (piping gh straight into a filter risks a pipefail abort);
    # keep only real version tags.
    releases=$(gh release list --repo {{repo}} --limit 100 --json tagName --jq '.[].tagName')
    tags=$(grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' <<<"$releases" || true)
    if [ -z "$tags" ]; then
        echo "No version releases found; nothing to purge."
        exit 0
    fi
    doomed=$(just _at-or-below "{{ver}}" "$tags")
    if [ -z "$doomed" ]; then
        echo "No releases at or below v{{ver}}; nothing to purge."
        exit 0
    fi
    just _confirm "About to DELETE these releases from GitHub (irreversible; tags stay):" "$doomed" \
        "$(comm -23 <(sort <<<"$tags") <(sort <<<"$doomed") | tr '\n' ' ')"
    # One call per release: gh deletes a single tag.
    for tag in $doomed; do
        gh release delete "$tag" --repo {{repo}} -y
    done
    echo "Purged $(wc -l <<<"$doomed") releases."

# Keeps the newest KEEP dev prereleases and deletes the rest whole — release,
# notes, APK and tag. The tags go too, unlike purge-assets and purge-releases: a
# dev tag marks a build nobody can install any more, and `git describe` picking
# one over the release it came after is actively misleading. Stable releases are
# unreachable from here — the pattern only matches -dev tags.
# usage: just purge-dev-tags [KEEP]
[doc('DELETE old dev prereleases and their tags')]
[group('5-danger')]
purge-dev-tags keep='5':
    #!/usr/bin/env bash
    set -euo pipefail
    # gh lists newest first, and that is the right order here: a dev build is
    # superseded by the next one, so "old" is positional rather than semantic —
    # no version sort to get wrong on a `-dev.10` vs `-dev.9`.
    releases=$(gh release list --repo {{repo}} --limit 100 --json tagName --jq '.[].tagName')
    devs=$(grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-dev\.[0-9]+$' <<<"$releases" || true)
    if [ -z "$devs" ]; then
        echo "No dev prereleases; nothing to clean."
        exit 0
    fi
    doomed=$(tail -n +$(( {{keep}} + 1 )) <<<"$devs")
    if [ -z "$doomed" ]; then
        echo "Only $(wc -l <<<"$devs") dev prerelease(s), keeping {{keep}}; nothing to clean."
        exit 0
    fi
    just _confirm "About to DELETE these dev prereleases and their tags (irreversible):" "$doomed" \
        "$(head -n {{keep}} <<<"$devs" | tr '\n' ' ')"
    for tag in $doomed; do
        gh release delete "$tag" --repo {{repo}} --cleanup-tag -y
    done
    # Drop the local copies of the tags the server no longer has.
    git fetch --prune --prune-tags --tags origin
    echo "Purged $(wc -l <<<"$doomed") dev prereleases."
