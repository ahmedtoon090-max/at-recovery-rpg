import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the Obsidian Sanctuary dark theme with WCAG AA+ contrast and
/// clear keyboard focus rings.
ThemeData buildObsidianTheme() {
  final bodyFont = GoogleFonts.inter();
  final displayFont = GoogleFonts.plusJakartaSans();

  final baseText = ThemeData.dark()
      .textTheme
      .copyWith(
        displayLarge: displayFont.copyWith(color: AppColors.textPrimary),
        displayMedium: displayFont.copyWith(color: AppColors.textPrimary),
        displaySmall: displayFont.copyWith(color: AppColors.textPrimary),
        headlineLarge: displayFont.copyWith(color: AppColors.textPrimary),
        headlineMedium: displayFont.copyWith(color: AppColors.textPrimary),
        headlineSmall: displayFont.copyWith(color: AppColors.textPrimary),
        titleLarge: displayFont.copyWith(color: AppColors.textPrimary),
        titleMedium: displayFont.copyWith(color: AppColors.textPrimary),
        titleSmall: bodyFont.copyWith(color: AppColors.textPrimary),
        bodyLarge: bodyFont.copyWith(color: AppColors.textPrimary),
        bodyMedium: bodyFont.copyWith(color: AppColors.textPrimary),
        bodySmall: bodyFont.copyWith(color: AppColors.textSecondary),
        labelLarge: bodyFont.copyWith(color: AppColors.textPrimary),
        labelMedium: bodyFont.copyWith(color: AppColors.textSecondary),
        labelSmall: bodyFont.copyWith(color: AppColors.textSecondary),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgVoid,
    canvasColor: AppColors.bgObsidian,
    cardColor: AppColors.bgObsidian,
    dividerColor: AppColors.borderSubtle,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bgObsidian,
      surfaceContainerHighest: AppColors.bgElevated,
      primary: AppColors.accentEmerald,
      onPrimary: AppColors.bgVoid,
      secondary: AppColors.accentGold,
      onSecondary: AppColors.bgVoid,
      tertiary: AppColors.accentCyan,
      error: AppColors.accentCrimson,
      onError: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderSubtle,
    ),
    textTheme: baseText,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgVoid,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: bodyFont.copyWith(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      hintStyle: bodyFont.copyWith(color: AppColors.textSecondary, fontSize: 14),
      labelStyle: bodyFont.copyWith(color: AppColors.textSecondary, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentEmerald, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentEmerald,
        foregroundColor: AppColors.bgVoid,
        minimumSize: const Size(44, 46),
        textStyle: displayFont.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(44, 46),
        side: const BorderSide(color: AppColors.borderHighlight),
        textStyle: bodyFont.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    focusColor: AppColors.accentEmerald.withValues(alpha: 0.24),
  );
}
