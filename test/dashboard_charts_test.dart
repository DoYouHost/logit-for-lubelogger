import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/chart_range.dart';
import 'package:lubelogger_mobile/core/format/expense_timeline.dart';
import 'package:lubelogger_mobile/features/dashboard/widgets/chart_range_sheet.dart';
import 'package:lubelogger_mobile/features/dashboard/widgets/dashboard_charts.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

void main() {
  Future<void> pump(WidgetTester tester, Widget chart) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: chart)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  const labels = ['Oct', 'Nov', 'Dec', 'Jan'];
  final slots = [
    for (final l in labels) TimeSlot(axisLabel: l, title: '$l 2026'),
  ];

  /// Taps the plot of [chart] at its left or right edge (first or last slot).
  Future<void> tapSlot(WidgetTester tester, Type chart, {required bool last}) {
    final plot = find
        .descendant(of: find.byType(chart), matching: find.byType(CustomPaint))
        .first;
    final rect = tester.getRect(plot);
    return tester.tapAt(
      Offset(last ? rect.right - 2 : rect.left + 40, rect.top + 60),
    );
  }

  group('CategoryShareChart', () {
    testWidgets('lists every category, muting the ones at zero', (
      tester,
    ) async {
      await pump(
        tester,
        const CategoryShareChart(
          emptyLabel: 'nothing',
          items: [
            ShareItem(
              label: 'Fuel',
              value: 75,
              color: Colors.amber,
              valueLabel: r'$75',
            ),
            ShareItem(
              label: 'Repairs',
              value: 25,
              color: Colors.purple,
              valueLabel: r'$25',
            ),
            ShareItem(
              label: 'Tax',
              value: 0,
              color: Colors.teal,
              valueLabel: r'$0',
            ),
          ],
        ),
      );
      expect(find.text(en.catTax), findsOneWidget);
      expect(find.text(r'$0'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('25.0%'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('nothing spent in the range shows the empty label', (
      tester,
    ) async {
      await pump(
        tester,
        const CategoryShareChart(
          emptyLabel: 'nothing',
          items: [
            ShareItem(
              label: 'Fuel',
              value: 0,
              color: Colors.amber,
              valueLabel: r'$0',
            ),
          ],
        ),
      );
      expect(find.text('nothing'), findsOneWidget);
      expect(find.text(en.catFuel), findsNothing);
    });
  });

  group('UrgencyChart', () {
    List<UrgencyItem> items(int count) => [
      UrgencyItem(label: 'Past Due', count: count, color: Colors.red),
      const UrgencyItem(label: 'Not Urgent', count: 0, color: Colors.green),
    ];

    testWidgets('no reminders at all shows the empty label', (tester) async {
      await pump(tester, UrgencyChart(items: items(0), emptyLabel: 'nothing'));
      expect(find.text('nothing'), findsOneWidget);
      expect(find.text(en.urgencyPastDue), findsNothing);
    });

    testWidgets('every level gets a tile, zero included', (tester) async {
      await pump(tester, UrgencyChart(items: items(3), emptyLabel: 'nothing'));
      expect(find.text(en.urgencyPastDue), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text(en.urgencyNotUrgent), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('ExpenseDistanceChart', () {
    Widget chart(List<ExpenseSlot> data) => ExpenseDistanceChart(
      slots: slots,
      data: data,
      categoryLabels: const {
        ExpenseCategory.fuel: 'Fuel',
        ExpenseCategory.repair: 'Repairs',
      },
      currencySymbol: r'$',
      expensesLabel: 'Expenses',
      distanceLabel: 'Distance',
      distanceUnit: 'km',
      totalLabel: 'Total',
      emptyLabel: 'nothing',
    );

    testWidgets('an empty range shows the empty label', (tester) async {
      await pump(
        tester,
        chart([
          for (final _ in slots) const ExpenseSlot(costs: {}, distance: 0),
        ]),
      );
      expect(find.text('nothing'), findsOneWidget);
    });

    testWidgets('totals the range and names only the categories in it', (
      tester,
    ) async {
      await pump(
        tester,
        chart([
          const ExpenseSlot(costs: {ExpenseCategory.fuel: 40}, distance: 300),
          const ExpenseSlot(costs: {ExpenseCategory.fuel: 60}, distance: 0),
          const ExpenseSlot(costs: {}, distance: 200),
          const ExpenseSlot(costs: {}, distance: 0),
        ]),
      );
      expect(find.text(r'$100'), findsOneWidget);
      expect(find.text('500 km'), findsOneWidget);
      expect(find.text(en.catFuel), findsOneWidget);
      expect(find.text(en.catRepairs), findsNothing);
      expect(find.text('nothing'), findsNothing);
    });

    testWidgets('leaves distance out when the range has none, tooltip too', (
      tester,
    ) async {
      await pump(
        tester,
        chart([
          for (final _ in slots)
            const ExpenseSlot(costs: {ExpenseCategory.fuel: 10}, distance: 0),
        ]),
      );
      expect(find.text(en.settingsDistance), findsNothing);

      await tapSlot(tester, ExpenseDistanceChart, last: true);
      await tester.pump();
      expect(find.text('Jan 2026'), findsOneWidget);
      expect(find.text(en.settingsDistance), findsNothing);
    });

    testWidgets('an empty slot opens no tooltip', (tester) async {
      await pump(
        tester,
        chart([
          const ExpenseSlot(costs: {ExpenseCategory.fuel: 10}, distance: 0),
          for (final _ in slots.skip(1))
            const ExpenseSlot(costs: {}, distance: 0),
        ]),
      );
      await tapSlot(tester, ExpenseDistanceChart, last: true);
      await tester.pump();
      expect(find.text('Jan 2026'), findsNothing);
    });

    testWidgets('tapping a slot shows its breakdown, tapping again hides it', (
      tester,
    ) async {
      await pump(
        tester,
        chart([
          for (final _ in slots.skip(1))
            const ExpenseSlot(costs: {}, distance: 100),
          const ExpenseSlot(
            costs: {ExpenseCategory.fuel: 30, ExpenseCategory.repair: 120},
            distance: 100,
          ),
        ]),
      );

      await tapSlot(tester, ExpenseDistanceChart, last: true);
      await tester.pump();
      expect(find.text('Jan 2026'), findsOneWidget);
      expect(find.text(r'$120'), findsOneWidget);
      expect(find.text(en.chartTotal), findsOneWidget);
      expect(find.text(en.catRepairs), findsNWidgets(2)); // legend + tooltip

      await tapSlot(tester, ExpenseDistanceChart, last: true);
      await tester.pump();
      expect(find.text('Jan 2026'), findsNothing);
    });
  });

  group('EconomyChart', () {
    Widget chart(List<double?> values) => EconomyChart(
      slots: slots,
      values: values,
      average: values.whereType<double>().isEmpty ? null : 7.2,
      unitLabel: 'L/100 km',
      averageLabel: (v) => 'avg $v',
      emptyLabel: 'nothing',
    );

    testWidgets('no fill-ups in the range shows the empty label', (
      tester,
    ) async {
      await pump(tester, chart([null, null, null, null]));
      expect(find.text('nothing'), findsOneWidget);
    });

    testWidgets('a slot without a fill-up gets no tooltip, a filled one does', (
      tester,
    ) async {
      await pump(tester, chart([null, 7.0, 7.5, 7.1]));

      await tapSlot(tester, EconomyChart, last: false);
      await tester.pump();
      expect(find.text('Oct 2026'), findsNothing);

      await tapSlot(tester, EconomyChart, last: true);
      await tester.pump();
      expect(find.text('Jan 2026'), findsOneWidget);
      expect(find.text('7.1'), findsOneWidget);
    });

    testWidgets('a refresh that empties the selected slot drops the tooltip', (
      tester,
    ) async {
      await pump(tester, chart([6.9, 7.0, 7.5, 7.1]));
      await tapSlot(tester, EconomyChart, last: true);
      await tester.pump();
      expect(find.text('Jan 2026'), findsOneWidget);

      await pump(tester, chart([6.9, 7.0, 7.5, null]));
      expect(find.text('Jan 2026'), findsNothing);
    });

    testWidgets('keeps its height when data replaces the empty state', (
      tester,
    ) async {
      Future<double> heightOf(Widget w) async {
        await pump(tester, Center(child: w));
        return tester.getSize(find.byType(EconomyChart)).height;
      }

      expect(
        await heightOf(chart([null, null, null, null])),
        await heightOf(chart([6.5, 7.0, null, 8.0])),
      );
    });
  });

  group('range sheet', () {
    Future<ChartRange?> open(
      WidgetTester tester, {
      required ChartRange current,
      required Future<void> Function() choose,
    }) async {
      late Future<ChartRange?> result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showChartRangeSheet(
                context,
                chartTitle: 'Fuel Mileage',
                current: current,
                defaultPreset: ChartRangePreset.threeMonths,
                currentWindow: current.resolve(DateTime.now()),
                formatDate: (d) => '${d.day}/${d.month}',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await choose();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('marks the default and returns the preset tapped', (
      tester,
    ) async {
      final picked = await open(
        tester,
        current: const PresetRange(ChartRangePreset.threeMonths),
        choose: () async {
          expect(find.text(en.chartRangeDefault), findsOneWidget);
          await tester.tap(find.text(en.chartRangeSixMonths));
        },
      );
      expect(picked, const PresetRange(ChartRangePreset.sixMonths));
    });

    testWidgets('shows the dates of a custom range', (tester) async {
      final picked = await open(
        tester,
        current: CustomRange(DateTime(2026, 7, 15), DateTime(2026, 9, 14)),
        choose: () async {
          expect(find.text('15/7 – 14/9'), findsOneWidget);
          await tester.tapAt(const Offset(10, 10)); // dismiss
        },
      );
      expect(picked, isNull);
    });
  });

  test('a custom range chip names both dates', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final now = DateTime(2026, 9, 14);
    expect(
      chartRangeChipLabel(
        CustomRange(DateTime(2026, 7, 15), DateTime(2026, 9, 14)),
        l10n,
        now,
      ),
      'Jul 15 – Sep 14',
    );
    expect(
      chartRangeChipLabel(
        CustomRange(DateTime(2025, 11, 1), DateTime(2026, 2, 1)),
        l10n,
        now,
      ),
      'Nov 1, 2025 – Feb 1, 2026',
    );
    expect(
      chartRangeChipLabel(
        CustomRange(DateTime(2025, 8, 20), DateTime(2025, 8, 10)),
        l10n,
        now,
      ),
      'Aug 10 – Aug 20, 2025',
    );
  });

  test('axis steps land on round numbers', () {
    expect(niceAxisInterval(1970, divisions: 3), 500);
    expect(niceAxisInterval(2.4, divisions: 3), 1);
  });
}
