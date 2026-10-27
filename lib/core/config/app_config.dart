class AppConfig {
  const AppConfig._();

  static const String _rawBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    final trimmed = _rawBaseUrl.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static bool get isConfigured => apiBaseUrl.isNotEmpty;
}
