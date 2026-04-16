import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Pretty-prints Dio requests and responses.
/// Active only in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '→ ${options.method} ${options.uri}\n'
        '  Headers: ${_mask(options.headers)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '← ${response.statusCode} ${response.requestOptions.uri}\n'
        '  Body: ${_truncate(response.data.toString())}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✗ ${err.type.name} ${err.requestOptions.uri}\n'
        '  ${err.message}',
      );
    }
    handler.next(err);
  }

  Map<String, dynamic> _mask(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = 'Bearer ••••••••';
    }
    return copy;
  }

  String _truncate(String s, {int max = 400}) =>
      s.length > max ? '${s.substring(0, max)}…' : s;
}
