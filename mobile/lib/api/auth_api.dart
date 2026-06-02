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
  static const Duration _fastLoginAttemptTimeout = Duration(seconds: 25);

  Future<(String, AppUser)> login(String email, String password) async {
    Object? lastError;
    try {
      return await _loginAttempt(email, password, timeout: _fastLoginAttemptTimeout);
    } catch (error) {
      lastError = error;
      if (!_isRetryableLoginError(error)) {
        rethrow;
      }
    }

    for (int attempt = 0; attempt < 2; attempt += 1) {
      try {
        await _client.waitForServerReady(
          maxWait: attempt == 0 ? const Duration(seconds: 20) : const Duration(seconds: 35),
        );
        return await _loginAttempt(email, password, timeout: _fastLoginAttemptTimeout);
      } catch (error) {
        lastError = error;
        if (attempt == 1 || !_isRetryableLoginError(error)) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    throw lastError ?? Exception('Unable to complete login.');
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

  Future<(String, AppUser)> _loginAttempt(
    String email,
    String password, {
    Duration? timeout,
  }) async {
    final Map<String, dynamic> json = await _client.post(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
      timeout: timeout,
    ) as Map<String, dynamic>;

    return (
      json['token']?.toString() ?? '',
      AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  bool _isRetryableLoginError(Object error) {
    final String message = error.toString();
    return message.contains('taking longer than usual') ||
        message.contains('Unable to reach the server') ||
        message.contains('TimeoutException') ||
        message.contains('SocketException') ||
        message.contains('ClientException');
  }
}
