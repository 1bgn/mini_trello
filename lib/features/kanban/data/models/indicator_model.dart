import '../../domain/entities/indicator.dart';

class IndicatorModel extends Indicator {
  const IndicatorModel({
    required super.indicatorToMoId,
    super.parentId,
    required super.name,
    required super.order,
    super.allowEdit = true,
  });

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    final rawParentId = json['parent_id'];
    int? parsedParentId;
    if (rawParentId != null) {
      final parsed = _parseInt(rawParentId);
      parsedParentId = (parsed > 0) ? parsed : null;
    }

    return IndicatorModel(
      indicatorToMoId: _parseInt(json['indicator_to_mo_id']),
      parentId: parsedParentId,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Без названия',
      order: json['order'] != null ? _parseInt(json['order']) : 0,
      allowEdit: json['allow_edit'] == true || json['allow_edit'] == 1,
    );
  }

  @override
  IndicatorModel copyWith({
    int? indicatorToMoId,
    int? parentId,
    String? name,
    int? order,
    bool? allowEdit,
  }) {
    return IndicatorModel(
      indicatorToMoId: indicatorToMoId ?? this.indicatorToMoId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      order: order ?? this.order,
      allowEdit: allowEdit ?? this.allowEdit,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
