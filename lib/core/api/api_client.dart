import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_util/app_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/credentials_store.dart';
import '../cache/http_cache.dart';
import '../cache/offline_interceptor.dart';
import '../cache/write_queue.dart';
import '../demo/demo_backend.dart';
import '../diagnostics/report_config.dart';
import '../settings/server_profile.dart';
import 'retry_interceptor.dart';

/// Header LubeLogger uses to return culture-invariant payloads: typed JSON and
/// ISO-8601 dates instead of locale-formatted strings. Sent on every request so
/// parsing never depends on the server's locale. See docs/api-server.md.
const String kCultureInvariantHeader = 'culture-invariant';

/// Dio spends `sendTimeout` on the whole body in one `addStream`, so for an
/// upload it caps file size, not latency: 7 MB up a 3 Mbps link needs ~20 s,
/// which the 15 s below reported as an unreachable server.
const Duration kUploadSendTimeout = Duration(minutes: 3);
const Duration kUploadReceiveTimeout = Duration(minutes: 1);

/// Bare Dio for calls without auth and as the base for [ApiClient]. Single place
/// for timeouts.
///
/// [HttpProbe] goes on here rather than in [ApiClient] so it also covers the
/// login probe (which runs before there is a profile) and the reminder worker's
/// own client. It writes nothing unless a diagnostic recording is running.
Dio createBareDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ),
)..interceptors.add(HttpProbe(config: lubeloggerHttpProbe));

/// Authenticated HTTP client for a single [ServerProfile].
class ApiClient {
  ApiClient({
    required ServerProfile profile,
    required CredentialsStore credentials,
    WriteQueue? queue,
    OfflineStatus? status,
    Dio? dio,
  }) : dio = dio ?? createBareDio(),
       cache = HttpCache(baseUrl: profile.baseUrl),
       status = status ?? OfflineStatus() {
    this.dio.options.baseUrl = profile.baseUrl;
    this.dio.interceptors.add(AuthInterceptor(credentials: credentials));
    if (kDebugMode) {
      this.dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
    // Demo profile: serve everything from the in-process fake server, so no
    // request ever leaves the device. Covers every consumer of this Dio.
    if (profile.isDemo) {
      this.dio.httpClientAdapter = DemoHttpClientAdapter(
        DemoBackend.instance.handle,
        uploads: DemoBackend.instance.upload,
        latency: const Duration(milliseconds: 140),
      );
    }
    // Ahead of the offline interceptor on purpose: a transient failure gets its
    // second attempt before it is allowed to count as the server being gone.
    this.dio.interceptors.add(
      RetryInterceptor(dio: this.dio, status: this.status),
    );
    // The demo backend cannot fail and its data lives in memory already, so
    // caching it would only leave a real server's directory shape on disk for a
    // profile that is not a server.
    if (queue != null && !profile.isDemo) {
      this.dio.interceptors.add(
        OfflineInterceptor(cache: cache, queue: queue, status: this.status),
      );
    }
  }

  final Dio dio;

  /// Stored bodies for this profile — exposed so Settings can size and clear it
  /// and so logging out can delete it.
  final HttpCache cache;

  final OfflineStatus status;
}

/// Attaches the `x-api-key` auth header and the culture-invariant header on
/// every request.
///
/// It deliberately does NOT react to 401: LubeLogger returns 401 both for a bad
/// key AND for a valid key lacking the required scope, so an automatic logout on
/// 401 would be wrong. Callers inspect the failure and decide (see
/// [AppErrorCode.unauthorized]).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.credentials});

  final CredentialsStore credentials;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers[kCultureInvariantHeader] = 'true';
    final key = await credentials.readApiKey();
    if (key != null) {
      options.headers['x-api-key'] = key;
    }
    handler.next(options);
  }
}
