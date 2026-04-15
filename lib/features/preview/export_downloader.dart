import 'dart:typed_data';

import 'export_downloader_stub.dart'
    if (dart.library.html) 'export_downloader_web.dart'
    as downloader;

Future<void> downloadExport(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/octet-stream',
}) {
  return downloader.downloadExport(bytes, fileName, mimeType: mimeType);
}
