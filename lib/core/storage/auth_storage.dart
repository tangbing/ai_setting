import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_session.dart';

class AuthStorage {
  AuthStorage();

  static const _sessionKey = 'auth.session';
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<AuthSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      _accessToken = null;
      return null;
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    final session = AuthSession.fromJson(json);
    _accessToken = session.accessToken;
    return session;
  }

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    _accessToken = session.accessToken;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _accessToken = null;
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});
