// lib/models/project_media.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part '../../generated/project_media.g.dart'; // Will be generated

@HiveType(typeId: 5) // Unique Type ID
class ProjectMedia extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId; // Link to a customer

  @HiveField(2)
  String? quoteId; // Optional: link to a specific quote (SimplifiedMultiLevelQuote ID)

  @HiveField(3)
  String filePath; // Path to the media file on the device

  @HiveField(4)
  String fileName;

  @HiveField(5)
  String fileType; // e.g., "image", "pdf", "document" or MIME type

  @HiveField(6)
  String? description;

  @HiveField(7)
  List<String> tags; // For categorizing or searching

  @HiveField(8)
  String category; // e.g., "before_photos", "after_photos", "damage_report", "contract"

  @HiveField(9)
  int? fileSizeBytes; // Optional: size of the file

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  ProjectMedia({
    String? id,
    required this.customerId,
    this.quoteId,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    this.description,
    List<String>? tags,
    this.category = 'general',
    this.fileSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
      if (isInBox) { save(); }
    }
  }

  void removeTag(String tag) {
    if (tags.remove(tag)) {
      updatedAt = DateTime.now();
      if (isInBox) { save(); }
    }
  }

  void updateDetails({
    String? description,
    String? category,
    List<String>? tags,
  }) {
    if (description != null) this.description = description;
    if (category != null) this.category = category;
    if (tags != null) this.tags = tags;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  bool get isImage {
    final lowerFileType = fileType.toLowerCase();
    final lowerFileName = fileName.toLowerCase();
    return lowerFileType == 'image' ||
        lowerFileName.endsWith('.jpg') ||
        lowerFileName.endsWith('.jpeg') ||
        lowerFileName.endsWith('.png') ||
        lowerFileName.endsWith('.gif') ||
        lowerFileName.endsWith('.webp') ||
        lowerFileName.endsWith('.bmp');
  }

  bool get isPdf {
    return fileType.toLowerCase() == 'pdf' || fileName.toLowerCase().endsWith('.pdf');
  }

  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes! < 0) return 'N/A';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    if (fileSizeBytes! < 1024 * 1024 * 1024) return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSizeBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'quoteId': quoteId,
      'filePath': filePath,
      'fileName': fileName,
      'fileType': fileType,
      'description': description,
      'tags': tags,
      'category': category,
      'fileSizeBytes': fileSizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectMedia.fromMap(Map<String, dynamic> map) {
    return ProjectMedia(
      id: map['id'],
      customerId: map['customerId'] ?? '',
      quoteId: map['quoteId'],
      filePath: map['filePath'] ?? '',
      fileName: map['fileName'] ?? 'unknown_file',
      fileType: map['fileType'] ?? 'unknown',
      description: map['description'],
      tags: List<String>.from(map['tags'] ?? []),
      category: map['category'] ?? 'general',
      fileSizeBytes: map['fileSizeBytes']?.toInt(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ProjectMedia(id: $id, fileName: $fileName, category: $category)';
  }
}