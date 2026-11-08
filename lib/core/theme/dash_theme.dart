import 'package:dash_kit/dash_kit.dart';
import 'package:material_ui/material_ui.dart';

export 'package:dash_kit/dash_kit.dart';

/// LubeLogger's Amber Gold in the shared design system.
///
/// The light ink was #9A6E12 until the design system's contrast audit measured
/// it at 3.81:1 on the light background; #835E0F is the same hue at 4.92:1.
/// `brand_contrast_test.dart` holds the brand to that audit.
const lubeLoggerBrand = DashBrand(
  dark: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFFD9A021)),
  light: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFF835E0F)),
  onAccent: Color(0xFF1A1206),
);

/// The accent under the name the screens were written with.
extension LubeLoggerAccent on DashTokens {
  Color get accentGold => accent;
  Color get accentGoldInk => accentInk;
}

/// The "LubeLogger" wordmark: italic Manrope 800 in the gold accent. No image
/// asset exists — the mark is always set as text (see design handoff).
class LubeLoggerWordmark extends StatelessWidget {
  const LubeLoggerWordmark({super.key, this.fontSize = 21});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Text(
      'LubeLogger',
      style: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        color: t.accentGold,
      ),
    );
  }
}
