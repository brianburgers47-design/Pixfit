// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'dart:html' as html;

import 'video_preview_source.dart';

Future<VideoPreviewSource?> createVideoPreviewSource({
  required Uint8List bytes,
  required String fileName,
}) async {
  final extension = fileName.split('.').length > 1
      ? fileName.split('.').last.toLowerCase()
      : '';
  final mimeType = switch (extension) {
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    _ => 'video/mp4',
  };

  final blob = html.Blob([bytes], mimeType);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);

  return VideoPreviewSource(
    uri: Uri.parse(objectUrl),
    dispose: () {
      html.Url.revokeObjectUrl(objectUrl);
    },
  );
}
