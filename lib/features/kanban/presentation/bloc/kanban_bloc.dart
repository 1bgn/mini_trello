import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/indicator.dart';
import '../../domain/usecases/get_indicators_usecase.dart';
import '../../domain/usecases/save_indicator_field_usecase.dart';
import 'kanban_event.dart';
import 'kanban_state.dart';

class KanbanBloc extends Bloc<KanbanEvent, KanbanState> {
  final GetIndicatorsUseCase getIndicatorsUseCase;
  final SaveIndicatorFieldUseCase saveIndicatorFieldUseCase;

  KanbanBloc({
    required this.getIndicatorsUseCase,
    required this.saveIndicatorFieldUseCase,
  }) : super(const KanbanState.initial()) {
    on<LoadIndicatorsEvent>(_onLoad);
    on<RefreshIndicatorsEvent>(_onRefresh);
    on<MoveCardEvent>(_onMoveCard);
  }

  Future<void> _onLoad(
    LoadIndicatorsEvent event,
    Emitter<KanbanState> emit,
  ) async {
    emit(const KanbanState.loading());
    final result = await getIndicatorsUseCase();
    result.fold(
      (failure) => emit(KanbanState.error(failure.message)),
      (indicators) => emit(KanbanState.loaded(indicators: indicators)),
    );
  }

  Future<void> _onRefresh(
    RefreshIndicatorsEvent event,
    Emitter<KanbanState> emit,
  ) async {
    final current = state;
    if (current is KanbanLoaded) {
      emit(current.copyWith(isSaving: true));
    } else {
      emit(const KanbanState.loading());
    }

    final result = await getIndicatorsUseCase();
    result.fold(
      (failure) => emit(KanbanState.error(failure.message)),
      (indicators) => emit(KanbanState.loaded(indicators: indicators)),
    );
  }

  Future<void> _onMoveCard(
    MoveCardEvent event,
    Emitter<KanbanState> emit,
  ) async {
    final current = state;
    if (current is! KanbanLoaded) return;

    // --- Guard: non-editable card — show optimistic move then revert ---
    if (!event.indicator.allowEdit) {
      final optimistic = _recalculateOrders(
        current.indicators,
        event.indicator,
        event.newParentId,
        event.insertPosition,
      );
      emit(current.copyWith(indicators: optimistic));
      await Future<void>.delayed(const Duration(milliseconds: 350));
      emit(KanbanState.saveError(
        message: 'Эта запись защищена от редактирования',
        previousState: current,
        isPermissionError: true,
      ));
      emit(current);
      return;
    }

    // --- Optimistic update ---
    final updatedIndicators = _recalculateOrders(
      current.indicators,
      event.indicator,
      event.newParentId,
      event.insertPosition,
    );

    emit(current.copyWith(indicators: updatedIndicators, isSaving: true));

    // Find the moved card's new order value.
    final moved = updatedIndicators.firstWhere(
      (i) => i.indicatorToMoId == event.indicator.indicatorToMoId,
    );

    // --- Persist parent_id + order in one request ---
    final saveResult = await saveIndicatorFieldUseCase(
      indicatorToMoId: moved.indicatorToMoId,
      fields: {
        'parent_id': moved.parentId.toString(),
        'order': moved.order.toString(),
      },
    );

    if (saveResult.isLeft()) {
      final msg = saveResult.fold((f) => f.message, (_) => '');
      emit(KanbanState.saveError(message: msg, previousState: current));
      emit(current);
      return;
    }

    // Use the latest state so concurrent moves are not reverted.
    final latest = state;
    if (latest is KanbanLoaded) {
      emit(latest.copyWith(isSaving: false));
    }
  }

  /// Rebuilds the indicator list with reassigned sequential orders after a move.
  List<Indicator> _recalculateOrders(
    List<Indicator> all,
    Indicator moving,
    int newParentId,
    int insertPosition,
  ) {
    // Use List<Indicator>.from() to force the correct runtime type in DDC (web),
    // preventing "type 'Indicator' is not a subtype of type 'IndicatorModel'" errors.
    final rest = List<Indicator>.from(
        all.where((i) => i.indicatorToMoId != moving.indicatorToMoId));

    final targetItems = List<Indicator>.from(
        rest.where((i) => i.parentId == newParentId))
      ..sort((a, b) => a.order.compareTo(b.order));

    final clampedIdx = insertPosition.clamp(0, targetItems.length);
    final movedWithNewParent = moving.copyWith(parentId: newParentId);
    targetItems.insert(clampedIdx, movedWithNewParent);

    final others = List<Indicator>.from(
        rest.where((i) => i.parentId != newParentId));

    final renumberedTarget = <Indicator>[];
    for (int i = 0; i < targetItems.length; i++) {
      renumberedTarget.add(targetItems[i].copyWith(order: i + 1));
    }

    if (moving.parentId != null && moving.parentId != newParentId) {
      final srcItems = List<Indicator>.from(
          others.where((i) => i.parentId == moving.parentId))
        ..sort((a, b) => a.order.compareTo(b.order));
      final nonSrc = List<Indicator>.from(
          others.where((i) => i.parentId != moving.parentId));
      final renumberedSrc = <Indicator>[];
      for (int i = 0; i < srcItems.length; i++) {
        renumberedSrc.add(srcItems[i].copyWith(order: i + 1));
      }
      return [...nonSrc, ...renumberedSrc, ...renumberedTarget];
    }

    return [...others, ...renumberedTarget];
  }
}
