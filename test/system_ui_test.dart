import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/theme/dash_theme.dart';
import 'package:material_ui/material_ui.dart';

/// The design system's app bar is transparent, which Flutter reads as a dark
/// background: a light theme got white status bar icons on a pale screen.
void main() {
  Future<SystemUiOverlayStyle> statusBarStyle(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLogitTheme(brightness),
        home: Scaffold(appBar: AppBar(title: const Text('t'))),
      ),
    );
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    );
    return region.value;
  }

  testWidgets('light theme gets dark status bar icons', (tester) async {
    final style = await statusBarStyle(tester, Brightness.light);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  testWidgets('dark theme gets light status bar icons', (tester) async {
    final style = await statusBarStyle(tester, Brightness.dark);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });
}
