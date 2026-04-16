import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/indicator_model.dart';

abstract class KanbanRemoteDataSource {
  Future<List<IndicatorModel>> getIndicators();

  /// Saves one or more fields in a single request.
  /// [fields] maps field_name → field_value; each entry becomes a
  /// duplicate field_name / field_value pair in the multipart body.
  Future<void> saveIndicatorField({
    required int indicatorToMoId,
    required Map<String, String> fields,
  });
}

class KanbanRemoteDataSourceImpl implements KanbanRemoteDataSource {
  final ApiClient apiClient;

  const KanbanRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<IndicatorModel>> getIndicators() async {
    try {
      final formData = FormData.fromMap({
        'period_start': AppConstants.periodStart,
        'period_end': AppConstants.periodEnd,
        'period_key': AppConstants.periodKey,
        'auth_user_id': AppConstants.authUserId,
      });

      final response = await apiClient.post(
        AppConstants.getIndicatorsPath,
        data: formData,
      );

      final items = _extractList(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(IndicatorModel.fromJson)
          .toList();
    } on DioException catch (e) {
      _handleDioError(e); // Never returns — throws
    }
  }

  @override
  Future<void> saveIndicatorField({
    required int indicatorToMoId,
    required Map<String, String> fields,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('period_start', AppConstants.periodStart),
        MapEntry('period_end', AppConstants.periodEnd),
        MapEntry('period_key', AppConstants.periodKey),
        MapEntry('indicator_to_mo_id', indicatorToMoId.toString()),
        // Each entry becomes a duplicate field_name / field_value pair,
        // matching the API's multipart format.
        for (final entry in fields.entries) ...[
          MapEntry('field_name', entry.key),
          MapEntry('field_value', entry.value),
        ],
        MapEntry('auth_user_id', AppConstants.authUserId),
      ]);

      final response = await apiClient.post(
        AppConstants.saveIndicatorFieldPath,
        data: formData,
      );

      // Check for application-level error in the response body.
      // API returns STATUS: "OK"|"OTHER_ERROR" and MESSAGES.error list.
      // Note: STATUS can be "OK" while MESSAGES.error is non-null (e.g. closed period).
      final data = response.data;
      if (data is Map) {
        final messages = data['MESSAGES'];
        if (messages is Map) {
          final errors = messages['error'];
          String? msg;
          if (errors is List && errors.isNotEmpty) {
            msg = errors.first.toString();
          } else if (errors is String && errors.isNotEmpty) {
            msg = errors;
          }
          if (msg != null) throw ServerException(msg);
        }
        final status = data['STATUS'] as String?;
        if (status != null && status != 'OK') {
          throw const ServerException('Ошибка сохранения');
        }
      }
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      // Real API wraps rows in DATA.rows (uppercase key)
      for (final topKey in ['DATA', 'data']) {
        final wrapper = data[topKey];
        if (wrapper is Map && wrapper['rows'] is List) {
          return wrapper['rows'] as List;
        }
      }
      for (final key in ['data', 'items', 'result', 'rows', 'list']) {
        if (data[key] is List) return data[key] as List;
        if (data[key] is Map && data[key]['rows'] is List) {
          return data[key]['rows'] as List;
        }
      }
    }
    return [];
  }

  Never _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const NetworkException('Нет подключения к серверу. Проверьте интернет.');
    }
    if (e.response?.statusCode == 401) {
      throw const ServerException('Ошибка авторизации. Проверьте токен доступа.');
    }
    if (e.response?.statusCode == 403) {
      throw const ServerException('Нет прав на изменение этой записи.');
    }
    throw ServerException(
      'Ошибка сервера (${e.response?.statusCode ?? 'нет ответа'})',
    );
  }
}
