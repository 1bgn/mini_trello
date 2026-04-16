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
  }) : super(const KanbanInitial()) {
    on<LoadIndicatorsEvent>(_onLoad);
    on<RefreshIndicatorsEvent>(_onRefresh);
    on<MoveCardEvent>(_onMoveCard);
  }

  Future<void> _onLoad(
    LoadIndicatorsEvent event,
    Emitter<KanbanState> emit,
  ) async {
    emit(const KanbanLoading());
    final result = await getIndicatorsUseCase();
    result.fold(
      (failure) => emit(KanbanError(failure.message)),
      (indicators) => emit(KanbanLoaded(indicators: indicators)),
    );
  }

  Future<void> _onRefresh(
    RefreshIndicatorsEvent event,
    Emitter<KanbanState> emit,
  ) async {
    final current = state;
    // Show a subtle saving indicator while refreshing.
    if (current is KanbanLoaded) {
      emit(current.copyWith(isSaving: true));
    } else {
      emit(const KanbanLoading());
    }

    final result = await getIndicatorsUseCase();
    result.fold(
      (failure) => emit(KanbanError(failure.message)),
      (indicators) => emit(KanbanLoaded(indicators: indicators)),
    );
  }

  Future<void> _onMoveCard(
    MoveCardEvent event,
    Emitter<KanbanState> emit,
  ) async {
    final current = state;
    if (current is! KanbanLoaded) return;

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

    // --- Persist parent_id ---
    final parentResult = await saveIndicatorFieldUseCase(
      indicatorToMoId: moved.indicatorToMoId,
      fieldName: 'parent_id',
      fieldValue: moved.parentId.toString(),
    );

    if (parentResult.isLeft()) {
      final msg = parentResult.fold((f) => f.message, (_) => '');
      // Emit error state for the listener, then immediately revert.
      emit(KanbanSaveError(message: msg, previousState: current));
      emit(current); // revert optimistic update
      return;
    }

    // --- Persist order ---
    final orderResult = await saveIndicatorFieldUseCase(
      indicatorToMoId: moved.indicatorToMoId,
      fieldName: 'order',
      fieldValue: moved.order.toString(),
    );

    if (orderResult.isLeft()) {
      final msg = orderResult.fold((f) => f.message, (_) => '');
      emit(KanbanSaveError(message: msg, previousState: current));
      emit(current); // revert optimistic update
      return;
    }

    emit(
      KanbanLoaded(indicators: updatedIndicators, isSaving: false),
    );
  }

  /// Rebuilds the indicator list with reassigned sequential orders after a move.
  List<Indicator> _recalculateOrders(
    List<Indicator> all,
    Indicator moving,
    int newParentId,
    int insertPosition,
  ) {
    // Remove the card being moved from the list.
    // Use List<Indicator>.from() to force the correct runtime type in DDC (web),
    // preventing "type 'Indicator' is not a subtype of type 'IndicatorModel'" errors.
    final rest = List<Indicator>.from(
        all.where((i) => i.indicatorToMoId != moving.indicatorToMoId));

    // Build the new target column list (sorted, without the moving card).
    final targetItems = List<Indicator>.from(
        rest.where((i) => i.parentId == newParentId))
      ..sort((a, b) => a.order.compareTo(b.order));

    // Insert the card at the requested position.
    final clampedIdx = insertPosition.clamp(0, targetItems.length);
    final movedWithNewParent = moving.copyWith(parentId: newParentId);
    targetItems.insert(clampedIdx, movedWithNewParent);

    // Remove target-column cards from rest so we can add them back renumbered.
    final others = List<Indicator>.from(
        rest.where((i) => i.parentId != newParentId));

    // Renumber target column 1, 2, 3 …
    final renumberedTarget = <Indicator>[];
    for (int i = 0; i < targetItems.length; i++) {
      renumberedTarget.add(targetItems[i].copyWith(order: i + 1));
    }

    // Also renumber the source column if different.
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
