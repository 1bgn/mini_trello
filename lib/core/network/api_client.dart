import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class ApiClient {
  final Dio dio;

  /// Production constructor — creates a pre-configured Dio instance.
  ApiClient() : dio = _buildDio() {
    _attachInterceptors(dio);
  }

  /// Testing constructor — accepts an externally-configured Dio so that
  /// [http_mock_adapter] (or any other HttpClientAdapter) can be injected.
  ApiClient.withDio(this.dio) {
    _attachInterceptors(dio);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) =>
      dio.post<dynamic>(path, data: data);

  // ── Private helpers ────────────────────────────────────────────────────────

  static Dio _buildDio() => Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  static void _attachInterceptors(Dio d) {
    d.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(dio: d, maxRetries: 3),
      LoggingInterceptor(),
    ]);
  }
}
