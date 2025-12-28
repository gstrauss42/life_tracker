import 'package:flutter/material.dart';

/// A progress card with a draggable slider for adjusting values.
class DraggableProgressCard extends StatefulWidget {
  const DraggableProgressCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.goalValue,
    required this.unit,
    required this.onChanged,
    this.step = 1,
  });

  final String title;
  final IconData icon;
  final Color color;
  final double currentValue;
  final double goalValue;
  final String unit;
  final ValueChanged<double> onChanged;
  final double step;

  @override
  State<DraggableProgressCard> createState() => _DraggableProgressCardState();
}

class _DraggableProgressCardState extends State<DraggableProgressCard> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  void didUpdateWidget(DraggableProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragValue != null && widget.currentValue == _dragValue) {
      _dragValue = null;
    }
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  double _snapToStep(double value) {
    return (value / widget.step).round() * widget.step;
  }

  void _handleDragStart(DragStartDetails details, double width) {
    setState(() => _isDragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    final maxValue = widget.goalValue;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    final effectiveWidth = width - 24;
    final relativeX = (localPosition.dx - 12).clamp(0, effectiveWidth);
    final percentage = relativeX / effectiveWidth;
    final rawValue = percentage * maxValue;
    final snappedValue = _snapToStep(rawValue).clamp(0.0, maxValue);

    setState(() => _dragValue = snappedValue);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragValue != null) {
      widget.onChanged(_dragValue!);
    }
    setState(() => _isDragging = false);
  }

  void _handleTap(TapUpDetails details, double width) {
    final maxValue = widget.goalValue;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    final effectiveWidth = width - 24;
    final relativeX = (localPosition.dx - 12).clamp(0, effectiveWidth);
    final percentage = relativeX / effectiveWidth;
    final rawValue = percentage * maxValue;
    final snappedValue = _snapToStep(rawValue).clamp(0.0, maxValue);

    widget.onChanged(snappedValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = _dragValue ?? widget.currentValue;
    final maxValue = widget.goalValue;
    final progress = (displayValue / maxValue).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const Spacer(),
                _buildValueDisplay(theme, displayValue, progress),
                const SizedBox(height: 8),
                _buildProgressBar(theme, constraints.maxWidth, progress),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: widget.color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(ThemeData theme, double displayValue, double progress) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _formatValue(displayValue),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '/ ${_formatValue(widget.goalValue)} ${widget.unit}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme, double width, double progress) {
    return GestureDetector(
      onHorizontalDragStart: (details) => _handleDragStart(details, width),
      onHorizontalDragUpdate: (details) => _handleDragUpdate(details, width),
      onHorizontalDragEnd: _handleDragEnd,
      onTapUp: (details) => _handleTap(details, width),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track background
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Progress fill
              Container(
                height: 24,
                width: progress * (width - 24),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Drag handle
              _buildDragHandle(theme, width, progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme, double width, double progress) {
    final trackWidth = width - 24;
    const handleSize = 26.0;
    final handleLeft = (progress * trackWidth - handleSize / 2).clamp(0.0, trackWidth - handleSize);

    return Positioned(
      left: handleLeft,
      top: -1,
      child: Container(
        width: handleSize,
        height: handleSize,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.surface,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isDragging
            ? Icon(
                Icons.drag_indicator,
                size: 12,
                color: theme.colorScheme.surface,
              )
            : null,
      ),
    );
  }
}

