import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

Future<XFile> createShareImageFile(
  Uint8List bytes, {
  required String fileName,
}) async {
  return XFile.fromData(bytes, mimeType: 'image/png', name: fileName);
}
