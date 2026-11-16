import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubelogger_mobile/core/cache/write_queue.dart';
import 'package:lubelogger_mobile/features/sync/pending_write_label.dart';
import 'package:lubelogger_mobile/features/sync/sync_sheet.dart';
import 'package:lubelogger_mobile/l10n/app_localizations.dart';
import 'package:lubelogger_mobile/l10n/app_localizations_en.dart';
import 'package:lubelogger_mobile/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lubelogger_mobile/core/models/vehicle_tab.dart';
import 'package:lubelogger_mobile/features/common/vehicle_tab_ui.dart';

/// The copy the tests render in, read rather than spelled out.
final en = AppLocalizationsEn();

/// A write held on the phone is invisible everywhere else in the app — the list
/// it belongs to still shows what the server has — so what the sheet says about
/// it is the only account the user gets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PendingWrite write(String path, {String method = 'POST', String? error}) =>
      PendingWrite(
        id: path,
        method: method,
        path: path,
        query: const {},
        body: const {},
        queuedAt: DateTime(2026, 3, 1),
        lastError: error,
      );

  group('naming a queued write', () {
    final l10n = AppLocalizationsEn();

    test('reads its record type off the path, as the tabs name it', () {
      expect(
        describePendingWrite(write('/api/vehicle/gasrecords/add'), l10n),
        'Add ${l10n.catFuel}',
      );
      expect(
        describePendingWrite(
          write('/api/vehicle/servicerecords/update', method: 'PUT'),
          l10n,
        ),
        'Edit ${l10n.catService}',
      );
      expect(
        describePendingWrite(
          write('/api/vehicle/odometerrecords/delete', method: 'DELETE'),
          l10n,
        ),
        'Delete ${l10n.tabOdometer}',
      );
      expect(
        describePendingWrite(write('/api/vehicles/add'), l10n),
        'Add ${l10n.syncTypeVehicle}',
      );
    });

    test('falls back to the path for an endpoint it has never heard of', () {
      expect(
        describePendingWrite(write('/api/vehicle/newthings/add'), l10n),
        'Add newthings',
      );
    });
  });

  testWidgets('the sheet counts what is waiting and names each one', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = WriteQueue(prefs);
    await queue.add(method: 'POST', path: '/api/vehicle/gasrecords/add');
    await queue.add(method: 'DELETE', path: '/api/vehicle/notes/delete');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showSyncSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(en.syncPendingCount(2)), findsOneWidget);
    expect(find.text(en.syncOpAdd(VehicleTab.fuel.label(en))), findsOneWidget);
    expect(
      find.text(en.syncOpDelete(VehicleTab.note.label(en))),
      findsOneWidget,
    );
    expect(find.text(en.syncSendNow), findsOneWidget);
  });

  testWidgets('a refused write is set apart, with the reason and a way out', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = WriteQueue(prefs);
    await queue.reject(
      write('/api/vehicle/planrecords/update', method: 'PUT'),
      'Progress cannot be set to Done.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    showSyncSheet(context);
    await tester.pumpAndSettle();

    expect(find.text(en.syncRejectedTitle), findsOneWidget);
    expect(find.text('Progress cannot be set to Done.'), findsOneWidget);
    // Nothing is queued, so the sheet must not offer to send anything.
    expect(find.text(en.syncSendNow), findsNothing);

    await tester.tap(find.text(en.syncDiscard).first);
    await tester.pumpAndSettle();
    expect(find.text(en.syncRejectedTitle), findsNothing);
    expect(queue.rejected, isEmpty);
  });
}
