import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xCCA1A1AA),
    height: 1.45,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xB3A1A1AA),
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  const AppTextStyles._();
}
