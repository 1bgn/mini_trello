import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/indicator.dart';

part 'kanban_state.freezed.dart';

const kRootColumnId = 0;

@freezed
sealed class KanbanState with _$KanbanState {
  const KanbanState._();

  const factory KanbanState.initial() = KanbanInitial;
  const factory KanbanState.loading() = KanbanLoading;
  const factory KanbanState.loaded({
    required List<Indicator> indicators,
    @Default(false) bool isSaving,
  }) = KanbanLoaded;
  const factory KanbanState.error(String message) = KanbanError;
  const factory KanbanState.saveError({
    required String message,
    required KanbanLoaded previousState,


    @Default(false) bool isPermissionError,
  }) = KanbanSaveError;
}

extension KanbanLoadedX on KanbanLoaded {

  Set<int> get _referencedParentIds => indicators
      .where((i) => i.parentId != null && i.parentId! > 0)
      .map((i) => i.parentId!)
      .toSet();


  Set<int> get folderIds => indicators
      .map((i) => i.indicatorToMoId)
      .toSet()
      .intersection(_referencedParentIds);




  Map<int, List<Indicator>> get columns {
    final folders = folderIds;
    final map = <int, List<Indicator>>{};

    for (final pid in _referencedParentIds) {
      map.putIfAbsent(pid, () => []);
    }

    for (final indicator in indicators) {
      final pid = indicator.parentId;
      if (pid != null && pid > 0) {
        map.putIfAbsent(pid, () => []).add(indicator);
      } else if (!folders.contains(indicator.indicatorToMoId)) {

        map.putIfAbsent(kRootColumnId, () => []).add(indicator);
      }
    }

    for (final list in map.values) {
      list.sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        return cmp != 0 ? cmp : a.indicatorToMoId.compareTo(b.indicatorToMoId);
      });
    }
    return map;
  }


  Map<int, String> get columnNames {
    final names = <int, String>{};
    int fallback = 1;
    for (final columnId in columns.keys) {
      if (columnId == kRootColumnId) {
        names[columnId] = 'Без категории';
        continue;
      }
      final match =
          indicators.where((i) => i.indicatorToMoId == columnId).firstOrNull;
      names[columnId] = match?.name ?? 'Папка $fallback';
      if (match == null) fallback++;
    }
    return names;
  }
}
