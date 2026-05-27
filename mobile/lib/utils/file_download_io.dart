import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveTextDownload({
  required String suggestedName,
  required String mimeType,
  required String content,
}) async {
  final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
  final String? outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: suggestedName,
    bytes: bytes,
  );
  if (outputPath == null || outputPath.isEmpty) {
    return false;
  }

  // On Android and iOS, the plugin writes the provided bytes itself.
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }

  await File(outputPath).writeAsBytes(bytes, flush: true);
  return true;
}
