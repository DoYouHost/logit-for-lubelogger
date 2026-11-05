# Branching and release branches

How code moves from a topic branch to a published version. The recipes behind it
are in [release.md](release.md).

## The model

```
topic ──merge──▶ dev ──merge a SHA──▶ release/X.Y.Z ──PR, merge commit──▶ main
                  ▲                                                       │
                  └─────────────── merge main back ◀──────────────────────┘
```

- **Topic branches** are `feat/…`, `fix/…`, `refactor/…`, `docs/…`, `test/…`. They
  merge into `dev` with a merge commit and are deleted. A push to them runs
  nothing: iterate on the tests of what you touched. A pull request into `dev`
  runs CI, which nothing on `dev` requires; the gate is the release branch.
- **`dev`** is the integration branch. Nothing is released from it and `ship`
  refuses to run on it. `ship-dev` (a prerelease, no commit) still runs anywhere.
- **`release/X.Y.Z`** is cut for every stable version and is the only branch
  `just ship X.Y.Z` runs on; the name must match the version exactly.
- **`main`** only receives release PRs. The `protect-default-branch` ruleset
  requires a pull request, one approval and a green `analyze · test · build`.

A pull request from outside goes into `dev`, like a topic branch, and its CI run
is the contributor's answer to "does it build". One that was opened against `main`
gets its base switched to `dev` before it is merged.

## Cutting a release

1. `just release-start X.Y.Z` — branches off `origin/dev`, pushes the branch and
   opens a **draft** PR into `main`. From then on every push to the branch runs
   CI. Pass a base to cut elsewhere: a SHA of `dev` to release only up to it, or
   `origin/main` for a hotfix.
2. Bring in what belongs to the release: `git merge <sha-on-dev>` for everything up
   to a point, `git cherry-pick` for a single fix. A fix lands on `dev` first and
   comes over from there, so the bump commit stays the only commit that exists on
   the release branch alone.
3. Push and **monitor the run** (`gh run list --branch release/X.Y.Z`, `gh run
   watch <id>`): CI is the draft PR's run. Fix what is red on the release branch
   and carry the fix to `dev`.
4. `just ship X.Y.Z` once the run is green — bumps, tests, builds, publishes the
   GitHub release and the Play internal track, then marks the PR ready. A branch
   that had nothing ahead of `main` at step 1 gets its PR here instead. The bump
   is a new head commit, so wait for its run to go green too before step 5.
5. Merge the PR with **Merge commit**, never squash or rebase: the release tag
   points at a SHA on the release branch, and a squash leaves that SHA outside
   `main`'s history.
6. `git switch dev && git merge origin/main && git push`. This is not cosmetic:
   `ship-dev` counts its builds from the last release tag reachable from `dev`, and
   until `dev` contains the bump commit it numbers them into a version that has
   already shipped.

The release is published on GitHub before the PR is merged, so waiting for green
in step 3 is what keeps a red build from reaching Obtainium; `just ship` still runs
`just test` and builds the APK and the bundle itself.

## Enforced by the repo

`protect-default-branch` allows only the **Merge commit** method
(`allowed_merge_methods: ["merge"]`), so step 5 cannot be done wrong from the web
UI. It also requires one approval and a green `analyze · test · build`. The
ruleset's bypass actor (repository admin) can override all of it; do not.

CI runs on GitHub-hosted runners. The self-hosted runner it used before belonged to
an org runner group that accepted a workflow only from an exact ref, so pull
requests from forks and from `release/*` never got a run.
