import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'share_image_file_web.dart'
    if (dart.library.io) 'share_image_file_io.dart'
    as impl;

Future<XFile> createShareImageFile(
  Uint8List bytes, {
  required String fileName,
}) {
  return impl.createShareImageFile(bytes, fileName: fileName);
}
