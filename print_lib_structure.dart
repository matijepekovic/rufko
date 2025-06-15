import 'dart:io';

void printDir(Directory dir, [String prefix = '']) {
  final entries = dir.listSync();
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final isLast = i == entries.length - 1;
    final newPrefix = prefix + (isLast ? '└── ' : '├── ');
    // ignore: avoid_print
    print('$newPrefix${e.uri.pathSegments.last}');
    if (e is Directory) {
      printDir(e, prefix + (isLast ? '    ' : '│   '));
    }
  }
}

void main() => printDir(Directory('lib'));