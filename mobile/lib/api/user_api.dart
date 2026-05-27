import '../models/app_user.dart';
import 'api_client.dart';

class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  Future<AppUser> me(String token) async {
    final Map<String, dynamic> json =
        await _client.get('/users/me', token: token) as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  Future<AppUser> verifyPlaceholder(
    String token, {
    required String channel,
    required String code,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/users/me/verify-placeholder',
      token: token,
      body: <String, dynamic>{'channel': channel, 'code': code},
    ) as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }
}
