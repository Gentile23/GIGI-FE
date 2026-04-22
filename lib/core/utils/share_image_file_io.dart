import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<XFile> createShareImageFile(
  Uint8List bytes, {
  required String fileName,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  return XFile(file.path, mimeType: 'image/png', name: fileName);
}
