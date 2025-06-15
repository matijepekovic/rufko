// lib/models/inspection_document.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part '../../generated/inspection_document.g.dart';

@HiveType(typeId: 15) // New type ID - make sure this doesn't conflict with existing ones
class InspectionDocument extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId; // Links to Customer

  @HiveField(2)
  String type; // 'note' or 'pdf'

  @HiveField(3)
  String title; // Display name

  @HiveField(4)
  String? content; // For notes - the actual text content

  @HiveField(5)
  String? filePath; // For PDFs - path to the file

  @HiveField(6)
  int sortOrder; // For ordering documents

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  String? quoteId; // Optional link to specific quote

  @HiveField(10)
  int? fileSizeBytes; // For PDFs

  @HiveField(11)
  List<String> tags; // For categorizing documents

  InspectionDocument({
    String? id,
    required this.customerId,
    required this.type,
    required this.title,
    this.content,
    this.filePath,
    this.sortOrder = 0,
    this.quoteId,
    this.fileSizeBytes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  // Getters for convenience
  bool get isNote => type == 'note';
  bool get isPdf => type == 'pdf';

  String get displayTitle => title.isNotEmpty ? title : (isNote ? 'Inspection Note' : 'Inspection PDF');

  String get formattedFileSize {
    if (fileSizeBytes == null) return '';
    final bytes = fileSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Update methods
  void updateContent(String newContent) {
    if (isNote) {
      content = newContent;
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateTitle(String newTitle) {
    title = newTitle;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void updateSortOrder(int newOrder) {
    sortOrder = newOrder;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void removeTag(String tag) {
    if (tags.remove(tag)) {
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type,
      'title': title,
      'content': content,
      'filePath': filePath,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'quoteId': quoteId,
      'fileSizeBytes': fileSizeBytes,
      'tags': tags,
    };
  }

  factory InspectionDocument.fromMap(Map<String, dynamic> map) {
    return InspectionDocument(
      id: map['id'],
      customerId: map['customerId'] ?? '',
      type: map['type'] ?? 'note',
      title: map['title'] ?? '',
      content: map['content'],
      filePath: map['filePath'],
      sortOrder: map['sortOrder']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      quoteId: map['quoteId'],
      fileSizeBytes: map['fileSizeBytes']?.toInt(),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
    );
  }

  @override
  String toString() {
    return 'InspectionDocument(id: $id, type: $type, title: $title, customerId: $customerId)';
  }
}

// Helper class for creating inspection documents
class InspectionDocumentHelper {
  static InspectionDocument createNote({
    required String customerId,
    required String title,
    required String content,
    String? quoteId,
    List<String>? tags,
  }) {
    return InspectionDocument(
      customerId: customerId,
      type: 'note',
      title: title,
      content: content,
      quoteId: quoteId,
      tags: tags ?? ['inspection', 'note'],
    );
  }

  static InspectionDocument createPdf({
    required String customerId,
    required String title,
    required String filePath,
    required int fileSizeBytes,
    String? quoteId,
    List<String>? tags,
  }) {
    return InspectionDocument(
      customerId: customerId,
      type: 'pdf',
      title: title,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      quoteId: quoteId,
      tags: tags ?? ['inspection', 'pdf'],
    );
  }
}