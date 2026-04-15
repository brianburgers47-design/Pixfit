import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'video_preview_source.dart';

Future<VideoPreviewSource?> createVideoPreviewSource({
  required Uint8List bytes,
  required String fileName,
}) async {
  final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final tempDirectory = await Directory.systemTemp.createTemp('pixfit_video_');
  final file = File('${tempDirectory.path}/$sanitizedFileName');

  await file.writeAsBytes(bytes, flush: true);

  return VideoPreviewSource(
    uri: file.uri,
    dispose: () {
      unawaited(() async {
        try {
          await file.delete();
        } catch (_) {}
      }());
      unawaited(() async {
        try {
          await tempDirectory.delete(recursive: true);
        } catch (_) {}
      }());
    },
  );
}
