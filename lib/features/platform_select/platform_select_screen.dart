// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../shared/models/selected_media.dart';
import '../analytics/analytics_service.dart';
import '../preview/preview_screen.dart';

class PlatformSelectScreen extends StatefulWidget {
  const PlatformSelectScreen({this.initialMedia, super.key});

  final SelectedMedia? initialMedia;

  @override
  State<PlatformSelectScreen> createState() => _PlatformSelectScreenState();
}

class _PlatformSelectScreenState extends State<PlatformSelectScreen> {
  final TextEditingController _customXController = TextEditingController();
  final TextEditingController _customYController = TextEditingController();
  String? _customRatioError;

  @override
  void dispose() {
    _customXController.dispose();
    _customYController.dispose();
    super.dispose();
  }

  void _openPreview(String platform) {
    print('Selected platform: $platform');
    AnalyticsService.track('platform_selected', {'platform': platform});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          platform: platform,
          initialMedia: widget.initialMedia,
        ),
      ),
    );
  }

  int? _parseValidPart(String rawValue) {
    if (rawValue.isEmpty) {
      return null;
    }

    final value = int.tryParse(rawValue);

    if (value == null || value <= 0 || value > 9999) {
      return null;
    }

    return value;
  }

  void _openCustomPreview() {
    final xValue = _parseValidPart(_customXController.text.trim());
    final yValue = _parseValidPart(_customYController.text.trim());

    if (xValue == null || yValue == null) {
      const errorMessage =
          'Vul twee geldige positieve getallen in tussen 1 en 9999.';

      setState(() {
        _customRatioError = errorMessage;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Vul twee geldige positieve getallen in tussen 1 en 9999.',
            ),
          ),
        );
      return;
    }

    setState(() {
      _customRatioError = null;
    });

    print('Selected platform: custom');
    print('Custom ratio: $xValue:$yValue');
    AnalyticsService.track('platform_selected', {
      'platform': 'custom',
      'customX': xValue,
      'customY': yValue,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          platform: 'custom',
          customWidth: xValue,
          customHeight: yValue,
          initialMedia: widget.initialMedia,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kies een platform')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Text(
                          'Selecteer een formaat',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        'Kies een platform',
                        style: textTheme.headlineLarge?.copyWith(fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Selecteer het formaat dat je nodig hebt',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _PlatformCard(
                      title: 'Instagram Post',
                      ratio: '1:1',
                      onTap: () => _openPreview('instagram_post'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PlatformCard(
                      title: 'Instagram Story',
                      ratio: '9:16',
                      onTap: () => _openPreview('instagram_story'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PlatformCard(
                      title: 'TikTok',
                      ratio: '9:16',
                      onTap: () => _openPreview('tiktok'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PlatformCard(
                      title: 'YouTube',
                      ratio: '16:9',
                      onTap: () => _openPreview('youtube'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CustomRatioCard(
                      xController: _customXController,
                      yController: _customYController,
                      errorText: _customRatioError,
                      onChanged: () {
                        if (_customRatioError != null) {
                          setState(() {
                            _customRatioError = null;
                          });
                        }
                      },
                      onTap: _openCustomPreview,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.title,
    required this.ratio,
    required this.onTap,
  });

  final String title;
  final String ratio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.04),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ratio,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomRatioCard extends StatelessWidget {
  const _CustomRatioCard({
    required this.xController,
    required this.yController,
    required this.errorText,
    required this.onChanged,
    required this.onTap,
  });

  final TextEditingController xController;
  final TextEditingController yController;
  final String? errorText;
  final VoidCallback onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.04),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vrij formaat',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'X:Y',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Gebruik je eigen verhouding', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _RatioField(
                      controller: xController,
                      hintText: 'X',
                      onChanged: onChanged,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      ':',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _RatioField(
                      controller: yController,
                      hintText: 'Y',
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  errorText ?? '',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFF8A8A),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatioField extends StatelessWidget {
  const _RatioField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.52),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
