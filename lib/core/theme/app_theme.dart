import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color_scheme.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData lightTheme = _buildTheme(AppColorScheme.light, Brightness.light);
  static ThemeData darkTheme = _buildTheme(AppColorScheme.dark, Brightness.dark);

  static ThemeData _buildTheme(AppColorScheme colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: isDark ? colors.background : Colors.white,
        secondary: colors.primary,
        onSecondary: isDark ? colors.background : Colors.white,
        error: colors.critical,
        onError: Colors.white,
        surface: colors.card,
        onSurface: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: isDark ? 0 : 1,
        shadowColor: colors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles(colors).titleLarge,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.navBackground,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.primary : colors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.textSecondary,
            size: 24,
          );
        }),
        height: 72,
        elevation: isDark ? 0 : 2,
        shadowColor: colors.cardShadow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.navBackground,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withValues(alpha: 0.3);
          }
          return colors.divider;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.divider,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.2),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.card),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.cardElevated,
        contentTextStyle: AppTextStyles(colors).bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? colors.textPrimary : Colors.white,
        ),
      ),
    );
  }
}
