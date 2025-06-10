import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  static const String _key = 'rufko_backup_key';

  List<int> _xorEncrypt(String input) {
    final keyCodes = _key.codeUnits;
    final inCodes = input.codeUnits;
    return List<int>.generate(
      inCodes.length,
      (i) => inCodes[i] ^ keyCodes[i % keyCodes.length],
    );
  }

  Future<String> saveEncryptedBackup(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'rufko_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.enc';
    final file = File('${directory.path}/$fileName');
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final encryptedBytes = _xorEncrypt(jsonString);
    await file.writeAsBytes(encryptedBytes);
    return file.path;
  }
}
