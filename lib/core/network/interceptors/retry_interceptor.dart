import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 3});

  static const _kRetryKey = '_retry_count';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isTransient = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (!isTransient) {
      return handler.next(err);
    }

    final retries = (err.requestOptions.extra[_kRetryKey] as int?) ?? 0;
    if (retries >= maxRetries) {
      return handler.next(err);
    }

    final delay = Duration(milliseconds: 500 * (1 << retries));
    await Future<void>.delayed(delay);

    final options = err.requestOptions
      ..extra[_kRetryKey] = retries + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }
}
