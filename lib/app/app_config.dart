class AppConfig {
  const AppConfig._();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'PIXFIT_API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    return 'http://localhost:8787';
  }

  static Uri apiUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse(
      '$apiBaseUrl$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }
}
