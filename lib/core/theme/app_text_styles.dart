import 'package:flutter/material.dart';

import 'app_color_scheme.dart';

class AppTextStyles {
  AppTextStyles(this._colors);

  final AppColorScheme _colors;

  static const String _fontFamily = 'Roboto';

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle get displayLarge => _base(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: _colors.textPrimary,
        letterSpacing: -1.5,
      );

  TextStyle get headlineLarge => _base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _colors.textPrimary,
        letterSpacing: -0.5,
      );

  TextStyle get headlineMedium => _base(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      );

  TextStyle get titleLarge => _base(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      );

  TextStyle get titleMedium => _base(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _colors.textPrimary,
      );

  TextStyle get bodyLarge => _base(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _colors.textPrimary,
      );

  TextStyle get bodyMedium => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _colors.textSecondary,
      );

  TextStyle get labelLarge => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      );

  TextStyle get labelSmall => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _colors.textSecondary,
        letterSpacing: 0.5,
      );
}
