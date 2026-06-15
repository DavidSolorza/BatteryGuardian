import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

abstract final class Responsive {
  static const double compactMax = 599;
  static const double mediumMax = 839;

  static ScreenSize screenSizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= compactMax) return ScreenSize.compact;
    if (width <= mediumMax) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.compact;

  static bool isMedium(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.medium;

  static bool isExpanded(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.expanded;

  static bool useNavigationRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 840;

  static double contentMaxWidth(BuildContext context) {
    return switch (screenSizeOf(context)) {
      ScreenSize.compact => double.infinity,
      ScreenSize.medium => 720,
      ScreenSize.expanded => 1100,
    };
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return switch (screenSizeOf(context)) {
      ScreenSize.compact => const EdgeInsets.all(20),
      ScreenSize.medium => const EdgeInsets.fromLTRB(28, 16, 28, 24),
      ScreenSize.expanded => const EdgeInsets.fromLTRB(40, 20, 40, 28),
    };
  }

  static int gridColumns(
    BuildContext context, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
  }) {
    return switch (screenSizeOf(context)) {
      ScreenSize.compact => compact,
      ScreenSize.medium => medium,
      ScreenSize.expanded => expanded,
    };
  }

  static double batteryIndicatorSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return 280;
    if (width >= 600) return 240;
    return width * 0.55;
  }

  static double gridAspectRatio(BuildContext context) {
    return isCompact(context) ? 1.5 : 1.35;
  }
}
