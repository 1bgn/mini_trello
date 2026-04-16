import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/indicator_model.dart';

abstract class KanbanRemoteDataSource {
  Future<List<IndicatorModel>> getIndicators();

  Future<void> saveIndicatorField({
    required int indicatorToMoId,
    required String fieldName,
    required String fieldValue,
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
        'requested_mo_id': AppConstants.requestedMoId,
        'behaviour_key': AppConstants.behaviourKey,
        'with_result': 'false',
        'response_fields': AppConstants.responseFields,
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
    required String fieldName,
    required String fieldValue,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('period_start', AppConstants.periodStart),
        MapEntry('period_end', AppConstants.periodEnd),
        MapEntry('period_key', AppConstants.periodKey),
        MapEntry('indicator_to_mo_id', indicatorToMoId.toString()),
        MapEntry('field_name', fieldName),
        MapEntry('field_value', fieldValue),
        MapEntry('auth_user_id', AppConstants.authUserId),
      ]);

      final response = await apiClient.post(
        AppConstants.saveIndicatorFieldPath,
        data: formData,
      );

      // Check for application-level error in the response body
      final data = response.data;
      if (data is Map) {
        final success = data['success'] ?? data['status'];
        if (success != null &&
            (success == false || success == 0 || success == 'error')) {
          final msg = data['message'] ?? data['error'] ?? 'Неизвестная ошибка';
          throw ServerException('Ошибка сохранения: $msg');
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
    throw ServerException(
      'Ошибка сервера (${e.response?.statusCode ?? 'нет ответа'})',
    );
  }
}
