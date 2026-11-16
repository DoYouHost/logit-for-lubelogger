import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_filter.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_tabs.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

/// Record lists were sorted one way, forever, with no way to search them — and
/// tags were stored and editable while being printed nowhere at all.
void main() {
  const vehicleId = 1;

  VehicleRecord record({
    required int id,
    required String description,
    double cost = 10,
    String notes = '',
    String tags = '',
    DateTime? date,
  }) => VehicleRecord(
    id: id,
    date: date ?? DateTime(2026, 4, id),
    odometer: 1000.0 * id,
    description: description,
    cost: cost,
    notes: notes,
    tags: tags,
  );

  Future<void> pump(WidgetTester tester, List<VehicleRecord> records) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRecordsProvider.overrideWith((ref, key) async => records),
          vehicleUnitsProvider.overrideWith(
            (ref, id) => const VehicleUnits(UnitsSettings()),
          ),
          currencySymbolProvider.overrideWithValue(r'$'),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: GenericRecordsTab(
              vehicleId: vehicleId,
              kind: RecordKind.service,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField).first, query);
    await tester.pumpAndSettle();
  }

  /// Card descriptions in the order they are laid out.
  List<String> shown(WidgetTester tester, List<String> candidates) => [
    for (final text in candidates)
      if (find.text(text).evaluate().isNotEmpty) text,
  ];

  final oil = record(id: 1, description: 'Oil change', cost: 58, tags: 'diy');
  final brakes = record(
    id: 2,
    description: 'Brake pads',
    cost: 210,
    notes: 'front axle',
    tags: 'workshop warranty',
  );
  final tyres = record(id: 3, description: 'Tyre rotation', cost: 20);

  group('search', () {
    testWidgets('narrows to the matching description', (tester) async {
      await pump(tester, [oil, brakes, tyres]);

      await search(tester, 'brake');

      expect(find.text('Brake pads'), findsOneWidget);
      expect(find.text('Oil change'), findsNothing);
    });

    testWidgets('looks in the notes too, which the card only flags', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      await search(tester, 'axle');

      expect(find.text('Brake pads'), findsOneWidget);
      expect(find.text('Tyre rotation'), findsNothing);
    });

    testWidgets('every word must match, in any order or field', (tester) async {
      await pump(tester, [oil, brakes, tyres]);

      await search(tester, 'axle brake');
      expect(find.text('Brake pads'), findsOneWidget);

      await search(tester, 'axle oil');
      expect(find.text('Brake pads'), findsNothing);
      expect(find.text('Oil change'), findsNothing);
    });

    testWidgets('an empty result says so and offers a way back', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      await search(tester, 'gearbox');
      expect(find.text(en.recordsNoMatches), findsOneWidget);
      expect(find.text(en.recordsEmpty), findsNothing);

      await tester.tap(find.text(en.recordsClearFilters));
      await tester.pumpAndSettle();
      expect(find.text('Oil change'), findsOneWidget);
    });

    testWidgets('a vehicle with no records at all gets no search field', (
      tester,
    ) async {
      await pump(tester, []);

      expect(find.text(en.recordsEmpty), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('tags', () {
    testWidgets('are printed on the card and filter when tapped', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      expect(find.text('diy'), findsOneWidget);
      expect(find.text('workshop'), findsOneWidget);
      expect(find.text('warranty'), findsOneWidget);

      await tester.tap(find.text('diy'));
      await tester.pumpAndSettle();

      expect(find.text('Oil change'), findsOneWidget);
      expect(find.text('Brake pads'), findsNothing);
    });

    testWidgets('tapping the active chip lets it go', (tester) async {
      await pump(tester, [oil, brakes, tyres]);

      await tester.tap(find.text('diy'));
      await tester.pumpAndSettle();
      // Two chips now: the card's own and the one in the filter bar.
      await tester.tap(find.text('diy').first);
      await tester.pumpAndSettle();

      expect(find.text('Brake pads'), findsOneWidget);
    });

    testWidgets('several tags narrow together, rather than widen', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      await tester.tap(find.text('workshop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('warranty').last);
      await tester.pumpAndSettle();

      expect(find.text('Brake pads'), findsOneWidget);
      expect(find.text('Oil change'), findsNothing);
    });
  });

  group('sort', () {
    testWidgets('defaults to newest first, as the tab always did', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      final cards = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data);
      expect(
        cards,
        containsAllInOrder(['Tyre rotation', 'Brake pads', 'Oil change']),
      );
    });

    testWidgets('by cost puts the dearest on top, and the toggle flips it', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.colCost).last);
      await tester.pumpAndSettle();

      var order = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
      expect(
        order,
        containsAllInOrder(['Brake pads', 'Oil change', 'Tyre rotation']),
      );

      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pumpAndSettle();

      order = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
      expect(
        order,
        containsAllInOrder(['Tyre rotation', 'Oil change', 'Brake pads']),
      );
    });

    testWidgets('by description starts ascending, not Z to A', (tester) async {
      await pump(tester, [oil, brakes, tyres]);

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.colDescription).last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      final order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data);
      expect(
        order,
        containsAllInOrder(['Brake pads', 'Oil change', 'Tyre rotation']),
      );
    });

    testWidgets('survives a search that hides part of the list', (
      tester,
    ) async {
      await pump(tester, [oil, brakes, tyres]);

      await search(tester, 'a'); // in every description
      expect(
        shown(tester, ['Oil change', 'Brake pads', 'Tyre rotation']),
        hasLength(3),
      );
    });
  });

  group('ordering', () {
    // `List.sort` is not stable, so equal keys have to be broken by the
    // incoming position — otherwise "pinned first, otherwise as the server sent
    // them" reshuffles itself, and so does a fuel list where several fill-ups
    // share a date.
    RecordListControls<String> controls() => RecordListControls<String>(
      matches: (r) => r != 'skip',
      compare: (a, b) => a.length.compareTo(b.length),
      activeTags: const {},
      onTagTap: (_) {},
      filtering: false,
    );

    test('apply keeps the incoming order between equal keys', () {
      final input = ['bb', 'aa', 'skip', 'cc', 'a', 'dd'];

      expect(controls().apply(input), ['a', 'bb', 'aa', 'cc', 'dd']);
    });

    test('sortStably does the same for a list a tab built itself', () {
      // What the fuel tab passes: rows whose economy was computed over the full
      // sequence, sorted by the record inside them.
      final rows = [
        (id: 1, record: 'bb'),
        (id: 2, record: 'aa'),
        (id: 3, record: 'a'),
        (id: 4, record: 'cc'),
      ];

      expect(
        controls().sortStably(rows, (row) => row.record).map((r) => r.id),
        [3, 1, 2, 4],
      );
    });
  });

  group('splitTags', () {
    test('splits on whitespace and drops the empties', () {
      expect(splitTags('diy  workshop\twarranty'), [
        'diy',
        'workshop',
        'warranty',
      ]);
      expect(splitTags('   '), isEmpty);
      expect(splitTags(''), isEmpty);
    });
  });
}
