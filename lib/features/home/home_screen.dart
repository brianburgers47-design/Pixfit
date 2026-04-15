// ignore_for_file: avoid_print

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../shared/models/selected_media.dart';
import '../../shared/widgets/pixfit_logo.dart';
import '../analytics/analytics_service.dart';
import '../platform_select/platform_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SelectedMedia? _createSelectedMedia(PlatformFile file) {
    final nameParts = file.name.split('.');
    final fallbackExtension = nameParts.length > 1 ? nameParts.last : '';
    final extension = (file.extension ?? fallbackExtension).toLowerCase();
    final isImage =
        extension == 'jpg' || extension == 'jpeg' || extension == 'png';

    print('FILE PICKED');
    print('FILE SELECTED: ${file.name}');
    print('EXTENSION: ${file.extension}');

    if (!isImage || file.bytes == null) {
      return null;
    }

    print('MEDIA TYPE: ${MediaType.image}');

    return SelectedMedia(
      type: MediaType.image,
      fileName: file.name,
      bytes: file.bytes,
    );
  }

  Future<void> _pickMediaAndContinue() async {
    print('UPLOAD BUTTON PRESSED');

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Bestand kiezen...')));

    try {
      print('PICKER OPENED');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (!mounted) {
        return;
      }

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Geen bestand gekozen')));
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      final media = _createSelectedMedia(file);

      if (bytes == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Bestand kon niet geladen worden')),
          );
        return;
      }

      if (media == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Bestand kon niet geladen worden')),
          );
        return;
      }

      AnalyticsService.track('image_uploaded');
      print('NAVIGATING TO PLATFORM SELECT');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlatformSelectScreen(initialMedia: media),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Bestand kon niet geladen worden')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17181F),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFB2B0D8).withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          blurRadius: 46,
                          spreadRadius: 2,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const PixfitLogo(),
                        const SizedBox(height: 26),
                        Text(
                          'Pixfit',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineLarge?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Maak je content direct passend voor elk platform',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.78,
                            ),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF5B57EF), Color(0xFF716CFF)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            blurRadius: 24,
                            spreadRadius: 1.5,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _pickMediaAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: const StadiumBorder(),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        child: const Text('Upload foto'),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Snel, rustig en gemaakt voor creators die vaak posten.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.70),
                      height: 1.5,
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
