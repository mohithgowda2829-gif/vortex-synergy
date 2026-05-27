import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _overrideOrigin = String.fromEnvironment('API_ORIGIN');

  static String get origin {
    String normalize(String value) {
      return value.replaceAll(RegExp(r'/+$'), '');
    }

    if (_overrideOrigin.isNotEmpty) {
      return normalize(_overrideOrigin);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  static String get baseUrl => '$origin/api';

  static String resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$origin$path';
  }
}
