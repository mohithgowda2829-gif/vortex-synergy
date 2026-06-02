import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 60);
  static const Duration _warmupRequestTimeout = Duration(seconds: 12);
  static const Duration _warmupWait = Duration(seconds: 90);
  static const Duration _warmupPollInterval = Duration(seconds: 3);
  static const Duration _serverReadyCache = Duration(minutes: 2);
  static const Duration _keepAliveInterval = Duration(minutes: 8);

  DateTime? _serverReadyUntil;
  Future<void>? _warmupFuture;
  Timer? _keepAliveTimer;

  void startKeepAlive() {
    if (_keepAliveTimer?.isActive ?? false) {
      return;
    }
    unawaited(pingServer());
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) {
      unawaited(pingServer());
    });
  }

  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<void> pingServer() async {
    try {
      await waitForServerReady(maxWait: const Duration(seconds: 45));
    } catch (_) {
      // Best-effort keepalive only.
    }
  }

  Future<void> waitForServerReady({
    Duration maxWait = _warmupWait,
  }) async {
    if (_serverReadyUntil != null && DateTime.now().isBefore(_serverReadyUntil!)) {
      return;
    }
    if (_warmupFuture != null) {
      return _warmupFuture!;
    }

    final Future<void> warmup = _waitForServerReadyInternal(maxWait: maxWait);
    _warmupFuture = warmup;
    try {
      await warmup;
    } finally {
      if (identical(_warmupFuture, warmup)) {
        _warmupFuture = null;
      }
    }
  }

  Future<void> _waitForServerReadyInternal({
    required Duration maxWait,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.origin}/actuator/health');
    final DateTime deadline = DateTime.now().add(maxWait);

    while (true) {
      try {
        final http.Response response = await http
            .get(uri, headers: const <String, String>{'Accept': 'application/json'})
            .timeout(_warmupRequestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _markServerReady();
          return;
        }
      } on TimeoutException {
        // Keep polling until the backend wakes up or the overall deadline is hit.
      } on SocketException {
        // Keep polling until the backend wakes up or the overall deadline is hit.
      } on http.ClientException {
        // Keep polling until the backend wakes up or the overall deadline is hit.
      }

      if (DateTime.now().isAfter(deadline)) {
        throw Exception(_timeoutMessage);
      }
      await Future<void>.delayed(_warmupPollInterval);
    }
  }

  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String?>? queryParameters,
    Duration? timeout,
  }) async {
    final Map<String, String>? sanitizedQueryParameters = queryParameters == null
        ? null
        : Map<String, String>.fromEntries(
            queryParameters.entries
                .where((MapEntry<String, String?> entry) => entry.value != null && entry.value!.isNotEmpty)
                .map((MapEntry<String, String?> entry) => MapEntry(entry.key, entry.value!)),
          );

    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path').replace(
      queryParameters: sanitizedQueryParameters == null || sanitizedQueryParameters.isEmpty
          ? null
          : sanitizedQueryParameters,
    );

    try {
      final response = await http.get(uri, headers: _headers(token)).timeout(timeout ?? _requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage);
    } on SocketException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on FormatException {
      throw Exception('The server returned an unreadable response.');
    }
  }

  Future<dynamic> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    try {
      final response = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ).timeout(timeout ?? _requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage);
    } on SocketException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on FormatException {
      throw Exception('The server returned an unreadable response.');
    }
  }

  Future<dynamic> patch(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    try {
      final response = await http.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ).timeout(timeout ?? _requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage);
    } on SocketException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on FormatException {
      throw Exception('The server returned an unreadable response.');
    }
  }

  Future<dynamic> put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    try {
      final response = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ).timeout(timeout ?? _requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage);
    } on SocketException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on FormatException {
      throw Exception('The server returned an unreadable response.');
    }
  }

  Future<String> getText(
    String path, {
    String? token,
    Map<String, String?>? queryParameters,
    Duration? timeout,
  }) async {
    final Map<String, String>? sanitizedQueryParameters = queryParameters == null
        ? null
        : Map<String, String>.fromEntries(
            queryParameters.entries
                .where((MapEntry<String, String?> entry) => entry.value != null && entry.value!.isNotEmpty)
                .map((MapEntry<String, String?> entry) => MapEntry(entry.key, entry.value!)),
          );

    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path').replace(
      queryParameters: sanitizedQueryParameters == null || sanitizedQueryParameters.isEmpty
          ? null
          : sanitizedQueryParameters,
    );
    try {
      final response = await http.get(uri, headers: _headers(token)).timeout(timeout ?? _requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _markServerReady();
        return response.body;
      }
      final dynamic decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final String message = _extractMessage(decoded);
      throw Exception(message);
    } on TimeoutException {
      throw Exception(_timeoutMessage);
    } on SocketException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on http.ClientException {
      throw Exception('Unable to reach the server. Check your connection and try again.');
    } on FormatException {
      throw Exception('The server returned an unreadable response.');
    }
  }

  Map<String, String> _headers(String? token) {
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    final dynamic decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _markServerReady();
      return decoded;
    }

    final String message = _extractMessage(decoded);
    throw Exception(message);
  }

  String _extractMessage(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return 'Request failed';
    }

    final dynamic fieldErrors = decoded['fieldErrors'];
    if (fieldErrors is Map && fieldErrors.isNotEmpty) {
      final List<String> messages = <String>[];
      for (final MapEntry<dynamic, dynamic> entry in fieldErrors.entries) {
        final String field = _humanizeField(entry.key?.toString() ?? 'field');
        final String error = entry.value?.toString() ?? 'Invalid value';
        messages.add('$field: $error');
      }
      return messages.join('\n');
    }

    return decoded['message']?.toString() ?? 'Request failed';
  }

  String _humanizeField(String field) {
    final String withSpaces = field.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (Match match) => '${match.group(1)} ${match.group(2)}',
    );
    if (withSpaces.isEmpty) {
      return 'Field';
    }
    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }

  String get _timeoutMessage =>
      'The server is taking longer than usual to respond. If the backend is waking up, wait a few seconds and try again.';

  void _markServerReady() {
    _serverReadyUntil = DateTime.now().add(_serverReadyCache);
  }
}
