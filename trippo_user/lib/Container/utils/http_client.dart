import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Shared HTTP client with proper configuration for web and mobile platforms
class HttpClient {
  static Dio? _dio;

  /// Get or create a configured Dio instance
  static Dio get instance {
    if (_dio != null) {
      return _dio!;
    }

    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for web platform to handle CORS
    if (kIsWeb) {
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // For Google Maps REST APIs on web, remove headers that cause CORS preflight issues
            // Simple GET requests don't need Content-Type header
            if (options.uri.host.contains('maps.googleapis.com') && 
                options.method.toUpperCase() == 'GET') {
              options.headers.remove('Content-Type');
              // Keep only Accept header for GET requests
              options.headers['Accept'] = '*/*';
            }
            handler.next(options);
          },
          onError: (error, handler) {
            // Handle CORS errors specifically
            if (error.type == DioExceptionType.badResponse) {
              final statusCode = error.response?.statusCode;
              if (statusCode == null) {
                error = DioException(
                  requestOptions: error.requestOptions,
                  type: DioExceptionType.unknown,
                  error: 'Network error. Please check your connection.',
                );
              }
            } else if (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout) {
              error = DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                error: 'Request timeout. Please try again.',
              );
            }
            handler.next(error);
          },
        ),
      );
    }

    return _dio!;
  }

  /// Dispose the Dio instance (call when app is closing)
  static void dispose() {
    _dio?.close();
    _dio = null;
  }
}

