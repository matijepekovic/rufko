import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'project_media.g.dart';

@HiveType(typeId: 5)
class ProjectMedia extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String? quoteId;

  @HiveField(3)
  String filePath;

  @HiveField(4)
  String fileName;

  @HiveField(5)
  String fileType; // image, pdf, document

  @HiveField(6)
  String? description;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  String category; // before, after, damage, materials, etc.

  @HiveField(9)
  int fileSizeBytes;

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
    this.fileSizeBytes = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  // Add tag
  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
      save();
    }
  }

  // Remove tag
  void removeTag(String tag) {
    tags.remove(tag);
    updatedAt = DateTime.now();
    save();
  }

  // Update description
  void updateDescription(String newDescription) {
    description = newDescription;
    updatedAt = DateTime.now();
    save();
  }

  // Update category
  void updateCategory(String newCategory) {
    category = newCategory;
    updatedAt = DateTime.now();
    save();
  }

  // Check if file is image
  bool get isImage {
    return fileType.toLowerCase() == 'image' ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.gif');
  }

  // Check if file is PDF
  bool get isPdf {
    return fileType.toLowerCase() == 'pdf' ||
        fileName.toLowerCase().endsWith('.pdf');
  }

  // Get file size in human readable format
  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (fileSizeBytes < 1024 * 1024 * 1024) return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Convert to Map for JSON serialization
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

  // Create from Map
  factory ProjectMedia.fromMap(Map<String, dynamic> map) {
    return ProjectMedia(
      id: map['id'],
      customerId: map['customerId'],
      quoteId: map['quoteId'],
      filePath: map['filePath'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      description: map['description'],
      tags: List<String>.from(map['tags'] ?? []),
      category: map['category'] ?? 'general',
      fileSizeBytes: map['fileSizeBytes'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'ProjectMedia(id: $id, fileName: $fileName, type: $fileType, category: $category)';
  }
}