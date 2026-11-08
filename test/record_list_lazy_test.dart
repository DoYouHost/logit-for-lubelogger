import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_list.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';

/// A record tab must not pay for records nobody is looking at. The list used to
/// be one box holding every card inside the scroll view, which the viewport can
/// neither skip nor cull — a vehicle with hundreds of fill-ups then laid out and
/// painted all of them, and the scroll stuttered for it.
void main() {
  const total = 500;

  Widget harness() => MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: RecordsTabBody<int>(
        async: AsyncValue.data(List.generate(total, (i) => i)),
        onRefresh: () async {},
        emptyIcon: Icons.speed,
        emptyLabel: 'nothing here',
        builder: (records, _) => RecordsContent(
          count: records.length,
          card: (context, index) =>
              RecordCard(date: 'row $index', headline: '$index'),
        ),
      ),
    ),
  );

  testWidgets('only the cards on screen are built', (tester) async {
    await tester.pumpWidget(harness());

    final built = find.byType(RecordCard).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(50));
  });

  testWidgets('every record is still reachable by scrolling', (tester) async {
    await tester.pumpWidget(harness());

    await tester.scrollUntilVisible(
      find.text('row ${total - 1}'),
      1000,
      scrollable: find.byType(Scrollable),
      maxScrolls: 200,
    );
    expect(find.text('row ${total - 1}'), findsOneWidget);
  });
}
