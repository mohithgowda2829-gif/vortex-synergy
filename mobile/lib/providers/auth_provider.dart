import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/notification_api.dart';
import '../api/user_api.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    initialize();
  }

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final ApiClient apiClient = ApiClient();

  late final AuthApi _authApi = AuthApi(apiClient);
  late final UserApi _userApi = UserApi(apiClient);
  late final NotificationApi _notificationApi = NotificationApi(apiClient);

  AppUser? _user;
  String? _token;
  bool _initialized = false;
  bool _busy = false;
  int _unreadNotificationCount = 0;

  AppUser? get user => _user;
  String? get token => _token;
  bool get initialized => _initialized;
  bool get busy => _busy;
  bool get isAuthenticated => _token != null && _user != null;
  int get unreadNotificationCount => _unreadNotificationCount;

  Future<void> initialize() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _token = preferences.getString(_tokenKey);
    final String? userJson = preferences.getString(_userKey);
    if (userJson != null) {
      _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }

    if (_token != null) {
      try {
        await apiClient.waitForServerReady();
        _user = await _userApi.me(_token!);
        await refreshNotificationSummary(notify: false);
        await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
      } catch (_) {
        await logout();
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _busy = true;
    notifyListeners();
    try {
      final (String token, AppUser user) = await _authApi.login(email, password);
      await _persistSession(token, user);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final (String token, AppUser user) = await _authApi.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      await _persistSession(token, user);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    _user = await _userApi.me(_token!);
    await refreshNotificationSummary(notify: false);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> verifyPlaceholder(String channel, String code) async {
    if (_token == null) return;
    _busy = true;
    notifyListeners();
    try {
      _user = await _userApi.verifyPlaceholder(_token!, channel: channel, code: code);
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
      await refreshNotificationSummary(notify: false);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotificationSummary({bool notify = true}) async {
    if (_token == null) {
      _unreadNotificationCount = 0;
      if (notify) {
        notifyListeners();
      }
      return;
    }
    final summary = await _notificationApi.summary(_token!);
    _unreadNotificationCount = summary.unreadCount;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_token == null) return;
    final summary = await _notificationApi.markAllRead(_token!);
    _unreadNotificationCount = summary.unreadCount;
    notifyListeners();
  }

  void setUnreadNotificationCount(int count) {
    _unreadNotificationCount = count;
    notifyListeners();
  }

  Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);
    _token = null;
    _user = null;
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  Future<void> _persistSession(String token, AppUser user) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _token = token;
    _user = user;
    await preferences.setString(_tokenKey, token);
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
    await refreshNotificationSummary(notify: false);
  }
}
