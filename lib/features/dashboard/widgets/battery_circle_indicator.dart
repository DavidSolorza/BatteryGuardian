import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';

class BatteryCircleIndicator extends StatefulWidget {
  const BatteryCircleIndicator({
    super.key,
    required this.level,
    required this.statusColor,
  });

  final int level;
  final Color statusColor;

  @override
  State<BatteryCircleIndicator> createState() => _BatteryCircleIndicatorState();
}

class _BatteryCircleIndicatorState extends State<BatteryCircleIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.level.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(BatteryCircleIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.level.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Responsive.batteryIndicatorSize(context).clamp(180.0, 300.0);
    final textStyles = context.textStyles;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayLevel = _animation.value.round();
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _CirclePainter(
                  progress: displayLevel / 100,
                  color: widget.statusColor,
                  trackColor: context.appColors.cardElevated,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayLevel',
                    style: textStyles.displayLarge.copyWith(
                      color: widget.statusColor,
                      fontSize: size * 0.22,
                    ),
                  ),
                  Text(
                    '%',
                    style: textStyles.bodyMedium.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.4), color],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
