import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_trello/core/errors/exceptions.dart';
import 'package:mini_trello/core/network/api_client.dart';
import 'package:mini_trello/features/kanban/data/datasources/kanban_remote_datasource.dart';
import 'package:mini_trello/features/kanban/data/models/indicator_model.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Response<dynamic> _response(dynamic data, {int status = 200}) => Response(
      data: data,
      statusCode: status,
      requestOptions: RequestOptions(path: ''),
    );

DioException _dioError(DioExceptionType type, {int? statusCode}) => DioException(
      type: type,
      requestOptions: RequestOptions(path: ''),
      response: statusCode != null
          ? Response(
              statusCode: statusCode,
              requestOptions: RequestOptions(path: ''),
            )
          : null,
    );

Map<String, dynamic> _item({
  required int id,
  required int? parentId,
  required String name,
  required int order,
}) =>
    {
      'indicator_to_mo_id': id,
      'parent_id': parentId,
      'name': name,
      'order': order,
    };

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockApiClient client;
  late KanbanRemoteDataSourceImpl dataSource;

  setUp(() {
    client = MockApiClient();
    dataSource = KanbanRemoteDataSourceImpl(client);
  });

  // Helper: stub any POST to return [data].
  void stubPost(dynamic data, {int status = 200}) {
    when(() => client.post(any(), data: any(named: 'data')))
        .thenAnswer((_) async => _response(data, status: status));
  }

  void stubPostThrows(DioException err) {
    when(() => client.post(any(), data: any(named: 'data'))).thenThrow(err);
  }

  group('getIndicators', () {
    test('returns parsed list — data wrapper', () async {
      stubPost({
        'data': [
          _item(id: 1, parentId: 100, name: 'Задача 1', order: 1),
          _item(id: 2, parentId: 100, name: 'Задача 2', order: 2),
        ]
      });

      final result = await dataSource.getIndicators();

      expect(result, hasLength(2));
      expect(result, everyElement(isA<IndicatorModel>()));
      expect(result.first.indicatorToMoId, 1);
      expect(result.first.parentId, 100);
      expect(result.first.name, 'Задача 1');
      expect(result.first.order, 1);
    });

    test('returns parsed list — root array (no wrapper)', () async {
      stubPost([_item(id: 5, parentId: 200, name: 'Task', order: 1)]);

      final result = await dataSource.getIndicators();
      expect(result, hasLength(1));
      expect(result.first.indicatorToMoId, 5);
    });

    test('returns empty list when data array is empty', () async {
      stubPost({'data': []});
      expect(await dataSource.getIndicators(), isEmpty);
    });

    test('treats parent_id = 0 as null', () async {
      stubPost({
        'data': [_item(id: 9, parentId: 0, name: 'No parent', order: 1)]
      });
      expect((await dataSource.getIndicators()).first.parentId, isNull);
    });

    test('parses string numeric fields', () async {
      stubPost({
        'data': [
          {
            'indicator_to_mo_id': '42',
            'parent_id': '100',
            'name': 'String fields',
            'order': '3',
          }
        ]
      });

      final result = await dataSource.getIndicators();
      expect(result.first.indicatorToMoId, 42);
      expect(result.first.parentId, 100);
      expect(result.first.order, 3);
    });

    test('uses fallback name when name is blank', () async {
      stubPost({
        'data': [_item(id: 1, parentId: 1, name: '   ', order: 1)]
      });
      expect((await dataSource.getIndicators()).first.name, 'Без названия');
    });

    test('throws ServerException on HTTP 401', () async {
      stubPostThrows(
        _dioError(DioExceptionType.badResponse, statusCode: 401),
      );
      await expectLater(
        dataSource.getIndicators(),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException on HTTP 500', () async {
      stubPostThrows(
        _dioError(DioExceptionType.badResponse, statusCode: 500),
      );
      await expectLater(
        dataSource.getIndicators(),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws NetworkException on connection timeout', () async {
      stubPostThrows(_dioError(DioExceptionType.connectionTimeout));
      await expectLater(
        dataSource.getIndicators(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws NetworkException on connection error', () async {
      stubPostThrows(_dioError(DioExceptionType.connectionError));
      await expectLater(
        dataSource.getIndicators(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('saveIndicatorField', () {
    test('completes on success=true body', () async {
      stubPost({'success': true});
      await expectLater(
        dataSource.saveIndicatorField(
          indicatorToMoId: 1001,
          fieldName: 'parent_id',
          fieldValue: '200',
        ),
        completes,
      );
    });

    test('completes when response body has no success field', () async {
      stubPost({});
      await expectLater(
        dataSource.saveIndicatorField(
          indicatorToMoId: 1001,
          fieldName: 'order',
          fieldValue: '3',
        ),
        completes,
      );
    });

    test('throws ServerException when success=false in body', () async {
      stubPost({'success': false, 'message': 'Запись не найдена'});
      await expectLater(
        dataSource.saveIndicatorField(
          indicatorToMoId: 9999,
          fieldName: 'order',
          fieldValue: '1',
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Запись не найдена'),
          ),
        ),
      );
    });

    test('throws ServerException on HTTP 500', () async {
      stubPostThrows(_dioError(DioExceptionType.badResponse, statusCode: 500));
      await expectLater(
        dataSource.saveIndicatorField(
          indicatorToMoId: 1,
          fieldName: 'parent_id',
          fieldValue: '2',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws NetworkException on receive timeout', () async {
      stubPostThrows(_dioError(DioExceptionType.receiveTimeout));
      await expectLater(
        dataSource.saveIndicatorField(
          indicatorToMoId: 1,
          fieldName: 'order',
          fieldValue: '1',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
