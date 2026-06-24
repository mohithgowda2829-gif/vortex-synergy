import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _overrideOrigin = String.fromEnvironment('API_ORIGIN');
  static const String _defaultDeployedOrigin = 'https://vortex-synergy-api.onrender.com';
  static const String _defaultLocalOrigin = 'http://127.0.0.1:8080';

  static String get origin {
    String normalize(String value) {
      return value.replaceAll(RegExp(r'/+$'), '');
    }

    if (_overrideOrigin.isNotEmpty) {
      return normalize(_overrideOrigin);
    }
    if (!kReleaseMode) {
      return _defaultLocalOrigin;
    }
    return _defaultDeployedOrigin;
  }

  static String get baseUrl => '$origin/api';

  static String resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$origin$path';
  }
}
