import 'package:equatable/equatable.dart';

class Indicator extends Equatable {
  final int indicatorToMoId;
  final int? parentId;
  final String name;
  final int order;

  const Indicator({
    required this.indicatorToMoId,
    this.parentId,
    required this.name,
    required this.order,
  });

  Indicator copyWith({
    int? indicatorToMoId,
    int? parentId,
    String? name,
    int? order,
  }) {
    return Indicator(
      indicatorToMoId: indicatorToMoId ?? this.indicatorToMoId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [indicatorToMoId, parentId, name, order];
}
