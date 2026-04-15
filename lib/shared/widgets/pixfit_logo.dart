import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PixfitLogo extends StatelessWidget {
  const PixfitLogo({
    this.size = 84,
    this.glowStrength = 1,
    super.key,
  });

  final double size;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final outerRadius = size * 0.24;
    final innerRadius = size * 0.19;
    final iconSize = size * 0.60;
    final outerPadding = size * 0.095;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D1F39), Color(0xFF2B2F67)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C6FFF).withValues(alpha: 0.14),
            blurRadius: size * 0.48 * glowStrength,
            spreadRadius: size * 0.05 * glowStrength,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.24),
            blurRadius: size * 0.24 * glowStrength,
            spreadRadius: size * 0.02 * glowStrength,
            offset: Offset(0, size * 0.17),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(outerPadding),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(innerRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF242750), Color(0xFF31377B)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Center(
            child: SizedBox(
              height: iconSize,
              width: iconSize,
              child: Stack(
                children: [
                  Positioned(
                    left: iconSize * 0.18,
                    top: iconSize * 0.08,
                    bottom: iconSize * 0.08,
                    child: Container(
                      width: iconSize * 0.20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.98),
                            const Color(0xFFE5E6FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.22),
                            blurRadius: iconSize * 0.28 * glowStrength,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: iconSize * 0.36,
                    top: iconSize * 0.08,
                    child: Container(
                      height: iconSize * 0.40,
                      width: iconSize * 0.44,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.96),
                          width: iconSize * 0.056,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            blurRadius: iconSize * 0.24 * glowStrength,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
