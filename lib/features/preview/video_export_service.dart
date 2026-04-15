import 'dart:typed_data';

import '../../shared/models/selected_media.dart';
import 'export_downloader.dart';

class VideoExportRequest {
  const VideoExportRequest({
    required this.videoBytes,
    required this.fileName,
    required this.mediaType,
    required this.chosenPlatform,
    this.customWidth,
    this.customHeight,
  });

  final Uint8List videoBytes;
  final String fileName;
  final MediaType mediaType;
  final String chosenPlatform;
  final int? customWidth;
  final int? customHeight;
}

class VideoExportTarget {
  const VideoExportTarget({
    required this.label,
    required this.ratioWidth,
    required this.ratioHeight,
  });

  final String label;
  final int ratioWidth;
  final int ratioHeight;
}

class VideoExportService {
  const VideoExportService();

  VideoExportTarget targetForPlatform({
    required String chosenPlatform,
    int? customWidth,
    int? customHeight,
  }) {
    switch (chosenPlatform) {
      case 'instagram_post':
        return const VideoExportTarget(
          label: 'instagram_post',
          ratioWidth: 1,
          ratioHeight: 1,
        );
      case 'instagram_story':
        return const VideoExportTarget(
          label: 'instagram_story',
          ratioWidth: 9,
          ratioHeight: 16,
        );
      case 'tiktok':
        return const VideoExportTarget(
          label: 'tiktok',
          ratioWidth: 9,
          ratioHeight: 16,
        );
      case 'youtube':
        return const VideoExportTarget(
          label: 'youtube',
          ratioWidth: 16,
          ratioHeight: 9,
        );
      case 'custom':
        return VideoExportTarget(
          label: 'custom',
          ratioWidth: customWidth ?? 1,
          ratioHeight: customHeight ?? 1,
        );
      default:
        return const VideoExportTarget(
          label: 'instagram_post',
          ratioWidth: 1,
          ratioHeight: 1,
        );
    }
  }

  Future<void> exportVideo(VideoExportRequest request) async {
    final target = targetForPlatform(
      chosenPlatform: request.chosenPlatform,
      customWidth: request.customWidth,
      customHeight: request.customHeight,
    );

    // TODO: Replace pass-through download with real platform-aware processing.
    // TODO: Add web-only video processing via browser APIs or JS interop.
    // TODO: Render video to target ratio with fit/crop/background-fill strategy.
    await downloadExport(
      request.videoBytes,
      _buildExportFileName(target.label, request.fileName),
      mimeType: _videoMimeType(request.fileName),
    );
  }

  String _buildExportFileName(String platformLabel, String originalFileName) {
    final extension = _safeExtension(originalFileName);

    switch (platformLabel) {
      case 'instagram_post':
        return 'pixfit_instagram_post_video.$extension';
      case 'instagram_story':
        return 'pixfit_instagram_story_video.$extension';
      case 'tiktok':
        return 'pixfit_tiktok_video.$extension';
      case 'youtube':
        return 'pixfit_youtube_video.$extension';
      case 'custom':
        return 'pixfit_custom_video.$extension';
      default:
        return 'pixfit_video_export.$extension';
    }
  }

  String _safeExtension(String fileName) {
    final parts = fileName.split('.');
    final extension = parts.length > 1 ? parts.last.toLowerCase() : 'mp4';

    if (extension == 'mp4' || extension == 'mov' || extension == 'webm') {
      return extension;
    }

    return 'mp4';
  }

  String _videoMimeType(String fileName) {
    switch (_safeExtension(fileName)) {
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mp4':
      default:
        return 'video/mp4';
    }
  }
}
