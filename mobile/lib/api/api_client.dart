import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String?>? queryParameters,
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
      final response = await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 20));
      return _handleResponse(response);
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
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    try {
      final response = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ).timeout(const Duration(seconds: 20));
      return _handleResponse(response);
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
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    try {
      final response = await http.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ).timeout(const Duration(seconds: 20));
      return _handleResponse(response);
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
  }) async {
    final Uri uri = Uri.parse('${AppConfig.baseUrl}$path');
    try {
      final response = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ).timeout(const Duration(seconds: 20));
      return _handleResponse(response);
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
      final response = await http.get(uri, headers: _headers(token)).timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      final dynamic decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final String message = _extractMessage(decoded);
      throw Exception(message);
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
}
