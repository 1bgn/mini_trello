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

    final midpoints = <double>[];
    for (final card in cards) {
      final key = _cardKeys[card.indicatorToMoId];
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      midpoints.add(topLeft.dy + box.size.height / 2);
    }

    if (midpoints.isEmpty) return cards.length;

    for (int i = 0; i < midpoints.length; i++) {
      if (globalPointerOffset.dy < midpoints[i]) return i;
    }
    return midpoints.length;
  }



  double? _localY(Offset globalPointerOffset) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(globalPointerOffset).dy;
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
          _insertionIndex = _calcInsertIndex(details.offset);
          _pointerLocalY = _localY(details.offset);
        });
      },
      onLeave: (_) => setState(() {
        _insertionIndex = null;
        _pointerLocalY = null;
      }),
      onAcceptWithDetails: (details) {
        final pos = _insertionIndex ?? widget.indicators.length;
        setState(() {
          _insertionIndex = null;
          _pointerLocalY = null;
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
