import 'package:equatable/equatable.dart';
import '../../domain/entities/indicator.dart';

abstract class KanbanEvent extends Equatable {
  const KanbanEvent();

  @override
  List<Object?> get props => [];
}

class LoadIndicatorsEvent extends KanbanEvent {
  const LoadIndicatorsEvent();
}

class RefreshIndicatorsEvent extends KanbanEvent {
  const RefreshIndicatorsEvent();
}

/// Emitted when a card is dropped onto a new position.
/// [insertPosition] is the 0-based index in the target column's sorted card list
/// where the card should be inserted.
class MoveCardEvent extends KanbanEvent {
  final Indicator indicator;
  final int newParentId;
  final int insertPosition;

  const MoveCardEvent({
    required this.indicator,
    required this.newParentId,
    required this.insertPosition,
  });

  @override
  List<Object?> get props => [indicator, newParentId, insertPosition];
}
