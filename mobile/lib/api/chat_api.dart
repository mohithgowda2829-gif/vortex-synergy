import '../models/chat_message.dart';
import 'api_client.dart';

class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  Future<List<ChatMessage>> conversation(String token, String claimId) async {
    final List<dynamic> json = await _client.get('/chat/$claimId', token: token) as List<dynamic>;
    return json.map((dynamic item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(
    String token, {
    required String claimId,
    required String message,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/chat',
      token: token,
      body: <String, dynamic>{
        'claimId': claimId,
        'message': message,
      },
    ) as Map<String, dynamic>;
    return ChatMessage.fromJson(json);
  }
}
