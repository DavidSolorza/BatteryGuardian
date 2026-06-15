import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colors.shimmerBase,
                Color.lerp(
                  colors.shimmerBase,
                  colors.shimmerHighlight,
                  _controller.value,
                )!,
                colors.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SkeletonLoader(height: 220, borderRadius: 110),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 100, borderRadius: 20)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 100, borderRadius: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 100, borderRadius: 20)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 100, borderRadius: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
