// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../shared/models/selected_media.dart';
import '../analytics/analytics_service.dart';
import '../entitlements/entitlement_service.dart';
import '../paywall/paywall_screen.dart';
import 'export_downloader.dart';
import 'image_render_service.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    required this.platform,
    this.initialMedia,
    this.customWidth,
    this.customHeight,
    super.key,
  });

  final String platform;
  final SelectedMedia? initialMedia;
  final int? customWidth;
  final int? customHeight;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  static const ImageRenderService _imageRenderService = ImageRenderService();

  SelectedMedia? _selectedMedia;
  Uint8List? _imageBytes;
  Uint8List? _renderedImageBytes;
  double? _originalAspectRatio;
  final EntitlementService _entitlements = EntitlementService.instance;
  bool _isExporting = false;
  bool _isPickingMedia = false;
  bool _isRenderingImage = false;

  ImageRenderTarget _currentTarget() {
    return _imageRenderService.getTargetForPlatform(
      platform: widget.platform,
      customX: widget.customWidth,
      customY: widget.customHeight,
    );
  }

  @override
  void initState() {
    super.initState();
    print('PreviewScreen platform: ${widget.platform}');
    AnalyticsService.track('preview_viewed', {'platform': widget.platform});
    _selectedMedia = widget.initialMedia;
    _entitlements.addListener(_handleEntitlementChange);
    _syncImageBytesFromMedia();
    _refreshEntitlements();
    _prepareRenderedImage();
  }

  @override
  void dispose() {
    _entitlements.removeListener(_handleEntitlementChange);
    super.dispose();
  }

  void _handleEntitlementChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshEntitlements() async {
    await _entitlements.refresh();
  }

  void _syncImageBytesFromMedia() {
    final media = _selectedMedia;

    if (media?.type == MediaType.image) {
      _imageBytes = media?.bytes;
    } else {
      _imageBytes = null;
    }
  }

  Future<void> _prepareRenderedImage() async {
    final imageBytes = _imageBytes;

    if (imageBytes == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _renderedImageBytes = null;
        _isRenderingImage = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isRenderingImage = true;
      });
    }

    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;
      final originalAspectRatio = originalImage.width / originalImage.height;

      final result = await _imageRenderService.renderImageForPlatform(
        imageBytes: imageBytes,
        platform: widget.platform,
        customX: widget.customWidth,
        customY: widget.customHeight,
        fitMode: 'fill',
        backgroundColor: AppColors.background,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _originalAspectRatio = originalAspectRatio;
        _renderedImageBytes = result.bytes;
        _isRenderingImage = false;
      });

      originalImage.dispose();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _originalAspectRatio = null;
        _renderedImageBytes = null;
        _isRenderingImage = false;
      });
    }
  }

  SelectedMedia? _createSelectedMedia(PlatformFile file) {
    final nameParts = file.name.split('.');
    final fallbackExtension = nameParts.length > 1 ? nameParts.last : '';
    final extension = (file.extension ?? fallbackExtension).toLowerCase();
    final isImage =
        extension == 'jpg' || extension == 'jpeg' || extension == 'png';

    print('FILE PICKED');
    print('Picked file name: ${file.name}');
    print('Picked file extension: ${file.extension}');
    print('Has bytes: ${file.bytes != null}');

    if (!isImage || file.bytes == null) {
      return null;
    }

    print('Detected media type: ${MediaType.image}');

    return SelectedMedia(
      type: MediaType.image,
      fileName: file.name,
      bytes: file.bytes,
    );
  }

  String _formatLabelForPlatform() {
    final target = _currentTarget();
    return target.compactLabel;
  }

  String _exportSupportLabel() {
    return 'Preview en export gebruiken hetzelfde canvas.';
  }

  String? _displayFileName() {
    final fileName = _selectedMedia?.fileName;

    if (fileName == null || fileName.isEmpty) {
      return null;
    }

    return fileName;
  }

  Widget _buildPreviewMeta(TextTheme textTheme) {
    final fileName = _displayFileName();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatLabelForPlatform(),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.92),
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (fileName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.84),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              _exportSupportLabel(),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.74),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required String label,
    required Widget child,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.86),
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  String _exportFileName() {
    final target = _currentTarget();
    return target.exportFileName;
  }

  Future<void> _pickImage() async {
    if (_isPickingMedia) {
      return;
    }

    setState(() {
      _isPickingMedia = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      final media = _createSelectedMedia(file);

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Bestand kon niet geladen worden')),
            );
        }
        return;
      }

      if (media == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Bestand kon niet geladen worden')),
            );
        }
        return;
      }

      AnalyticsService.track('image_uploaded');
      _selectedMedia = media;
      print('NAVIGATING TO PREVIEW');
      if (mounted) {
        setState(() {
          _syncImageBytesFromMedia();
        });
      }
      await _prepareRenderedImage();
    } finally {
      if (mounted) {
        setState(() {
          _isPickingMedia = false;
        });
      }
    }
  }

  void _openPaywall() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const PaywallScreen()),
    ).then((_) async {
      await _refreshEntitlements();
    });
  }

  String _planLabel() {
    return _entitlements.displayPlanLabel;
  }

  String _exportBlockedMessage(String? reason) {
    switch (reason) {
      case 'no_credits':
        return 'No credits remaining';
      case 'unknown_user':
        return 'Backend user not found';
      case 'missing_or_invalid_anonymous_user_id':
        return 'Backend not reachable';
      default:
        return 'Export not allowed';
    }
  }

  void _showFloatingSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<bool> _downloadCurrentImage() async {
    final selectedMedia = _selectedMedia;
    final imageBytes = _renderedImageBytes;

    if (selectedMedia == null) {
      _showFloatingSnackBar('Geen bestand geselecteerd');
      return false;
    }

    if (selectedMedia.type == MediaType.video) {
      if (selectedMedia.bytes == null) {
        _showFloatingSnackBar('Video kon niet geëxporteerd worden');
        return false;
      }

      _showFloatingSnackBar('Video kon niet geëxporteerd worden');
      return false;
    }

    if (selectedMedia.bytes == null || imageBytes == null) {
      _showFloatingSnackBar('Afbeelding kon niet geladen worden');
      return false;
    }

    try {
      debugPrint('Export started');
      debugPrint('Export bytes length: ${imageBytes.length}');

      await downloadExport(imageBytes, _exportFileName());

      _showFloatingSnackBar('Download gestart');

      await Future<void>.delayed(const Duration(milliseconds: 900));

      _showFloatingSnackBar('Export voltooid');

      return true;
    } catch (_) {
      _showFloatingSnackBar('Export mislukt');

      return false;
    }
  }

  Future<void> _handleExport() async {
    AnalyticsService.track('export_clicked', {'platform': widget.platform});

    if (_isExporting) {
      return;
    }

    if (_selectedMedia == null) {
      _showFloatingSnackBar('Geen bestand geselecteerd');
      return;
    }

    if (_selectedMedia?.type != MediaType.image ||
        _renderedImageBytes == null) {
      _showFloatingSnackBar('Afbeelding kon niet geladen worden');
      return;
    }

    if (mounted) {
      setState(() {
        _isExporting = true;
      });
    }

    try {
      final consumeResult = await _entitlements.consumeExport();

      if (!consumeResult.allowed) {
        _showFloatingSnackBar(_exportBlockedMessage(consumeResult.reason));

        if (consumeResult.reason == 'no_credits') {
          _openPaywall();
        }

        return;
      }

      if (consumeResult.isPro) {
        _showFloatingSnackBar('Pro active');
      }

      await _downloadCurrentImage();
    } catch (_) {
      _showFloatingSnackBar('Backend not reachable');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _currentTarget();
    final aspectRatio = target.aspectRatio;
    final imageBytes = _renderedImageBytes;
    final originalBytes = _imageBytes;
    final selectedMedia = _selectedMedia;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actionGroupSpacing = constraints.maxHeight >= 860
                ? AppSpacing.xxxl
                : constraints.maxHeight >= 720
                ? AppSpacing.xxl
                : AppSpacing.lg;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Preview',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Controleer rustig hoe je content straks in het gekozen formaat staat.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.88,
                          ),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Text(
                          'Zo komt je post eruit te zien',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14151A),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.26),
                                blurRadius: 28,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.06),
                                blurRadius: 34,
                                spreadRadius: 1,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildComparisonCard(
                                      label: 'Before',
                                      textTheme: textTheme,
                                      child: AspectRatio(
                                        aspectRatio: _originalAspectRatio ?? 1,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Container(
                                            color: AppColors.background,
                                            child: originalBytes != null
                                                ? Image.memory(
                                                    originalBytes,
                                                    fit: BoxFit.contain,
                                                    gaplessPlayback: true,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                  )
                                                : _PreviewPlaceholder(
                                                    fileName:
                                                        selectedMedia?.fileName,
                                                    textTheme: textTheme,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _buildComparisonCard(
                                      label: 'After',
                                      textTheme: textTheme,
                                      child: AspectRatio(
                                        aspectRatio: aspectRatio,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B0C0F),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.08),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 28,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                              AppSpacing.sm,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  border: Border.all(
                                                    color: AppColors
                                                        .textSecondary
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                  ),
                                                ),
                                                child: _isRenderingImage
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                      )
                                                    : imageBytes != null
                                                    ? Image.memory(
                                                        imageBytes,
                                                        fit: BoxFit.fill,
                                                        gaplessPlayback: true,
                                                        filterQuality:
                                                            FilterQuality.high,
                                                      )
                                                    : _PreviewPlaceholder(
                                                        fileName: selectedMedia
                                                            ?.fileName,
                                                        textTheme: textTheme,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildPreviewMeta(textTheme),
                      const SizedBox(height: AppSpacing.xxl),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.background.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Huidige status',
                                style: textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.82,
                                  ),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _planLabel(),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(
                                    alpha: 0.42,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _entitlements.isPro
                                      ? 'Unlimited'
                                      : 'Credits: ${_entitlements.credits}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.92,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextButton(
                        onPressed: _openPaywall,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('Plan wijzigen'),
                      ),
                      SizedBox(height: actionGroupSpacing + AppSpacing.lg),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedMedia != null) ...[
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _isPickingMedia || _isExporting
                                          ? null
                                          : _pickImage,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: BorderSide(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.35),
                                        ),
                                        backgroundColor: AppColors.surface
                                            .withValues(alpha: 0.35),
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _isPickingMedia
                                            ? 'Bezig met kiezen...'
                                            : 'Bestand vervangen',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isExporting
                                        ? null
                                        : _handleExport,
                                    child: _isExporting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.textPrimary,
                                            ),
                                          )
                                        : const Text('Exporteer'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: actionGroupSpacing),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.fileName, required this.textTheme});

  final String? fileName;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Preview komt hier',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.88),
          ),
        ),
      ),
    );
  }
}
