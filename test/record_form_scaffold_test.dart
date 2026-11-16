import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:lubelogger_mobile/features/vehicle/forms/record_form_scaffold.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

final en = AppLocalizationsEn();

/// A landscape tablet leaves a sheet about 720 dp of height; the vehicle form
/// is taller than that, and its buttons used to scroll away with the fields.
void main() {
  const screen = Size(1280, 500);
  final lastField = find.widgetWithText(TextFormField, 'Field 19');

  Future<void> openForm(
    WidgetTester tester, {
    required int fieldCount,
    required VoidCallback onCancel,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildDashThemeData(Brightness.dark, brand: lubeLoggerBrand),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => dashSheet<void>(
              context,
              builder: (_) => RecordFormScaffold(
                formKey: GlobalKey<FormState>(),
                title: 'Title',
                isEditing: false,
                submitting: false,
                onCancel: onCancel,
                onSubmit: () {},
                onDelete: null,
                error: null,
                fields: [
                  for (var i = 0; i < fieldCount; i++)
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Field $i'),
                    ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a form taller than the screen keeps its buttons on screen', (
    tester,
  ) async {
    var cancelled = false;
    await openForm(tester, fieldCount: 20, onCancel: () => cancelled = true);

    expect(tester.getRect(lastField).top, greaterThan(screen.height));
    expect(
      tester.getRect(find.byType(FilledButton)).bottom,
      lessThanOrEqualTo(screen.height),
    );
    await tester.tap(find.text(en.actionCancel));
    expect(cancelled, isTrue);
  });

  testWidgets('the last field is still reachable by scrolling', (tester) async {
    await openForm(tester, fieldCount: 20, onCancel: () {});

    // Every text field carries a Scrollable of its own; the sheet's is the
    // first one under its scroll view.
    final sheetScroll = find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(lastField, 200, scrollable: sheetScroll);
    expect(
      tester.getRect(lastField).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(FilledButton)).top),
    );
  });

  testWidgets('a short form wraps its content instead of filling the screen', (
    tester,
  ) async {
    await openForm(tester, fieldCount: 1, onCancel: () {});

    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(sheet.height, lessThan(screen.height * 0.75));
    expect(
      tester.getRect(find.byType(FilledButton)).bottom,
      lessThanOrEqualTo(screen.height),
    );
  });
}
