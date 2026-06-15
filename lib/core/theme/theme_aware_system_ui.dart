import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_extensions.dart';

class ThemeAwareSystemUI extends StatelessWidget {
  const ThemeAwareSystemUI({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colors = context.appColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colors.navBackground,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}
