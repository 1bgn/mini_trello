import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/indicator.dart';
import '../bloc/kanban_bloc.dart';
import '../bloc/kanban_event.dart';
import '../bloc/kanban_state.dart';
import 'kanban_column_widget.dart';

class KanbanBoardWidget extends StatefulWidget {
  final KanbanLoaded state;

  const KanbanBoardWidget({super.key, required this.state});

  @override
  State<KanbanBoardWidget> createState() => _KanbanBoardWidgetState();
}

class _KanbanBoardWidgetState extends State<KanbanBoardWidget> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCardDropped(
    Indicator indicator,
    int targetColumnId,
    int insertPosition,
  ) {
    // Guard: dropping to the exact same position in the same column is a no-op.
    final currentColumn = widget.state.columns[indicator.parentId] ?? [];
    if (indicator.parentId == targetColumnId) {
      final currentIdx = currentColumn.indexWhere(
        (i) => i.indicatorToMoId == indicator.indicatorToMoId,
      );
      // If inserting above or at current position → same spot
      if (currentIdx == insertPosition || currentIdx + 1 == insertPosition) {
        return;
      }
    }

    context.read<KanbanBloc>().add(
          MoveCardEvent(
            indicator: indicator,
            newParentId: targetColumnId,
            insertPosition: insertPosition,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.state.columns;
    final columnNames = widget.state.columnNames;
    final columnIds = columns.keys.toList()..sort();

    if (columnIds.isEmpty) {
      return _EmptyBoard(isSaving: widget.state.isSaving);
    }

    return Stack(
      children: [
        Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final delta = event.scrollDelta.dy;
              _scrollController.animateTo(
                (_scrollController.offset + delta).clamp(
                  0.0,
                  _scrollController.position.maxScrollExtent,
                ),
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
              );
            }
          },
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
              itemCount: columnIds.length,
              itemBuilder: (context, index) {
                final columnId = columnIds[index];
                final cards = columns[columnId] ?? [];
                final name = columnNames[columnId] ?? 'Папка ${index + 1}';
                final color =
                    AppColors.columnColors[index % AppColors.columnColors.length];

                return KanbanColumnWidget(
                  key: ValueKey(columnId),
                  columnId: columnId,
                  columnName: name,
                  indicators: cards,
                  columnColor: color,
                  colorIndex: index,
                  onCardDropped: _onCardDropped,
                );
              },
            ),
          ),
        ),

        if (widget.state.isSaving)
          Positioned(
            top: 12,
            right: 20,
            child: _SavingBadge(),
          ),
      ],
    );
  }
}

class _SavingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Сохранение…',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  final bool isSaving;

  const _EmptyBoard({required this.isSaving});

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 72,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Задачи не найдены',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Нет задач для отображения за выбранный период',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
