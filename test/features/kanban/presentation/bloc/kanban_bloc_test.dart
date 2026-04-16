import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_trello/core/errors/failures.dart';
import 'package:mini_trello/features/kanban/domain/entities/indicator.dart';
import 'package:mini_trello/features/kanban/domain/usecases/get_indicators_usecase.dart';
import 'package:mini_trello/features/kanban/domain/usecases/save_indicator_field_usecase.dart';
import 'package:mini_trello/features/kanban/presentation/bloc/kanban_bloc.dart';
import 'package:mini_trello/features/kanban/presentation/bloc/kanban_event.dart';
import 'package:mini_trello/features/kanban/presentation/bloc/kanban_state.dart';

class MockGetIndicatorsUseCase extends Mock implements GetIndicatorsUseCase {}

class MockSaveIndicatorFieldUseCase extends Mock
    implements SaveIndicatorFieldUseCase {}

const _folder1 = Indicator(
  indicatorToMoId: 100,
  parentId: null,
  name: 'Новые задачи',
  order: 1,
);

const _folder2 = Indicator(
  indicatorToMoId: 200,
  parentId: null,
  name: 'В работе',
  order: 2,
);

const _task1 = Indicator(
  indicatorToMoId: 1001,
  parentId: 100,
  name: 'Задача А',
  order: 1,
);

const _task2 = Indicator(
  indicatorToMoId: 1002,
  parentId: 100,
  name: 'Задача Б',
  order: 2,
);

const _task3 = Indicator(
  indicatorToMoId: 2001,
  parentId: 200,
  name: 'Задача В',
  order: 1,
);

final _allIndicators = [_folder1, _folder2, _task1, _task2, _task3];

void main() {
  late MockGetIndicatorsUseCase mockGet;
  late MockSaveIndicatorFieldUseCase mockSave;
  late KanbanBloc bloc;

  setUp(() {
    mockGet = MockGetIndicatorsUseCase();
    mockSave = MockSaveIndicatorFieldUseCase();
    bloc = KanbanBloc(
      getIndicatorsUseCase: mockGet,
      saveIndicatorFieldUseCase: mockSave,
    );
  });

  tearDown(() => bloc.close());

  group('LoadIndicatorsEvent', () {
    test('emits [Loading, Loaded] on success', () {
      when(() => mockGet()).thenAnswer((_) async => Right(_allIndicators));

      expectLater(
        bloc.stream,
        emitsInOrder([
          const KanbanLoading(),
          KanbanLoaded(indicators: _allIndicators),
        ]),
      );

      bloc.add(const KanbanEvent.load());
    });

    test('emits [Loading, KanbanError] on ServerFailure', () {
      when(() => mockGet()).thenAnswer(
        (_) async => const Left(ServerFailure('Ошибка сервера')),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          const KanbanLoading(),
          const KanbanError('Ошибка сервера'),
        ]),
      );

      bloc.add(const KanbanEvent.load());
    });

    test('emits [Loading, KanbanError] on NetworkFailure', () {
      when(() => mockGet()).thenAnswer(
        (_) async => const Left(NetworkFailure('Нет сети')),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          const KanbanLoading(),
          const KanbanError('Нет сети'),
        ]),
      );

      bloc.add(const KanbanEvent.load());
    });
  });

  group('KanbanLoaded — columns/columnNames', () {
    test('groups tasks by parent_id and excludes folder items', () {
      final loaded = KanbanLoaded(indicators: _allIndicators);
      final columns = loaded.columns;

      expect(columns.keys, containsAll([100, 200]));
      expect(columns[100]!.map((i) => i.indicatorToMoId), [1001, 1002]);
      expect(columns[200]!.map((i) => i.indicatorToMoId), [2001]);


      for (final tasks in columns.values) {
        expect(tasks.any((t) => t.indicatorToMoId == 100), isFalse);
        expect(tasks.any((t) => t.indicatorToMoId == 200), isFalse);
      }
    });

    test('columnNames resolves folder names from matching indicators', () {
      final loaded = KanbanLoaded(indicators: _allIndicators);
      final names = loaded.columnNames;

      expect(names[100], 'Новые задачи');
      expect(names[200], 'В работе');
    });

    test('columnNames falls back to "Папка N" for unknown parent', () {

      final loaded = KanbanLoaded(
        indicators: [
          const Indicator(
            indicatorToMoId: 9999,
            parentId: 8888,
            name: 'Orphan task',
            order: 1,
          ),
        ],
      );
      expect(loaded.columnNames[8888], startsWith('Папка'));
    });

    test('cards within a column are sorted by order', () {
      final shuffled = KanbanLoaded(
        indicators: [
          _folder1,
          _task2,
          _task1,
        ],
      );
      final col = shuffled.columns[100]!;
      expect(col[0].indicatorToMoId, 1001);
      expect(col[1].indicatorToMoId, 1002);
    });
  });

  group('MoveCardEvent', () {
    setUp(() {

      when(
        () => mockSave(
          indicatorToMoId: any(named: 'indicatorToMoId'),
          fields: any(named: 'fields'),
        ),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
    });

    test('moves card to a different column optimistically then confirms', () async {
      when(() => mockGet()).thenAnswer((_) async => Right(_allIndicators));
      bloc.add(const KanbanEvent.load());
      await Future<void>.delayed(Duration.zero);

      bloc.add(
        const KanbanEvent.moveCard(
          indicator: _task1,
          newParentId: 200,
          insertPosition: 0,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final current = bloc.state as KanbanLoaded;
      final col200 = current.columns[200]!;

      expect(col200.any((t) => t.indicatorToMoId == 1001), isTrue);
      final movedTask = col200.firstWhere((t) => t.indicatorToMoId == 1001);
      expect(movedTask.parentId, 200);


      verify(
        () => mockSave(
          indicatorToMoId: 1001,
          fields: any(named: 'fields'),
        ),
      ).called(1);
    });

    test('emits KanbanSaveError then reverts on parent_id save failure', () async {

      when(
        () => mockSave(
          indicatorToMoId: any(named: 'indicatorToMoId'),
          fields: any(named: 'fields'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Нет связи')),
      );

      when(() => mockGet()).thenAnswer((_) async => Right(_allIndicators));
      bloc.add(const KanbanEvent.load());
      await Future<void>.delayed(Duration.zero);

      final stateBefore = bloc.state as KanbanLoaded;

      final emitted = <KanbanState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(
        const KanbanEvent.moveCard(
          indicator: _task1,
          newParentId: 200,
          insertPosition: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();


      expect(emitted.any((s) => s is KanbanSaveError), isTrue);
      final saveError =
          emitted.firstWhere((s) => s is KanbanSaveError) as KanbanSaveError;
      expect(saveError.message, 'Нет связи');


      expect(emitted.last, stateBefore);
    });
  });

  group('RefreshIndicatorsEvent', () {
    test('refreshes data while keeping isSaving=true during load', () async {

      when(() => mockGet()).thenAnswer((_) async => Right(_allIndicators));
      bloc.add(const KanbanEvent.load());
      await Future<void>.delayed(Duration.zero);

      when(() => mockGet()).thenAnswer((_) async => Right(_allIndicators));

      final states = <KanbanState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(const KanbanEvent.refresh());
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();


      expect(states.first, isA<KanbanLoaded>());
      expect((states.first as KanbanLoaded).isSaving, isTrue);
    });
  });
}
