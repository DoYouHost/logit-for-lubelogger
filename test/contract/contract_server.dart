import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lubelogger_mobile/core/api/api_client.dart';
import 'package:lubelogger_mobile/data/vehicles_repository.dart';

/// A running LubeLogger the contract tests talk to, described by the
/// environment `tool/contract.sh` sets: `LUBELOGGER_URL`, `LUBELOGGER_VERSION`
/// and `LUBELOGGER_LOCALE` (the server's `LUBELOGGER_LOCALE_OVERRIDE`, empty for
/// its default).
class ContractServer {
  ContractServer._(this.url, this.version, this.locale);

  /// Null when no server is configured, which skips the whole suite.
  static ContractServer? fromEnvironment() {
    final url = Platform.environment['LUBELOGGER_URL'];
    if (url == null || url.isEmpty) return null;
    return ContractServer._(
      url,
      Platform.environment['LUBELOGGER_VERSION'] ?? '',
      Platform.environment['LUBELOGGER_LOCALE'] ?? '',
    );
  }

  final String url;
  final String version;
  final String locale;

  /// A plain client: no API key (the server runs without auth) but the same
  /// `culture-invariant` header the app sends.
  Dio get dio => createBareDio()
    ..options.baseUrl = url
    ..options.headers[kCultureInvariantHeader] = 'true';

  VehiclesRepository get repository => VehiclesRepository(dio);
}
