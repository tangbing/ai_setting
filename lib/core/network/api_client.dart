import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session_events.dart';
import '../storage/auth_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._authStorage, this._authSessionEvents)
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.apiV1BaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    dio.interceptors.addAll(
      [
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final token = _authStorage.accessToken;
            if (token != null &&
                token.isNotEmpty &&
                options.headers['Authorization'] == null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            // developer.log(
            //   '${options.method} ${options.uri}',
            //   name: 'ApiClient',
            // );
            handler.next(options);
          },
          onResponse: (response, handler) {
            // developer.log(
            //   '${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
            //   name: 'ApiClient',
            // );
            handler.next(response);
          },
          onError: (error, handler) {
            final mapped = mapError(
              error,
              fallback: '请求失败，请稍后重试',
            );
            if (mapped.statusCode == 401) {
              _authSessionEvents.emit(AuthSessionEvent.unauthorized);
            }
            // developer.log(
            //   '${error.response?.statusCode ?? 0} ${error.requestOptions.method} ${error.requestOptions.uri} ${mapped.message}',
            //   name: 'ApiClient',
            //   error: error,
            // );
            handler.next(error.copyWith(error: mapped));
          },
        ),
        LogInterceptor(requestBody: true, responseBody: true),
      ]
    );
  }

  final AuthStorage _authStorage;
  final AuthSessionEvents _authSessionEvents;
  final Dio dio;

  ApiException mapError(
    DioException error, {
    required String fallback,
  }) {
    final original = error.error;
    if (original is ApiException) {
      return original;
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return ApiException(
          message: detail,
          statusCode: error.response?.statusCode,
        );
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(message: '请求超时，请检查网络后重试');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(message: '网络连接失败，请检查后端服务或网络环境');
    }

    if (error.response?.statusCode == 401) {
      return const ApiException(message: '登录已失效，请重新登录', statusCode: 401);
    }

    return ApiException(
      message: fallback,
      statusCode: error.response?.statusCode,
    );
  }

  String resolveMessage(
    Object error, {
    required String fallback,
  }) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is DioException) {
      return mapError(error, fallback: fallback).message;
    }
    return fallback;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(authStorageProvider),
    ref.watch(authSessionEventsProvider),
  );
});
