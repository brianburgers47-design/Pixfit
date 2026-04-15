// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImageRenderTarget {
  const ImageRenderTarget({
    required this.platform,
    required this.displayName,
    required this.ratioText,
    required this.width,
    required this.height,
  });

  final String platform;
  final String displayName;
  final String ratioText;
  final int width;
  final int height;

  double get aspectRatio => width / height;

  String get compactLabel => '$displayName · $ratioText';

  String get exportFileName {
    switch (platform) {
      case 'instagram_post':
        return 'pixfit_instagram_post.png';
      case 'instagram_story':
        return 'pixfit_instagram_story.png';
      case 'tiktok':
        return 'pixfit_tiktok.png';
      case 'youtube':
        return 'pixfit_youtube.png';
      case 'custom':
        return 'pixfit_custom.png';
      default:
        return 'pixfit_export.png';
    }
  }
}

class ImageRenderLayout {
  const ImageRenderLayout({
    required this.scale,
    required this.newWidth,
    required this.newHeight,
    required this.offsetX,
    required this.offsetY,
  });

  final double scale;
  final double newWidth;
  final double newHeight;
  final double offsetX;
  final double offsetY;
}

class ImageRenderResult {
  const ImageRenderResult({
    required this.bytes,
    required this.target,
    required this.layout,
  });

  final Uint8List bytes;
  final ImageRenderTarget target;
  final ImageRenderLayout layout;
}

class ImageRenderService {
  const ImageRenderService();

  ImageRenderTarget getTargetForPlatform({
    required String platform,
    int? customX,
    int? customY,
  }) {
    switch (platform) {
      case 'instagram_post':
        return const ImageRenderTarget(
          platform: 'instagram_post',
          displayName: 'Instagram Post',
          ratioText: '1:1',
          width: 1080,
          height: 1080,
        );
      case 'instagram_story':
        return const ImageRenderTarget(
          platform: 'instagram_story',
          displayName: 'Instagram Story',
          ratioText: '9:16',
          width: 1080,
          height: 1920,
        );
      case 'tiktok':
        return const ImageRenderTarget(
          platform: 'tiktok',
          displayName: 'TikTok',
          ratioText: '9:16',
          width: 1080,
          height: 1920,
        );
      case 'youtube':
        return const ImageRenderTarget(
          platform: 'youtube',
          displayName: 'YouTube',
          ratioText: '16:9',
          width: 1920,
          height: 1080,
        );
      case 'custom':
        return _customTarget(customX: customX, customY: customY);
      default:
        return const ImageRenderTarget(
          platform: 'instagram_post',
          displayName: 'Instagram Post',
          ratioText: '1:1',
          width: 1080,
          height: 1080,
        );
    }
  }

  Size getTargetCanvasSize({
    required String platform,
    int? customX,
    int? customY,
  }) {
    final target = getTargetForPlatform(
      platform: platform,
      customX: customX,
      customY: customY,
    );
    return Size(target.width.toDouble(), target.height.toDouble());
  }

  Future<ImageRenderResult> renderImageForPlatform({
    required Uint8List imageBytes,
    required String platform,
    int? customX,
    int? customY,
    String fitMode = 'fill',
    Color backgroundColor = const Color(0xFF000000),
  }) async {
    final target = getTargetForPlatform(
      platform: platform,
      customX: customX,
      customY: customY,
    );
    final targetSize = getTargetCanvasSize(
      platform: platform,
      customX: customX,
      customY: customY,
    );

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;

    final sourceWidth = sourceImage.width.toDouble();
    final sourceHeight = sourceImage.height.toDouble();
    final targetWidth = targetSize.width;
    final targetHeight = targetSize.height;
    final layout = _calculateLayout(
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      fitMode: fitMode,
    );

    print('Platform: $platform');
    print('Canvas: ${target.width} x ${target.height}');
    print('Fit mode: $fitMode');
    print('Scale: ${layout.scale}');
    print('OffsetX: ${layout.offsetX} OffsetY: ${layout.offsetY}');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(Offset.zero & targetSize, Paint()..color = backgroundColor);

    canvas.drawImageRect(
      sourceImage,
      Rect.fromLTWH(0, 0, sourceWidth, sourceHeight),
      Rect.fromLTWH(
        layout.offsetX,
        layout.offsetY,
        layout.newWidth,
        layout.newHeight,
      ),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(target.width, target.height);
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    sourceImage.dispose();
    renderedImage.dispose();

    if (byteData == null) {
      throw Exception('Afbeelding kon niet gerenderd worden');
    }

    return ImageRenderResult(
      bytes: byteData.buffer.asUint8List(),
      target: target,
      layout: layout,
    );
  }

  ImageRenderLayout _calculateLayout({
    required double sourceWidth,
    required double sourceHeight,
    required double targetWidth,
    required double targetHeight,
    required String fitMode,
  }) {
    final fit = fitMode.toLowerCase();
    final scale = fit == 'fit'
        ? math.min(targetWidth / sourceWidth, targetHeight / sourceHeight)
        : math.max(targetWidth / sourceWidth, targetHeight / sourceHeight);

    final newWidth = sourceWidth * scale;
    final newHeight = sourceHeight * scale;
    final offsetX = (targetWidth - newWidth) / 2;
    final offsetY = (targetHeight - newHeight) / 2;

    return ImageRenderLayout(
      scale: scale,
      newWidth: newWidth,
      newHeight: newHeight,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }

  ImageRenderTarget _customTarget({int? customX, int? customY}) {
    final width = math.max(1, customX ?? 1);
    final height = math.max(1, customY ?? 1);
    const highResBase = 1920;

    if (width >= height) {
      return ImageRenderTarget(
        platform: 'custom',
        displayName: 'Vrij formaat',
        ratioText: '$width:$height',
        width: highResBase,
        height: math.max(1, (highResBase * height / width).round()),
      );
    }

    return ImageRenderTarget(
      platform: 'custom',
      displayName: 'Vrij formaat',
      ratioText: '$width:$height',
      width: math.max(1, (highResBase * width / height).round()),
      height: highResBase,
    );
  }
}
