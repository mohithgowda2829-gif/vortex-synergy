import '../models/dashboard_summary.dart';
import '../models/pending_verification.dart';
import '../models/resource_item.dart';
import 'api_client.dart';

class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<List<PendingVerification>> pendingVerifications(String token) async {
    final List<dynamic> json =
        await _client.get('/admin/verifications/pending', token: token) as List<dynamic>;
    return json
        .map((dynamic item) => PendingVerification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PendingVerification> decideVerification(
    String token, {
    required String verificationId,
    required bool approved,
    required String note,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/admin/verifications/$verificationId/decision',
      token: token,
      body: <String, dynamic>{'approved': approved, 'note': note},
    ) as Map<String, dynamic>;
    return PendingVerification.fromJson(json);
  }

  Future<List<ResourceItem>> resources(String token) async {
    final List<dynamic> json = await _client.get('/admin/resources', token: token) as List<dynamic>;
    return json.map((dynamic item) => ResourceItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> removeResource(String token, String resourceId) async {
    await _client.post('/admin/resources/$resourceId/remove', token: token);
  }

  Future<DashboardSummary> analytics(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/admin/analytics', token: token) as Map<String, dynamic>;
    return DashboardSummary.fromJson(json);
  }
}
