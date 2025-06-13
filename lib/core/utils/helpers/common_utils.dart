import 'package:flutter/material.dart';

import 'package:intl/intl.dart';


String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatCategoryName(String key) {
  return key
      .split('_')
      .map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

IconData getFileIcon(String fileType) {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return Icons.image;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    default:
      return Icons.insert_drive_file;
  }
}

Color getFileColor(String fileType) {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return Colors.red;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return Colors.blue;
    case 'doc':
    case 'docx':
      return Colors.indigo;
    case 'xls':
    case 'xlsx':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

String getMimeType(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}


String formatCommunicationDate(String timestamp) {
  try {
    final date = DateTime.parse(timestamp);
    return DateFormat('MMM dd, yyyy at h:mm a').format(date);
  } catch (e) {
    return timestamp;
  }
}

String formatPhotoCategoryName(String category) {
  switch (category) {
    case 'before_photos':
      return 'Before Photos';
    case 'after_photos':
      return 'After Photos';
    case 'inspection_photos':
      return 'Inspection Photos';
    case 'progress_photos':
      return 'Progress Photos';
    case 'damage_report':
      return 'Damage Photos';
    case 'other_photos':
      return 'Other Photos';
    default:
      return formatCategoryName(category);
  }
}

