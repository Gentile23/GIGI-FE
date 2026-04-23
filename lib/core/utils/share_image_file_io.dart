import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<XFile> createShareImageFile(
  Uint8List bytes, {
  required String fileName,
}) async {
  debugPrint('createShareImageFile: starting for $fileName');
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  
  debugPrint('createShareImageFile: writing ${bytes.length} bytes to $filePath');
  await file.writeAsBytes(bytes, flush: true);
  
  final exists = await file.exists();
  final size = exists ? await file.length() : 0;
  debugPrint('createShareImageFile: file written. Exists: $exists, Size: $size bytes');

  return XFile(file.path, mimeType: 'image/png', name: fileName);
}
