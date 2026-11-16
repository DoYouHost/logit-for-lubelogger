import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

export 'package:dash_kit/dash_kit.dart';

/// LubeLogger's Amber Gold in the shared design system.
///
/// The inks are the lightest tones that still clear the design system's audit
/// under the accent wash (4.5:1), with a tone or two of headroom.
/// `brand_contrast_test.dart` holds the brand to that audit.
const lubeLoggerBrand = DashBrand(
  dark: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFFDFA527)),
  light: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFF7B5706)),
  onAccent: Color(0xFF1A1206),
);

/// System bar icons that contrast with a [brightness] theme.
///
/// The design system's app bar is transparent, and Flutter picks its icon
/// colour from the bar's background — a transparent one reads as dark, so a
/// light theme got white status icons on a pale screen.
SystemUiOverlayStyle logitSystemOverlay(Brightness brightness) {
  final icons = brightness == Brightness.light
      ? Brightness.dark
      : Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: brightness,
    systemNavigationBarIconBrightness: icons,
  );
}

/// The app theme for [brightness]: the shared design system plus the system
/// bar style above.
ThemeData buildLogitTheme(Brightness brightness) {
  final base = buildDashThemeData(brightness, brand: lubeLoggerBrand);
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      systemOverlayStyle: logitSystemOverlay(brightness),
    ),
  );
}

/// The wordmark's colour in the light theme. The accent fill is 2.04:1 on the
/// palest background stop and large text needs 3:1; this is the old light ink,
/// 3.98:1 there, and still reads as gold.
const lubeLoggerWordmarkLight = Color(0xFF9A6E12);

/// The wordmark's colour in a theme: the fill where it contrasts, the darker
/// gold where the background is pale.
Color lubeLoggerWordmarkInk(DashTokens t) =>
    t.brightness == Brightness.light ? lubeLoggerWordmarkLight : t.accentGold;

/// The accent under the name the screens were written with.
extension LubeLoggerAccent on DashTokens {
  Color get accentGold => accent;
  Color get accentGoldInk => accentInk;
}

/// The "Logit" wordmark: italic Manrope 800 in the gold accent. No image
/// asset exists — the mark is always set as text (see design handoff).
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 21});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Text(
      'Logit',
      style: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        color: lubeLoggerWordmarkInk(t),
      ),
    );
  }
}
