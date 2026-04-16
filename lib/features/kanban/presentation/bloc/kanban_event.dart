import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/indicator.dart';

part 'kanban_event.freezed.dart';

@freezed
sealed class KanbanEvent with _$KanbanEvent {
  const factory KanbanEvent.load() = LoadIndicatorsEvent;
  const factory KanbanEvent.refresh() = RefreshIndicatorsEvent;

  /// Emitted when a card is dropped onto a new position.
  /// [insertPosition] is the 0-based index in the target column's sorted card
  /// list where the card should be inserted.
  const factory KanbanEvent.moveCard({
    required Indicator indicator,
    required int newParentId,
    required int insertPosition,
  }) = MoveCardEvent;
}
