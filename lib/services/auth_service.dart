import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/auth_session.dart';

class AuthService {
  AuthService(this._apiClient, {Dio? dio}) : _dio = dio ?? _apiClient.dio;

  final ApiClient _apiClient;
  final Dio _dio;

  Future<AuthSession> register({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
        },
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '注册失败，请稍后重试');
    }
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (error) {
      throw _apiClient.mapError(error, fallback: '登录失败，请稍后重试');
    }
  }
}
