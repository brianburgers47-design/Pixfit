import 'dart:typed_data';

import 'video_preview_source_stub.dart'
    if (dart.library.io) 'video_preview_source_io.dart'
    if (dart.library.html) 'video_preview_source_web.dart' as impl;

class VideoPreviewSource {
  const VideoPreviewSource({required this.uri, required this.dispose});

  final Uri uri;
  final void Function() dispose;
}

Future<VideoPreviewSource?> createVideoPreviewSource({
  required Uint8List bytes,
  required String fileName,
}) {
  return impl.createVideoPreviewSource(bytes: bytes, fileName: fileName);
}
