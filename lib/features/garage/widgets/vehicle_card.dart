import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/formatters.dart';
import '../../../core/models/vehicle_info.dart';
import '../../../core/settings/units_settings.dart';
import '../../../core/format/vehicle_units.dart';
import '../../../core/theme/dash_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/diagnostics/image_probe.dart';
import '../../common/vehicle_image.dart';

/// A single vehicle in the garage list (design screen #2): a photo with floating
/// odometer + cost badges, then year / make-model / plate below.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.info,
    required this.baseUrl,
    required this.apiKey,
    required this.currencySymbol,
    required this.units,
    this.onTap,
  });

  final VehicleInfo info;
  final String baseUrl;
  final String? apiKey;
  final String currencySymbol;
  final UnitsSettings units;
  final VoidCallback? onTap;

  static const double _photoHeight = 210;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final v = info.vehicle;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: t.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _photo(t),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DashSpace.lg,
                    DashSpace.lg,
                    DashSpace.lg,
                    DashSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (v.year > 0) Text('${v.year}', style: _sub(t)),
                      Text(
                        v.makeModel,
                        style: TextStyle(
                          fontFamily: DashTokens.fontUi,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: t.textPrimary,
                        ),
                      ),
                      if (v.licensePlate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: DashSpace.xs),
                          child: Text(v.licensePlate, style: _sub(t)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(DashTokens t) => Stack(
    children: [
      SizedBox(height: _photoHeight, width: double.infinity, child: _image(t)),
      Positioned(
        top: 12,
        left: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Badge(
              icon: Icons.speed,
              label: VehicleUnits(
                units,
                useHours: info.vehicle.useHours,
              ).distance(info.lastReportedOdometer),
            ),
            const SizedBox(height: DashSpace.sm),
            _Badge(
              icon: Icons.payments_outlined,
              label: Formatters.currency(info.totalCost, currencySymbol),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _image(DashTokens t) {
    final placeholder = ColoredBox(
      color: t.subCard,
      child: Center(
        child: Icon(Icons.directions_car, size: 56, color: t.textTertiary),
      ),
    );
    if (info.vehicle.imageLocation.isEmpty) return placeholder;
    // The cell width decides how much of the photo is worth decoding, and it
    // varies with the column count, so it is measured rather than assumed.
    return LayoutBuilder(
      builder: (context, constraints) => Image(
        image: vehicleImageProvider(
          imageLocation: info.vehicle.imageLocation,
          baseUrl: baseUrl,
          apiKey: apiKey,
          cacheWidth:
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round(),
        ),
        fit: BoxFit.cover,
        errorBuilder: ImageProbe.errorBuilder(placeholder),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : ColoredBox(color: t.subCard),
      ),
    );
  }

  TextStyle _sub(DashTokens t) => TextStyle(
    fontFamily: DashTokens.fontUi,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: t.textTertiary,
  );
}

/// Dark translucent pill overlaid on the vehicle photo.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashSpace.md,
        vertical: DashSpace.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: DashSpace.sm),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DashTokens.fontMono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed "add a vehicle" tile shown at the bottom of the garage list.
class AddVehicleTile extends StatelessWidget {
  const AddVehicleTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    // Tagged where the tile is defined, so both places that use it — the grid
    // and the empty garage — are named by this one line.
    return logTag(
      'garage.add',
      // The tile is an icon alone, so its name is the action it performs.
      Semantics(
        label: AppLocalizations.of(context).formVehicleTitle,
        child: SizedBox(
          height: 200,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: t.subCardBorder,
                  radius: 16,
                ),
                child: Center(
                  child: Icon(Icons.add, size: 44, color: t.accentGold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a rounded dashed rectangle border (the add tile's outline).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
