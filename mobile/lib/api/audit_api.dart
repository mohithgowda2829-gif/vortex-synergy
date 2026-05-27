import '../models/timeline_event.dart';
import 'api_client.dart';

class AuditApi {
  AuditApi(this._client);

  final ApiClient _client;

  Future<List<TimelineEvent>> resourceTimeline(String token, String resourceId) async {
    final List<dynamic> json = await _client.get('/audit/resource/$resourceId', token: token) as List<dynamic>;
    return json.map((dynamic item) => TimelineEvent.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<TimelineEvent>> claimTimeline(String token, String claimId) async {
    final List<dynamic> json = await _client.get('/audit/claim/$claimId', token: token) as List<dynamic>;
    return json.map((dynamic item) => TimelineEvent.fromJson(item as Map<String, dynamic>)).toList();
  }
}
