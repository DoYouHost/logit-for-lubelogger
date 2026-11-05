# Performance measurement

How to measure scroll and frame performance on a device without fooling yourself.
**Read it before you start chasing a jank or speed symptom, and before you report
a performance win.**

## The rule

**Build the repeatable measurement before testing any hypothesis.** Do not
"change something, scroll by hand, compare numbers":

- Hand scrolling varies in duration, velocity and where it stops, so the numbers
  describe the hand, not the code.
- A probe that only logs bad seconds leaves the denominator unknown, so a longer
  run reads as a worse one. The probe must report every second that produced
  frames, clean ones included.
- A stale background `adb logcat` keeps appending to an earlier run's file; a
  trace parser can mis-pair begin/end events across overlapping ring-buffer dumps.
- A win quoted from one run is noise. Run each variant **3 times and compare the
  means**, and check the instrument first: three identical runs must agree.
- Measure in **profile** mode. Debug drops frames for reasons a release build does
  not have, so debug timings answer a question nobody asked.

## `tool/scroll_bench.sh`

[`tool/scroll_bench.sh`](../tool/scroll_bench.sh) drives the app over `adb` with a
fixed script (open the first vehicle card, swipe to the fuel tab, then alternating
fling pairs over the record list) and prints one summary line: seconds, frames,
late frames and their share, and mean and max build and raster time.

```
tool/scroll_bench.sh --emit-probe          # writes lib/core/diagnostics/frame_probe.dart, prints the wiring
flutter build apk --profile --dart-define=frame_log=true
tool/scroll_bench.sh <label> [serial]      # one run
```

- **The probe is not part of the app.** `--emit-probe` writes a temporary
  `FrameProbe` that logs one `[frames] n=… late=… bsum=… bmax=… rsum=… rmax=…` line
  per second (build = Dart work, raster = GPU replay; they have different causes
  and fixes). Wire its one call in `main()` for the measurement, then delete the
  file and revert `main.dart`. A diagnostic that ships is one nobody removes.
- Only frames after the setup phase count: the log is cleared right before the
  fling phase.
- The fling is tunable through the environment (`FLING_PAIRS`, `FLING_MS`,
  `FLING_GAP`, `FLING_FROM`, `FLING_TO`). How hard the list is thrown decides how
  many rows are built in one frame; a gentle drag and a real flick are different
  tests, and a harness that only does the gentle one reports as smooth a screen
  that stutters in a hand.
- The script fails loudly when the probe never reports, rather than printing an
  empty run as a good one.
- **Coordinates are calibrated for a 1080x1920 phone** (`CARD_TAP`, the swipe
  geometry, `TAB_SWIPES=5` for the fuel tab, the 6th of 12). On another screen
  re-derive them. It targets the app id
  `page.codeberg.doyouhost.lubelogger_mobile`; the app must be installed.
- It restarts the app (`force-stop`) and clears logcat for each run, which is what
  keeps one run from leaking into the next.

## Guard in the test suite

[`test/record_list_scroll_rebuild_test.dart`](../test/record_list_scroll_rebuild_test.dart)
asserts that scrolling builds each card once, not once per frame: a frame spent
rebuilding unchanged rows is a frame the scroll does not get. It was added with
the fix for scroll jank caused by a `SliverLayoutBuilder` and the floating tab
strip ([`responsive.dart`](../lib/core/layout/responsive.dart)).
