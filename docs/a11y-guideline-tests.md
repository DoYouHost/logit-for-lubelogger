# Rendered accessibility tests

Every screen of the app is rendered on the demo server and held to Flutter's
accessibility guidelines (`textContrastGuideline`, `androidTapTargetGuideline`,
`labeledTapTargetGuideline`) in both themes at 100 % text, and in the light theme at
150 % and 200 %. **Read this before touching `test/a11y/` or fixing a finding it
reports.** The same suite exists in bambuddy-mobile; its write-up of how the contrast
guideline really measures is `docs/a11y-guideline-tests.md` there.

The suite was written **before** any fix: it records what the app does today, and
the fixes follow it, not the other way round. A test is never loosened to make a fix
unnecessary.

## Running it

- `just test-a11y` — the whole suite, one `flutter test --concurrency=4` under a
  12 GB scope (about 90 s). `just test-a11y test/a11y/garage_a11y_test.dart` for one
  file. Several `flutter test` processes at once corrupt `build/test_cache`; the
  parallelism is inside the one run.
- The harness's own fixtures (`a11y_contrast_judge_test.dart`,
  `a11y_contrast_phase_test.dart`, `a11y_text_scale_test.dart`) must pass before any
  finding is believed: they prove the harness itself.

## What it covers

One file per area, each surface registered with `a11ySurface(name, location:,
arrange:, shows:)`; every surface runs four tests (light, dark, light 150 %, light
200 %).

| File | Surfaces |
|---|---|
| `setup_a11y_test.dart` | sign-in, both validation errors, a rejected key, the key revealed |
| `garage_a11y_test.dart` | garage, empty, failed, swiped open, writes waiting, server away; add and edit vehicle, empty save, fuel-type menu, both delete confirmations, the unsupported-server dialog |
| `vehicle_a11y_test.dart` | dashboard (both vehicles, failed, empty ranges, no reminders, chart tooltips, range sheet, custom range picker), add-record sheet, tab strip variants, **every record tab** with records, empty and failed, sort menu, search, tag filter |
| `record_forms_a11y_test.dart` | **every record form**: new, saved empty, existing, delete confirmation and (where it has a date) the date picker; a record with an attachment and custom fields, the attachment opened; the three fuel entry modes; the odometer-backwards warning; the plan and reminder menus |
| `settings_a11y_test.dart` | settings, every select open, toggles on, hidden and reordered tabs, update available, backup made, licenses |
| `sync_a11y_test.dart` | the sync sheet waiting, retried, sending, refused, away, still away after a send |
| `quick_actions_a11y_test.dart` | the vehicle picker a launcher shortcut opens |
| `bug_report_a11y_test.dart` | the shared report screens in the app: explanation, every kind, a request refused in demo mode, recording, the recording bar over the garage, review (raw, a record opened, GitHub chosen, refused, discard asked) |

### Not covered, on purpose

- **Snackbars that follow a platform call** (stored data cleared): the cache clears
  through `path_provider`, which has no platform in a widget test.
- **A recovered recording** in the bug-report idle view: it needs a log file left on
  disk by an earlier run.
- **A launcher shortcut arriving** (`QuickActionHandler`): the handler's own
  navigator-context lookup is not reproducible under the test binding, so the sheet
  it opens is tested directly.
- **The system file picker and the share/open-file hand-off** of an attachment.

## What the harness does

- `a11yPumpApp` mounts the real `LubeLoggerApp` on the demo profile, in Polish. The
  platform side of a scenario (brightness, text scale, locale) goes through
  `tester.platformDispatcher`, so `ThemeMode.system` and the localization delegates
  are exercised too. DPR is 1, because the contrast judge reads one pixel per dp.
- `a11ySurface` pages a scrolling screen one viewport **less 72 dp** at a time
  (`a11yMeetsAllWhileScrolling`).
- **Tap targets are measured by `A11yTapTargets`, not by Flutter's traversal**, which
  skips a node touching the edge of an implicitly scrolling ancestor or of the window:
  a row as wide as its list touches both edges, so a full-width row of any height
  passed (`a11y_tap_targets_test.dart` pins it). Every tappable node is measured.
  The one narrowing is a measurement artefact: a control a viewport cuts reads small
  *across the cut only* (`SemanticsNode.rect` is clipped), so that axis is excused and
  the other is held to 48 dp (a tab half scrolled out of the strip is narrow, its
  46 dp height is real). Each scrollable above the node is asked on its own,
  against its own viewport: an edge counts as cut only when the node is flush with
  *that* viewport there **and** that scrollable has content beyond it, which its scroll
  actions say: at offset 0 a vertical scrollable offers `scrollUp` only, at the end
  `scrollDown` only (measured; horizontally `scrollLeft` / `scrollRight`). So the first
  row at offset 0 is measured whole, however flush with the top, and a page's "more
  below" cannot excuse the height of a horizontal strip inside it.
- A menu a surface leaves open is measured and then closed before the paging starts
  (`_closeMenus`): `MenuAnchor` with Escape, a popup or a dropdown with a tap on its
  barrier. Both are routes whose own scrollable would otherwise be taken for the
  screen's list, and the screen under the menu would never be paged.
- **A `shows:` finder must tell the arranged state from the state before it.** It was
  audited by skipping each step of every `arrange:` in turn (`a11yTap`, `a11yEnter`,
  `a11yLongPress`) and asking whether `shows:` still matched; a finder that survives
  proves nothing about that step. Three traps found that way: the options of a closed
  `DropdownButton` are built too (hidden in its button), a `Text` that is also the
  screen's title, and an obscured field that still holds its text. Re-run the audit
  after adding a surface (the harness had a temporary counter for it; it is a dozen
  lines).
- A red surface stops at its first failing page, so the scrolling pass matters only
  once the pages before it are green: the count of red tests is a lower bound.
- The contrast guideline is wrapped: a finding must fail at three sub-pixel phases (matched by node, `a11yStillFailing`: one node can carry several findings, and an ordinal would pair the wrong ones) and
  then fail again by the text's own colours (`judgeContrastFindings`). Section headers
  are skipped by the guideline because a short label in a full-width row leaves too
  few text pixels; their ink is `accentInk`, held by `brand_contrast_test.dart`.
- `a11yOnDone` registers work that must stop while the providers are alive (a
  recording); it runs on a failing surface too.
- The app's recorder is replaced by one that writes no files (`a11yPlatformOverrides`):
  file I/O never completes under a widget test's fake clock.
- `test/a11y/flutter_test_config.dart` loads Manrope and JetBrains Mono for this
  directory only. Without them every glyph is a block twice as wide as the real one.
- The demo backend is one process-wide instance and a surface may mutate it; a
  surface that saves must say so.

## Where a tappable node gets its label

Found fixing the label findings (1104 of them, down to the recording bar's 14):

- A log tag (`logTag`, `.tagged`) is `Semantics(identifier:)` and a node of its own: it
  merges the nodes *inside* it up, but not into a `Semantics` around it. So a label
  goes **inside** the tag (`Semantics(label:)` as the tag's child), never outside it:
  a select's name is passed into `_Dropdown`, not put on the `_SettingRow` around it.
- A button whose only child is a tagged text (a dropdown option, the garage's Edit
  pill) takes its name from a `Semantics(label:)` between the button and the tag,
  with the text under the tag excluded so it is not read twice.
- An `IconButton` takes `tooltip:`; an icon-only `FilledButton` takes only
  `Icon(semanticLabel:)`; a `Switch` beside a `Text` takes `Semantics(label:)` with the
  same words. A `GestureDetector`'s long-press is a node of its own: a `Semantics(label:)`
  *outside* the detector names it. Material's own words come from
  `MaterialLocalizations` (close, delete, back, "select date").
- `flutter_slidable` puts a tap with no name over every other card while one is open: the
  card is named from outside the `Slidable`.

## State

718 tests plus the harness's own, **718 green, 4 skipped, none red**. Nothing is red for a
harness reason. The four skipped are `dashboard: custom range picker`, switched off with
`a11ySurface(skip:)` and a comment at the call: `showDateRangePicker` is Flutter's own, its day
cells are 42 dp tall and its "close" and "save" buttons 34 dp, constants no theme reaches. The
maintainer chose to keep Material's range picker (with its band between the two dates) over a
sheet of our own or two single date pickers, so these are accepted, not forgotten. Re-enable
them when the picker is replaced or Flutter raises those sizes.

The recording bar (`app_report_ui`, `recording_banner.dart`) was the rest of the red until
`app-shared` v0.14.8: its buttons are named inside their own node, have a 48 dp target, and the
bar wraps onto a second line at a large text size instead of overflowing.

When you render a screen for a before/after image, load the `MaterialIcons` font from the
Flutter SDK (`bin/cache/artifacts/material_fonts`) with a `FontLoader`: without it every icon
is a tofu square with a different baseline, which looks like a centring bug and is not one.
The tests themselves do not need it.
