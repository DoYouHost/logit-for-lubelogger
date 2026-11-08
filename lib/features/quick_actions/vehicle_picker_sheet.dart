import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_diagnostics/app_diagnostics.dart';

import '../../core/models/vehicle.dart';
import '../../core/models/vehicle_info.dart';
import '../../core/theme/dash_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../core/diagnostics/image_probe.dart';
import '../common/vehicle_image.dart';

/// Asks the user which vehicle a quick-action record should be added to.
/// Resolves to the chosen vehicle id, or `null` if dismissed. Only shown when
/// there's more than one vehicle (a single vehicle is auto-selected upstream).
Future<int?> showVehiclePicker(
  BuildContext context,
  List<VehicleInfo> vehicles,
) {
  return dashSheet<int>(
    context,
    scrollControlled: false,
    builder: (_) => _VehiclePickerSheet(vehicles: vehicles),
  );
}

class _VehiclePickerSheet extends ConsumerWidget {
  const _VehiclePickerSheet({required this.vehicles});

  final List<VehicleInfo> vehicles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = DashTokens.of(context);
    final baseUrl = ref.watch(serverProfileProvider)?.baseUrl ?? '';
    final apiKey = ref.watch(apiKeyProvider).value;

    // Bottom inset only — the sheet is centered via its width constraint, so a
    // landscape cutout inset on the notch side would push the list off-centre.
    return logSurface(
      'quick_action.picker',
      SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DashSpace.xl,
                DashSpace.xs,
                DashSpace.xl,
                DashSpace.md,
              ),
              child: Text(
                l10n.quickActionSelectVehicle,
                style: TextStyle(
                  fontFamily: DashTokens.fontUi,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: DashSpace.sm),
                itemCount: vehicles.length,
                itemBuilder: (context, i) {
                  final vehicle = vehicles[i].vehicle;
                  return ListTile(
                    leading: _Avatar(
                      vehicle: vehicle,
                      baseUrl: baseUrl,
                      apiKey: apiKey,
                    ),
                    title: Text(
                      _name(vehicle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: DashTokens.fontUi,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    subtitle: vehicle.licensePlate.isEmpty
                        ? null
                        : Text(
                            vehicle.licensePlate,
                            style: TextStyle(
                              fontFamily: DashTokens.fontUi,
                              fontSize: 13,
                              color: t.textTertiary,
                            ),
                          ),
                    onTap: () => Navigator.of(context).pop(vehicle.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Year Make Model", falling back to the plate then the id.
  String _name(Vehicle v) {
    final label = [
      if (v.year > 0) '${v.year}',
      v.makeModel,
    ].where((s) => s.isNotEmpty).join(' ');
    if (label.isNotEmpty) return label;
    return v.licensePlate.isNotEmpty ? v.licensePlate : '#${v.id}';
  }
}

/// Small circular vehicle photo (or a car glyph placeholder), authenticated
/// with the API key header — mirrors the vehicle screen's avatar.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.vehicle, required this.baseUrl, this.apiKey});

  final Vehicle vehicle;
  final String baseUrl;
  final String? apiKey;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final placeholder = Icon(
      Icons.directions_car,
      size: 20,
      color: t.textTertiary,
    );
    final image = vehicle.imageLocation;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: t.subCard,
        shape: BoxShape.circle,
        border: Border.all(color: t.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isEmpty
          ? Center(child: placeholder)
          : Image(
              image: vehicleImageProvider(
                imageLocation: image,
                baseUrl: baseUrl,
                apiKey: apiKey,
                cacheWidth: (40 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
              ),
              fit: BoxFit.cover,
              errorBuilder: ImageProbe.errorBuilder(Center(child: placeholder)),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const SizedBox.shrink(),
            ),
    );
  }
}
