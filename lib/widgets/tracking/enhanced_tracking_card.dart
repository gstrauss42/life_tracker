import 'package:flutter/material.dart';

/// An enhanced tracking card with hover effects, quick actions, and animations.
class EnhancedTrackingCard extends StatefulWidget {
  const EnhancedTrackingCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.goalValue,
    required this.unit,
    required this.onChanged,
    this.step = 1,
    this.onTap,
    this.quickActionIcon,
    this.quickActionLabel,
  });

  final String title;
  final IconData icon;
  final Color color;
  final double currentValue;
  final double goalValue;
  final String unit;
  final ValueChanged<double> onChanged;
  final double step;
  final VoidCallback? onTap;
  final IconData? quickActionIcon;
  final String? quickActionLabel;

  @override
  State<EnhancedTrackingCard> createState() => _EnhancedTrackingCardState();
}

class _EnhancedTrackingCardState extends State<EnhancedTrackingCard>
    with SingleTickerProviderStateMixin {
  double? _dragValue;
  bool _isDragging = false;
  bool _isHovered = false;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedTrackingCard oldWidget) {
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

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_hoverAnimation.value * 0.02),
                child: Card(
                  elevation: _hoverAnimation.value * 4,
                  shadowColor: widget.color.withValues(alpha: 0.3),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: _isHovered
                          ? widget.color.withValues(alpha: 0.3)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: _isHovered ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(14),
                    splashColor: widget.color.withValues(alpha: 0.1),
                    highlightColor: widget.color.withValues(alpha: 0.05),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(theme),
                            const Spacer(),
                            _buildValueDisplay(theme, displayValue, progress),
                            const SizedBox(height: 6),
                            _buildProgressBar(theme, constraints.maxWidth, progress),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Hero(
          tag: 'tracking_icon_${widget.title}',
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
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
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getProgressColor(progress).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(progress * 100).toInt()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getProgressColor(progress),
              fontWeight: _isDragging ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return widget.color;
    if (progress >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildProgressBar(ThemeData theme, double width, double progress) {
    // Guard against invalid width
    if (width <= 24 || !width.isFinite) {
      return const SizedBox(height: 32);
    }
    
    final effectiveWidth = (width - 24).clamp(0.0, double.infinity);
    final progressWidth = (progress * effectiveWidth).clamp(0.0, effectiveWidth);
    
    return GestureDetector(
      onHorizontalDragStart: (details) => _handleDragStart(details, width),
      onHorizontalDragUpdate: (details) => _handleDragUpdate(details, width),
      onHorizontalDragEnd: _handleDragEnd,
      onTapUp: (details) => _handleTap(details, width),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              // Progress fill with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 24,
                width: progressWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.8),
                    ],
                  ),
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
    // Guard against invalid width
    if (width <= 24 || !width.isFinite) {
      return const SizedBox.shrink();
    }
    
    final trackWidth = (width - 24).clamp(0.0, double.infinity);
    const handleSize = 26.0;
    final handleLeft = (progress * trackWidth - handleSize / 2).clamp(0.0, (trackWidth - handleSize).clamp(0.0, double.infinity));

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      left: handleLeft,
      top: -1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isDragging ? 1.1 : 1.0,
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
      ),
    );
  }

}

