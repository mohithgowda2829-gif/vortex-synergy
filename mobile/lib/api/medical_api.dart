import '../models/resource_item.dart';
import 'api_client.dart';

class MedicalApi {
  MedicalApi(this._client);

  final ApiClient _client;

  Future<List<ResourceItem>> pending(String token) async {
    final List<dynamic> json = await _client.get('/medical/pending', token: token) as List<dynamic>;
    return json.map((dynamic item) => ResourceItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ResourceItem>> history(String token) async {
    final List<dynamic> json = await _client.get('/medical/history', token: token) as List<dynamic>;
    return json.map((dynamic item) => ResourceItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ResourceItem> verify(
    String token, {
    required String resourceId,
    required String note,
    required String verificationNotes,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/medical/verify/$resourceId',
      token: token,
      body: <String, dynamic>{'note': note, 'verificationNotes': verificationNotes},
    ) as Map<String, dynamic>;
    return ResourceItem.fromJson(json);
  }

  Future<ResourceItem> reject(
    String token, {
    required String resourceId,
    required String note,
    required String verificationNotes,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/medical/reject/$resourceId',
      token: token,
      body: <String, dynamic>{'note': note, 'verificationNotes': verificationNotes},
    ) as Map<String, dynamic>;
    return ResourceItem.fromJson(json);
  }
}
