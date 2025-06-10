import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  final Key _key = Key.fromUtf8('rufko_secure_backup_key_123456');
  final IV _iv = IV.fromLength(16);

  Future<String> saveEncryptedBackup(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'rufko_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.enc';
    final file = File('${directory.path}/$fileName');
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final encrypter = Encrypter(AES(_key));
    final encrypted = encrypter.encrypt(jsonString, iv: _iv);
    await file.writeAsBytes(encrypted.bytes);
    return file.path;
  }
}
