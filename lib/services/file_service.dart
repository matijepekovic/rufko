import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  FileService._internal();
  static final FileService instance = FileService._internal();

  /// Pick an image from gallery and store it inside the application
  /// documents directory under `company_logos`. Returns the new
  /// file path or `null` if no image was selected.
  Future<String?> pickAndSaveCompanyLogo({
    XFile? image,
    Directory? baseDirectory,
  }) async {
    final picker = ImagePicker();
    final XFile? selectedImage =
        image ?? await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);

    if (selectedImage == null) return null;

    final directory = baseDirectory ?? await getApplicationDocumentsDirectory();
    final logoDir = Directory('${directory.path}/company_logos');
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }
    final extension = selectedImage.path.split('.').last;
    final fileName =
        'company_logo_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final newPath = '${logoDir.path}/$fileName';
    await File(selectedImage.path).copy(newPath);
    return newPath;
  }

  /// Save exported [data] to a json file in the application documents
  /// directory. Returns the written file path.
  Future<String> saveExportedData(
    Map<String, dynamic> data, {
    Directory? baseDirectory,
  }) async {
    final directory = baseDirectory ?? await getApplicationDocumentsDirectory();
    final fileName =
        'rufko_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file.path;
  }

  /// Pick a backup file (json) and return its parsed contents as a map.
  Future<Map<String, dynamic>> pickAndReadBackupFile({String? filePath}) async {
    String? path = filePath;
    if (path == null) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        throw Exception('No file selected');
      }
      path = result.files.single.path!;
    }
    final file = File(path);
    final jsonString = await file.readAsString();
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
