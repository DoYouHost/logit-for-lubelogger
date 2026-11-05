import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_util/app_util.dart';
import 'package:dio/dio.dart';

/// Error codes for the API/auth layer. The core layer is UI-independent:
/// translation to text happens at display time (see `lib/l10n/error_messages.dart`).
enum AppErrorCode {
  serverUnreachable,

  /// 401. LubeLogger OVERLOADS this: it means *either* missing/invalid
  /// credentials *or* a valid key/user with insufficient scope (the server
  /// returns 401 + a `{success:false}` body for both, never 403 for scope).
  /// So a 401 must NOT trigger an automatic logout — the credentials may be
  /// fine and only the permission is lacking. See docs/api-server.md.
  unauthorized,

  /// 403 — reserved. LubeLogger's API rarely uses it (scope denial comes back
  /// as 401), but a reverse proxy in front of the server may return it.
  forbidden,
  badResponse,

  /// 404 on an endpoint a newer LubeLogger added — the route simply isn't there
  /// on this server. Raised only where the app knows the minimum version (see
  /// `ServerCapabilities`); a 404 anywhere else stays a [badResponse], because
  /// there it means a wrong base URL, not an old server.
  unsupportedByServer,
  badCertificate,
  connectionError,
  malformedResponse,
  invalidCredentials,
  apiKeyRejected,
}

/// Base exception for the API layer. Carries an error code (for localization)
/// and optional technical details for logs.
sealed class AppApiException implements Exception {
  const AppApiException(
    this.code, {
    this.statusCode,
    this.detail,
    this.method,
    this.path,
  });

  final AppErrorCode code;

  /// HTTP status code for [AppErrorCode.badResponse] (null for others).
  final int? statusCode;

  /// Raw, user-invisible detail (e.g. `DioException.message`).
  final String? detail;

  /// The call that failed. With several requests in flight, reconstructing it
  /// from the `http` records around the failure is guesswork.
  ///
  /// [path] has been through [loggablePath], the same reduction `HttpProbe`
  /// records with: no host, no query string, and no segment the user named.
  /// Both are null for an exception the app raised itself rather than mapped
  /// from a response.
  final String? method;
  final String? path;

  @override
  String toString() =>
      '$runtimeType($code${statusCode == null ? '' : ', status=$statusCode'}'
      '${detail == null ? '' : ', detail=$detail'})';
}

/// Server responded with an error (4xx/5xx except 401/403) or the response had
/// an unexpected shape.
class ApiException extends AppApiException {
  const ApiException(
    super.code, {
    super.statusCode,
    super.detail,
    super.method,
    super.path,
  });
}

/// Authentication problem: bad credentials, rejected key, or insufficient scope.
class AuthException extends AppApiException {
  const AuthException(super.code, {super.detail, super.method, super.path});
}

/// Server unreachable: timeout, connection refused, or no network.
class NetworkException extends AppApiException {
  const NetworkException(super.code, {super.detail, super.method, super.path});
}

/// Runs [body], mapping any [DioException] to an [AppApiException] via
/// [mapDioException]. Centralizes the `try { ... } on DioException` boilerplate
/// repeated across repositories.
Future<T> guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw mapDioException(e);
  }
}

/// Like [guard], but non-auth failures degrade to `null` instead of rethrowing
/// — for single-entity fetches where one unreachable resource shouldn't break a
/// composite view. Auth errors still bubble up so the UI can react.
///
/// Every swallow leaves a record. This is the one failure the app makes
/// invisible on purpose: the screen renders without the missing piece and says
/// nothing, so "the card shows no odometer" reaches a report as a screenshot of
/// a working app. The HTTP probe sees the failed request but not the decision to
/// carry on without it — and a `TypeError` from a response the parser could not
/// read never reaches the probe at all.
Future<T?> guardOrNull<T>(Future<T?> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    final mapped = mapDioException(e);
    if (mapped is AuthException) throw mapped;
    _logDegraded(mapped.code.name, mapped);
    return null;
  } on Object catch (error) {
    // Nothing mapped, so nothing names the request: a `TypeError` from a
    // response the parser could not read never reached the probe either.
    _logDegraded(error.runtimeType.toString(), null);
    return null;
  }
}

void _logDegraded(String cause, AppApiException? failure) =>
    DiagnosticRecorder.active?.add(
      LogSource.http,
      'degraded',
      lvl: LogLevel.warn,
      fields: {
        'cause': cause,
        'status': failure?.statusCode,
        // Which call the screen carried on without. The probe records the
        // request, but not the decision to render the screen anyway.
        'method': failure?.method,
        'path': failure?.path,
      },
    );

/// Maps a [DioException] to a typed application exception.
AppApiException mapDioException(DioException e) {
  if (e.error is AppApiException) {
    return e.error! as AppApiException;
  }
  final method = e.requestOptions.method;
  // The same reduction `HttpProbe` records with: no host, no query, and no
  // segment the user named.
  final path = loggablePath(e.requestOptions.uri.path);
  return switch (classifyDioException(e)) {
    DioFailure.unreachable => NetworkException(
      AppErrorCode.serverUnreachable,
      detail: e.message,
      method: method,
      path: path,
    ),
    DioFailure.unauthorized => AuthException(
      AppErrorCode.unauthorized,
      method: method,
      path: path,
    ),
    DioFailure.forbidden => AuthException(
      AppErrorCode.forbidden,
      method: method,
      path: path,
    ),
    // No code of its own here: a 429 reads as the status it is.
    DioFailure.tooManyRequests || DioFailure.badResponse => ApiException(
      AppErrorCode.badResponse,
      statusCode: e.response?.statusCode,
      method: method,
      path: path,
    ),
    DioFailure.badCertificate => NetworkException(
      AppErrorCode.badCertificate,
      method: method,
      path: path,
    ),
    DioFailure.cancelled || DioFailure.unknown => NetworkException(
      AppErrorCode.connectionError,
      detail: e.message,
      method: method,
      path: path,
    ),
  };
}
