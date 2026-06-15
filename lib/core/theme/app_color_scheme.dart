import 'package:flutter/material.dart';

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.background,
    required this.card,
    required this.cardElevated,
    required this.primary,
    required this.primaryDark,
    required this.warning,
    required this.critical,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.cardShadow,
    required this.navBackground,
    required this.surfaceTint,
  });

  final Color background;
  final Color card;
  final Color cardElevated;
  final Color primary;
  final Color primaryDark;
  final Color warning;
  final Color critical;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color cardShadow;
  final Color navBackground;
  final Color surfaceTint;

  static const dark = AppColorScheme(
    background: Color(0xFF0F172A),
    card: Color(0xFF1E293B),
    cardElevated: Color(0xFF334155),
    primary: Color(0xFF22C55E),
    primaryDark: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    critical: Color(0xFFEF4444),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    divider: Color(0xFF334155),
    shimmerBase: Color(0xFF1E293B),
    shimmerHighlight: Color(0xFF334155),
    cardShadow: Color(0x66000000),
    navBackground: Color(0xFF1E293B),
    surfaceTint: Color(0xFF22C55E),
  );

  static const light = AppColorScheme(
    background: Color(0xFFF1F5F9),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFE2E8F0),
    primary: Color(0xFF16A34A),
    primaryDark: Color(0xFF15803D),
    warning: Color(0xFFD97706),
    critical: Color(0xFFDC2626),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    divider: Color(0xFFE2E8F0),
    shimmerBase: Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
    cardShadow: Color(0x1A0F172A),
    navBackground: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFF16A34A),
  );

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? card,
    Color? cardElevated,
    Color? primary,
    Color? primaryDark,
    Color? warning,
    Color? critical,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? cardShadow,
    Color? navBackground,
    Color? surfaceTint,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      warning: warning ?? this.warning,
      critical: critical ?? this.critical,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      cardShadow: cardShadow ?? this.cardShadow,
      navBackground: navBackground ?? this.navBackground,
      surfaceTint: surfaceTint ?? this.surfaceTint,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
    );
  }
}
