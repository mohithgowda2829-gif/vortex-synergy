import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveTextDownload({
  required String suggestedName,
  required String mimeType,
  required String content,
}) async {
  final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
  if (Platform.isAndroid || Platform.isIOS) {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$suggestedName');
    await file.writeAsBytes(bytes, flush: true);
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
        text: 'Donor certificate export',
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  final String? outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: suggestedName,
    bytes: bytes,
  );
  if (outputPath == null || outputPath.isEmpty) {
    return false;
  }

  await File(outputPath).writeAsBytes(bytes, flush: true);
  return true;
}
