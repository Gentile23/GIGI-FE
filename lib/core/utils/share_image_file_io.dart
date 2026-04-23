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
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final dotIndex = safeName.lastIndexOf('.');
  final baseName = dotIndex > 0 ? safeName.substring(0, dotIndex) : safeName;
  final extension = dotIndex > 0 ? safeName.substring(dotIndex) : '.png';
  final uniqueName =
      '${baseName}_${DateTime.now().millisecondsSinceEpoch}$extension';
  final filePath = '${directory.path}/$uniqueName';
  final file = File(filePath);

  debugPrint(
    'createShareImageFile: writing ${bytes.length} bytes to $filePath',
  );
  await file.writeAsBytes(bytes, flush: true);

  final exists = await file.exists();
  final size = exists ? await file.length() : 0;
  debugPrint(
    'createShareImageFile: file written. Exists: $exists, Size: $size bytes',
  );

  if (!exists || size == 0) {
    throw StateError('Share image file was not created correctly');
  }

  return XFile(file.path, mimeType: 'image/png', name: uniqueName);
}
