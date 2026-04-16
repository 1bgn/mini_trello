import 'package:equatable/equatable.dart';
import '../../domain/entities/indicator.dart';

abstract class KanbanState extends Equatable {
  const KanbanState();

  @override
  List<Object?> get props => [];
}

class KanbanInitial extends KanbanState {
  const KanbanInitial();
}

class KanbanLoading extends KanbanState {
  const KanbanLoading();
}

class KanbanLoaded extends KanbanState {
  final List<Indicator> indicators;
  final bool isSaving;

  const KanbanLoaded({required this.indicators, this.isSaving = false});

  /// Returns all unique parent IDs that are referenced by at least one task.
  Set<int> get _referencedParentIds => indicators
      .where((i) => i.parentId != null && i.parentId! > 0)
      .map((i) => i.parentId!)
      .toSet();

  /// IDs of indicators that act as folders (their ID is used as parentId).
  Set<int> get folderIds => indicators
      .map((i) => i.indicatorToMoId)
      .toSet()
      .intersection(_referencedParentIds);

  /// Grouped columns: { parentId -> sorted task list }.
  /// Folder items themselves are excluded from columns.
  Map<int, List<Indicator>> get columns {
    final folders = folderIds;
    final referenced = _referencedParentIds;
    final map = <int, List<Indicator>>{};

    // Ensure every referenced column exists (even if empty).
    for (final pid in referenced) {
      map.putIfAbsent(pid, () => []);
    }

    for (final indicator in indicators) {
      // Skip items that are folders themselves.
      if (folders.contains(indicator.indicatorToMoId)) continue;
      final pid = indicator.parentId;
      if (pid != null && pid > 0) {
        map.putIfAbsent(pid, () => []).add(indicator);
      }
    }

    // Sort each column by order, then by ID for stability.
    for (final list in map.values) {
      list.sort((a, b) {
        final cmp = a.order.compareTo(b.order);
        return cmp != 0 ? cmp : a.indicatorToMoId.compareTo(b.indicatorToMoId);
      });
    }
    return map;
  }

  /// Human-readable name for each column.
  Map<int, String> get columnNames {
    final names = <int, String>{};
    int fallback = 1;
    for (final columnId in columns.keys) {
      final match = indicators
          .where((i) => i.indicatorToMoId == columnId)
          .firstOrNull;
      names[columnId] = match?.name ?? 'Папка $fallback';
      if (match == null) fallback++;
    }
    return names;
  }

  KanbanLoaded copyWith({List<Indicator>? indicators, bool? isSaving}) {
    return KanbanLoaded(
      indicators: indicators ?? this.indicators,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [indicators, isSaving];
}

class KanbanError extends KanbanState {
  final String message;

  const KanbanError(this.message);

  @override
  List<Object?> get props => [message];
}

class KanbanSaveError extends KanbanState {
  final String message;
  final KanbanLoaded previousState;

  const KanbanSaveError({required this.message, required this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}
