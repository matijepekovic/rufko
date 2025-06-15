import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rufko/core/services/storage/file_service.dart';

void main() {
  test('saveExportedData writes json file', () async {
    final dir = await Directory.systemTemp.createTemp('rufko_test_export');
    final filePath =
        await FileService.instance.saveExportedData({'a': 1}, baseDirectory: dir);
    final file = File(filePath);
    expect(await file.exists(), isTrue);
    final contents = await file.readAsString();
    expect(contents.contains('"a"'), isTrue);
  });

  test('pickAndSaveCompanyLogo copies image to directory', () async {
    final sourceDir = await Directory.systemTemp.createTemp('rufko_source');
    final src = File('${sourceDir.path}/logo.jpg');
    await src.writeAsBytes(List.filled(5, 1));

    final destDir = await Directory.systemTemp.createTemp('rufko_dest');
    final newPath = await FileService.instance.pickAndSaveCompanyLogo(
      image: XFile(src.path),
      baseDirectory: destDir,
    );

    expect(newPath, isNotNull);
    expect(await File(newPath!).exists(), isTrue);
  });
}
