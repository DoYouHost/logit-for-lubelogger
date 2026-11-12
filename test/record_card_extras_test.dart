import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/format/vehicle_units.dart';
import 'package:lubelogger_mobile/core/models/attachment.dart';
import 'package:lubelogger_mobile/core/models/vehicle_record.dart';
import 'package:lubelogger_mobile/core/settings/units_settings.dart';
import 'package:lubelogger_mobile/features/vehicle/widgets/record_tabs.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

/// A record's attachments and its note are stored, editable — and used to be
/// invisible on the card, so the only way to learn a record had photos on it
/// was to open the edit form and look.
void main() {
  const vehicleId = 1;

  VehicleRecord record({required int id, int files = 0, String notes = ''}) =>
      VehicleRecord(
        id: id,
        date: DateTime(2026, 4, 5),
        odometer: 1000,
        description: 'record $id',
        cost: 10,
        notes: notes,
        tags: '',
        files: [
          for (var i = 0; i < files; i++)
            Attachment(name: 'f$i.jpg', location: '/documents/f$i.jpg'),
        ],
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

  testWidgets('a record with files says how many', (tester) async {
    await pump(tester, [record(id: 1, files: 3)]);

    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip(en.cardAttachments(3)), findsOneWidget);
  });

  testWidgets('a record with a note is flagged, without printing it', (
    tester,
  ) async {
    await pump(tester, [record(id: 1, notes: 'ordered the wrong filter')]);

    expect(find.byIcon(Icons.notes), findsOneWidget);
    expect(find.byTooltip(en.cardHasNote), findsOneWidget);
    // The note is a flag, not content: the card would otherwise show two blocks
    // of prose (description + note) and stop being scannable.
    expect(find.text('ordered the wrong filter'), findsNothing);
  });

  testWidgets('a bare record carries neither marker', (tester) async {
    await pump(tester, [record(id: 1)]);

    expect(find.byIcon(Icons.attach_file), findsNothing);
    expect(find.byIcon(Icons.notes), findsNothing);
  });

  testWidgets('whitespace is not a note', (tester) async {
    await pump(tester, [record(id: 1, notes: '   \n ')]);

    expect(find.byIcon(Icons.notes), findsNothing);
  });
}
