import 'package:flutter/material.dart';

import 'app_color_scheme.dart';
import 'app_text_styles.dart';

extension AppThemeContext on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.dark;

  AppTextStyles get textStyles => AppTextStyles(appColors);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
