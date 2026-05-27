import '../models/app_user.dart';
import 'api_client.dart';

class ForgotPasswordResult {
  const ForgotPasswordResult({
    required this.message,
    required this.resetToken,
    required this.expiresAt,
  });

  final String message;
  final String? resetToken;
  final DateTime? expiresAt;

  factory ForgotPasswordResult.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResult(
      message: json['message']?.toString() ?? 'Password reset instructions generated.',
      resetToken: json['resetToken']?.toString(),
      expiresAt: json['expiresAt'] == null ? null : DateTime.tryParse(json['expiresAt'].toString()),
    );
  }
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<(String, AppUser)> login(String email, String password) async {
    await _client.waitForServerReady();
    final Map<String, dynamic> json = await _client.post(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    ) as Map<String, dynamic>;

    return (
      json['token']?.toString() ?? '',
      AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Future<(String, AppUser)> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/auth/register',
      body: <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    ) as Map<String, dynamic>;

    return (
      json['token']?.toString() ?? '',
      AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Future<ForgotPasswordResult> forgotPassword(String email) async {
    final Map<String, dynamic> json = await _client.post(
      '/auth/forgot-password',
      body: <String, dynamic>{'email': email},
    ) as Map<String, dynamic>;
    return ForgotPasswordResult.fromJson(json);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post(
      '/auth/reset-password',
      body: <String, dynamic>{
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }
}
