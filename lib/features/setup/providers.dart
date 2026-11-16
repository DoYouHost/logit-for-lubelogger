import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exceptions.dart';
import '../../core/auth/whoami.dart';
import '../../core/demo/demo_config.dart';
import '../../core/settings/server_profile.dart';
import '../../providers.dart';

/// Validation errors raised by the setup screen itself (distinct from an
/// [AppApiException] from the network layer). Translated in the UI.
enum SetupErrorCode { missingUrl, missingApiKey }

class SetupState {
  const SetupState({this.busy = false, this.error});

  final bool busy;

  /// A [SetupErrorCode] or an [AppApiException]; translated on display.
  final Object? error;

  SetupState copyWith({bool? busy, Object? error}) =>
      SetupState(busy: busy ?? this.busy, error: error);
}

final setupControllerProvider =
    NotifierProvider.autoDispose<SetupController, SetupState>(
      SetupController.new,
    );

/// Drives the login screen: validate input, verify the API key against
/// `GET /api/whoami`, then persist the profile (which flips the router to the
/// app — see `router.dart`).
class SetupController extends Notifier<SetupState> {
  @override
  SetupState build() => const SetupState();

  Future<void> connect({required String rawUrl, required String apiKey}) async {
    final url = ServerProfile.normalizeBaseUrl(rawUrl);
    // The scheme is the diagnosis for a whole class of "it will not connect"
    // reports — the address itself is the user's and never goes in. A recording
    // started on this screen has no server profile yet, so the session header
    // cannot carry it either.
    _log(
      'sign_in',
      fields: {
        'scheme': Uri.tryParse(url)?.scheme,
        'demo': DemoConfig.isDemoUrl(url) ? true : null,
      },
    );
    if (url.isEmpty) {
      state = state.copyWith(error: SetupErrorCode.missingUrl);
      _log('sign_in_rejected', fields: {'reason': 'missingUrl'});
      return;
    }
    if (apiKey.trim().isEmpty) {
      state = state.copyWith(error: SetupErrorCode.missingApiKey);
      _log('sign_in_rejected', fields: {'reason': 'missingApiKey'});
      return;
    }
    // Demo mode (store review): recognized locally, no network probe. The
    // fabricated backend serves everything; the magic token is the "API key".
    if (DemoConfig.isDemoUrl(url)) {
      if (apiKey.trim() != DemoConfig.token) {
        state = state.copyWith(
          error: const AuthException(AppErrorCode.apiKeyRejected),
        );
        _log('sign_in_rejected', fields: {'reason': 'demoToken'});
        return;
      }
      await ref.read(credentialsStoreProvider).writeApiKey(DemoConfig.token);
      await ref
          .read(serverProfileProvider.notifier)
          .save(
            const ServerProfile(baseUrl: DemoConfig.baseUrl, label: 'Demo'),
          );
      return;
    }
    state = const SetupState(busy: true);
    try {
      final result = await ref
          .read(authServiceProvider)
          .verifyAndStoreApiKey(baseUrl: url, apiKey: apiKey.trim());
      await _saveProfile(result.baseUrl, result.who);
      _log('sign_in_ok');
    } on AppApiException catch (e) {
      state = SetupState(error: e);
      // The app's verdict, which the request alone does not give: LubeLogger
      // answers 401 both for a wrong key and for a key without the scope, and
      // that difference is the whole of some reports.
      _log(
        'sign_in_failed',
        lvl: LogLevel.warn,
        fields: {'reason': e.code.name, 'status': e.statusCode},
      );
    }
  }

  /// Nothing here carries the address or the key — see the field notes above.
  void _log(
    String evt, {
    LogLevel lvl = LogLevel.info,
    Map<String, Object?> fields = const {},
  }) => DiagnosticRecorder.active?.add(
    LogSource.app,
    evt,
    lvl: lvl,
    fields: fields,
  );

  /// Saving the profile switches the router to the app shell (see routerProvider).
  Future<void> _saveProfile(String url, WhoAmI who) => ref
      .read(serverProfileProvider.notifier)
      .save(
        ServerProfile(
          baseUrl: url,
          label: who.displayName.isEmpty ? null : who.displayName,
        ),
      );
}
