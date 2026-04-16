import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/indicator.dart';
import 'kanban_card_widget.dart';

typedef OnCardDropped = void Function(
  Indicator indicator,
  int targetColumnId,
  int insertPosition,
);

bool get _isDesktop =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

class KanbanColumnWidget extends StatefulWidget {
  final int columnId;
  final String columnName;
  final List<Indicator> indicators;
  final Color columnColor;
  final int colorIndex;
  final Indicator? draggingIndicator;
  final OnCardDropped onCardDropped;

  const KanbanColumnWidget({
    super.key,
    required this.columnId,
    required this.columnName,
    required this.indicators,
    required this.columnColor,
    required this.colorIndex,
    required this.onCardDropped,
    this.draggingIndicator,
  });

  @override
  State<KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<KanbanColumnWidget> {

  int? _insertionIndex;

  double? _pointerLocalY;

  double _lastPointerGlobalY = double.negativeInfinity;

  final _scrollController = ScrollController();



  final _cardKeys = <int, GlobalKey>{};

  GlobalKey _keyFor(int id) =>
      _cardKeys.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }





  int _calcInsertIndex(Offset globalPointerOffset) {
    final cards = widget.indicators;
    if (cards.isEmpty) return 0;

    final isDraggingDown = globalPointerOffset.dy >= _lastPointerGlobalY;
    final thresholdFraction = isDraggingDown ? 0.25 : 0.75;

    for (int i = 0; i < cards.length; i++) {
      final key = _cardKeys[cards[i].indicatorToMoId];
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      if (globalPointerOffset.dy < topLeft.dy + box.size.height * thresholdFraction) {
        return i;
      }
    }
    return cards.length;
  }



  double? _boundaryLocalY(int insertIndex) {
    final columnBox = context.findRenderObject() as RenderBox?;
    if (columnBox == null) return null;
    final cards = widget.indicators;
    if (cards.isEmpty) return null;

    double globalY;
    if (insertIndex <= 0) {
      final key = _cardKeys[cards.first.indicatorToMoId];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return null;
      globalY = box.localToGlobal(Offset.zero).dy;
    } else if (insertIndex >= cards.length) {
      final key = _cardKeys[cards.last.indicatorToMoId];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return null;
      globalY = box.localToGlobal(Offset(0, box.size.height)).dy;
    } else {
      final prevBox = _cardKeys[cards[insertIndex - 1].indicatorToMoId]
          ?.currentContext
          ?.findRenderObject() as RenderBox?;
      final nextBox = _cardKeys[cards[insertIndex].indicatorToMoId]
          ?.currentContext
          ?.findRenderObject() as RenderBox?;
      if (prevBox == null || nextBox == null) return null;
      final prevBottom = prevBox.localToGlobal(Offset(0, prevBox.size.height)).dy;
      final nextTop = nextBox.localToGlobal(Offset.zero).dy;
      globalY = (prevBottom + nextTop) / 2;
    }
    return columnBox.globalToLocal(Offset(0, globalY)).dy;
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      width: 288,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.columnBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ColumnHeader(
            name: widget.columnName,
            count: widget.indicators.length,
            color: widget.columnColor,
          ),
          Expanded(child: _buildDropArea()),
        ],
      ),
    );
  }




  Widget _buildDropArea() {
    return DragTarget<Indicator>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        setState(() {
          final idx = _calcInsertIndex(details.offset);
          _insertionIndex = idx;
          _pointerLocalY = _boundaryLocalY(idx);
          _lastPointerGlobalY = details.offset.dy;
        });
      },
      onLeave: (_) => setState(() {
        _insertionIndex = null;
        _pointerLocalY = null;
        _lastPointerGlobalY = double.negativeInfinity;
      }),
      onAcceptWithDetails: (details) {
        final pos = _insertionIndex ?? widget.indicators.length;
        setState(() {
          _insertionIndex = null;
          _pointerLocalY = null;
          _lastPointerGlobalY = double.negativeInfinity;
        });
        widget.onCardDropped(details.data, widget.columnId, pos);
      },
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return Stack(
          children: [
            _buildCardList(),

            if (isHovering && _pointerLocalY != null)
              _InsertionLine(
                y: _pointerLocalY!,
                color: widget.columnColor,
              ),
            if (isHovering)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.columnColor.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCardList() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.indicators.length,
        itemBuilder: (context, index) {
          final indicator = widget.indicators[index];
          return _buildDraggableCard(indicator);
        },
      ),
    );
  }

  Widget _buildDraggableCard(Indicator indicator) {
    final cardKey = _keyFor(indicator.indicatorToMoId);

    final feedback = KanbanCardFeedback(
      indicator: indicator,
      accentColor: widget.columnColor,
    );
    final ghost = KanbanCardGhost(indicator: indicator);
    final card = KanbanCardWidget(
      indicator: indicator,
      accentColor: widget.columnColor,
    );



    final child = Container(key: cardKey, child: card);

    if (_isDesktop) {

      return Draggable<Indicator>(
        data: indicator,
        feedback: feedback,
        childWhenDragging: ghost,
        child: child,
      );
    } else {

      return LongPressDraggable<Indicator>(
        data: indicator,
        delay: const Duration(milliseconds: 250),
        feedback: feedback,
        childWhenDragging: ghost,
        child: child,
      );
    }
  }
}

class _InsertionLine extends StatelessWidget {
  final double y;
  final Color color;

  const _InsertionLine({required this.y, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (y - 2).clamp(0.0, double.infinity),
      left: 10,
      right: 10,
      child: IgnorePointer(
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final String name;
  final int count;
  final Color color;

  const _ColumnHeader({
    required this.name,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.columnBg,
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _CountBadge(count: count, color: color),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
