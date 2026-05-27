import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class UploadApi {
  Future<String> uploadResourcePhoto(String token, PlatformFile file) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/uploads/resource-photo'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    } else {
      throw Exception('Selected image could not be read');
    }

    final http.Response response;
    final dynamic json;
    try {
      final http.StreamedResponse streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamedResponse);
      json = response.body.isEmpty ? null : jsonDecode(response.body);
    } on SocketException {
      throw Exception('Unable to upload right now. Check your connection and try again.');
    } on http.ClientException {
      throw Exception('Unable to upload right now. Check your connection and try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json['url']?.toString() ?? '';
    }

    final String message = json is Map<String, dynamic>
        ? json['message']?.toString() ?? 'Upload failed'
        : 'Upload failed';
    throw Exception(message);
  }
}
