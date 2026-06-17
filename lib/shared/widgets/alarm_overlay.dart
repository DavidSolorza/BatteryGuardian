import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_extensions.dart';

class AlarmOverlay extends StatefulWidget {
  const AlarmOverlay({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  State<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<AlarmOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  void _updateTime() {
    final now = DateTime.now();
    final newTime = DateFormat('HH:mm').format(now);
    if (newTime != _timeString) {
      setState(() => _timeString = newTime);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -300) {
              widget.onDismiss();
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.15),
                  child: child,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 80,
                  color: colors.critical.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _timeString,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE d \'de\' MMMM', 'es').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.stop_circle_outlined, size: 32),
                    label: const Text(
                      'DETENER ALARMA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.critical,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'o desliza hacia arriba para detener',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
