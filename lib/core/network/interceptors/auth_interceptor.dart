import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';

/// Injects the Authorization: Bearer header into every outgoing request.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer ${AppConstants.bearerToken}';
    handler.next(options);
  }
}
