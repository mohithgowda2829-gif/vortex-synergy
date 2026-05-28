import 'dart:async';
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
    apiClient.startKeepAlive();
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
  Future<void>? _notificationRefreshTask;

  AppUser? get user => _user;
  String? get token => _token;
  bool get initialized => _initialized;
  bool get busy => _busy;
  bool get isAuthenticated => _token != null && _user != null;
  int get unreadNotificationCount => _unreadNotificationCount;

  @override
  void dispose() {
    apiClient.stopKeepAlive();
    super.dispose();
  }

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
        await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
        _refreshNotificationSummaryInBackground(notify: true);
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
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(_user!.toJson()));
    _refreshNotificationSummaryInBackground(notify: true);
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
      _refreshNotificationSummaryInBackground(notify: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> prewarmServer() async {
    try {
      await apiClient.waitForServerReady(maxWait: const Duration(seconds: 45));
    } catch (_) {
      // Best-effort warmup for sleeping demo backends.
    }
  }

  Future<void> refreshNotificationSummary({bool notify = true}) async {
    if (_token == null) {
      final bool changed = _unreadNotificationCount != 0;
      _unreadNotificationCount = 0;
      if (notify && changed) {
        notifyListeners();
      }
      return;
    }
    final summary = await _notificationApi.summary(_token!);
    final bool changed = _unreadNotificationCount != summary.unreadCount;
    _unreadNotificationCount = summary.unreadCount;
    if (notify && changed) {
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_token == null) return;
    final summary = await _notificationApi.markAllRead(_token!);
    final bool changed = _unreadNotificationCount != summary.unreadCount;
    _unreadNotificationCount = summary.unreadCount;
    if (changed) {
      notifyListeners();
    }
  }

  void setUnreadNotificationCount(int count) {
    if (_unreadNotificationCount == count) {
      return;
    }
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
    _unreadNotificationCount = 0;
    await preferences.setString(_tokenKey, token);
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
    _refreshNotificationSummaryInBackground(notify: true);
  }

  void _refreshNotificationSummaryInBackground({bool notify = true}) {
    unawaited(_ensureNotificationSummary(notify: notify));
  }

  Future<void> _ensureNotificationSummary({bool notify = true}) async {
    if (_token == null) {
      _unreadNotificationCount = 0;
      if (notify) {
        notifyListeners();
      }
      return;
    }
    if (_notificationRefreshTask != null) {
      return _notificationRefreshTask!;
    }

    final Future<void> task = () async {
      try {
        await refreshNotificationSummary(notify: notify);
      } catch (_) {
        // Notification badges should never block the main auth flow.
      } finally {
        _notificationRefreshTask = null;
      }
    }();
    _notificationRefreshTask = task;
    await task;
  }
}
