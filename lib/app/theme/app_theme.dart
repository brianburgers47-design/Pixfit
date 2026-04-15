import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMuted,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: const BorderSide(color: Color(0x33A1A1AA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: AppTextStyles.bodyMuted.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppTextStyles.title,
        contentTextStyle: AppTextStyles.bodyMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  const AppTheme._();
}
