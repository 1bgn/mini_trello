import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/indicator.dart';

part 'kanban_event.freezed.dart';

@freezed
sealed class KanbanEvent with _$KanbanEvent {
  const factory KanbanEvent.load() = LoadIndicatorsEvent;
  const factory KanbanEvent.refresh() = RefreshIndicatorsEvent;




  const factory KanbanEvent.moveCard({
    required Indicator indicator,
    required int newParentId,
    required int insertPosition,
  }) = MoveCardEvent;
}
