import 'dart:typed_data';

enum MediaType { image, video }

class SelectedMedia {
  const SelectedMedia({required this.type, this.fileName, this.bytes});

  final MediaType type;
  final String? fileName;
  final Uint8List? bytes;
}
