import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Dark-Fantasy RPG Typography System:
/// - Cinzel for carved realm titles, boss names, medallions, and victory banners.
/// - Plus Jakarta Sans / Inter for crystal-clear UI copy.
/// - JetBrains Mono with tabular figures for live counters & stats.
abstract final class AppTypography {
  static const double desktopBreakpoint = 720.0;

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  static TextStyle cinzelDisplay(
    double width, {
    double? size,
    Color color = AppColors.textPrimary,
    double letterSpacing = 1.2,
  }) {
    final baseSize = size ?? (isDesktopWidth(width) ? 26.0 : 22.0);
    return GoogleFonts.cinzel(
      fontSize: baseSize,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
      height: 1.15,
      color: color,
    );
  }

  static TextStyle cinzelTitle(
    double width, {
    Color color = AppColors.accentGold,
  }) {
    final desktop = isDesktopWidth(width);
    return GoogleFonts.cinzel(
      fontSize: desktop ? 22.0 : 19.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      height: 1.2,
      color: color,
    );
  }

  static TextStyle heroDays(double width) {
    final desktop = isDesktopWidth(width);
    final size = desktop ? 58.0 : 46.0;
    return GoogleFonts.cinzel(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.02,
      color: AppColors.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle liveSubCounter(
    double width, {
    Color color = AppColors.accentEmeraldGlow,
  }) {
    final desktop = isDesktopWidth(width);
    final size = desktop ? 18.0 : 15.5;
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * 0.04,
      height: 1.2,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle monoStat({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle screenTitle(double width) {
    final desktop = isDesktopWidth(width);
    final size = desktop ? 27.0 : 23.0;
    return GoogleFonts.cinzel(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      height: 1.2,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle cardTitle(double width) {
    final desktop = isDesktopWidth(width);
    final size = desktop ? 17.0 : 16.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * -0.01,
      height: 1.3,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle bodyCopy(
    double width, {
    Color color = AppColors.textSecondary,
  }) {
    final desktop = isDesktopWidth(width);
    final size = desktop ? 14.5 : 13.5;
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.48,
      color: color,
    );
  }

  static TextStyle microLabel(
    double width, {
    Color color = AppColors.textSecondary,
  }) {
    final desktop = isDesktopWidth(width);
    final size = desktop ? 11.5 : 10.5;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * 0.09,
      height: 1.2,
      color: color,
    );
  }
}
