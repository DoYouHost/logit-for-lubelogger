# Vehicle dashboard and its charts

How the dashboard (first tab of the vehicle screen) picks chart date ranges,
buckets data, and draws and colours the charts. **Read it before changing
chart ranges, bucket rules, chart colours, or adding a chart.**

Code: [`dashboard_screen.dart`](../lib/features/dashboard/dashboard_screen.dart),
[`widgets/dashboard_charts.dart`](../lib/features/dashboard/widgets/dashboard_charts.dart),
[`widgets/chart_range_sheet.dart`](../lib/features/dashboard/widgets/chart_range_sheet.dart),
[`widgets/chart_palette.dart`](../lib/features/dashboard/widgets/chart_palette.dart),
[`core/format/chart_range.dart`](../lib/core/format/chart_range.dart). Range
state is in [`providers.dart`](../lib/providers.dart)
(`chartDefaultRangeProvider`, `chartRangeOverridesProvider`, `chartRangeProvider`).

## Ranges

- **Presets are 1, 3, 6 and 12 months, plus a custom range.** The default is
  3 months, stored in preferences as the preset name under `chart_default_range`
  and set in Settings, "Charts" section. **A custom range cannot be the default**:
  it names specific dates, so only `ChartRangePreset` is persisted.
- **A per-chart override is keyed by vehicle and chart** (`ChartKey`): a custom
  range fitted to one vehicle's history is usually empty on another.
- **Overrides live in memory only** (lost on restart) and are **cleared whenever
  the default changes**, otherwise a new default the charts did not follow would
  look like the setting did nothing. Picking the default preset on a chart removes
  its override.
- **The reminders chart has no range**: it shows the current state, not history.
  The switchable charts are `DashboardChart.expensesByType`, `expensesDistance`
  and `economy`.
- The range is chosen from a chip in the card header that opens a bottom sheet
  (`showChartRangeSheet`).

## Buckets

`bucketFor` splits a window into slots by its length, so a chart never has a
handful of slots or several dozen:

- up to 93 days: **weeks**, starting on the locale's first weekday;
- up to 24 calendar months: **months**;
- longer: **quarters**.

A preset snaps its start to a bucket boundary so the first slot is not a sliver
(whole calendar months including the current one, or the first week start inside
the span). A custom range is exact, so its edge slots are partial
(`ChartWindow.daysOf`). Covered by `test/chart_range_test.dart` and
`test/chart_range_providers_test.dart`.

## Chart forms and why

Charts are drawn with `CustomPainter`; there is no `fl_chart` dependency. It
could not do gaps between segments or swatch tooltips.

- **Expenses by type**: one 100% bar with 2 px gaps plus a row per category
  (amount and share). Zero categories stay listed, muted, so rows do not jump as
  the range changes.
- **Expenses and distance**: bars stacked by category over a **separate distance
  panel**, sharing the time axis but not a value axis. No dual axis. The distance
  panel is dropped when the range has no distance.
- **Economy**: a line with dots, axis cropped to the data (only a line reads
  honestly off a cropped scale). The line is **joined across slots without a
  fill-up** and dots mark real fill-ups. Refuelling every few weeks (the demo data
  does) leaves most week slots empty, and a line broken at each gap rendered as
  lone dots. For the same reason distance is columns, not a line.
- **Reminders by urgency**: a proportion bar over one tile per level, most urgent
  first; past due uses the theme's danger colour.
- **Stat block** at the top: one list card (icon chip, label, mono value, the
  odometer's date under its label) with a gold glow in the corner; two columns
  only once each has room for a long label beside a long value.
- Slots are tappable and show a tooltip with the breakdown.
- Off-screen charts are left unbuilt; a chart is expensive to lay out and paint,
  and on a phone at most two are in view.

## Colours

- **`chartCategoryOrder` and the swatches in `chart_palette.dart` were validated
  for colour-blind separation between neighbours, in that order.** Do not reorder
  or re-tint without re-running a colour-blind/contrast check on the new set.
  Each category has separate dark and light values; none is a status colour (tax
  used to borrow the danger colour and read as an error).
- The economy line uses the brand gold on dark but a darker gold on light, where
  the brand colour is too pale for a 2 px line.
- Rank colouring, dual axes and cropped bars were rejected as forms; keep to
  that when adding charts.

## Data

All three switchable charts read shared providers, so they agree:
`gasStatsProvider`, `expenseTimelineProvider` and `odometerReadingsProvider`
(fuel-ups plus dedicated odometer readings, so a fuel-only vehicle still has a
distance timeline). The dashboard's "last odometer" date comes from the same
timeline, not from the server's `lastReportedOdometer`, which also counts
service, repair and upgrade mileage.
