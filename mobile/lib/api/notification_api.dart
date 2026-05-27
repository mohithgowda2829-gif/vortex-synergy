import '../models/app_notification.dart';
import '../models/notification_summary.dart';
import 'api_client.dart';

class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> mine(String token) async {
    final List<dynamic> json = await _client.get('/notifications/my', token: token) as List<dynamic>;
    return json
        .map((dynamic item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationSummary> summary(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/notifications/summary', token: token) as Map<String, dynamic>;
    return NotificationSummary.fromJson(json);
  }

  Future<AppNotification> markRead(String token, String notificationId) async {
    final Map<String, dynamic> json = await _client.patch(
      '/notifications/$notificationId/read',
      token: token,
    ) as Map<String, dynamic>;
    return AppNotification.fromJson(json);
  }

  Future<NotificationSummary> markAllRead(String token) async {
    final Map<String, dynamic> json =
        await _client.patch('/notifications/read-all', token: token) as Map<String, dynamic>;
    return NotificationSummary.fromJson(json);
  }
}
