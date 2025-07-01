// lib/models/inspection_document.dart (HIVE ANNOTATIONS REMOVED)

import 'package:uuid/uuid.dart';

class InspectionDocument {
  late String id;
  String customerId; // Links to Customer
  String type; // 'note' or 'pdf'
  String title; // Display name
  String? content; // For notes - the actual text content
  String? filePath; // For PDFs - path to the file
  int sortOrder; // For ordering documents
  DateTime createdAt;
  DateTime updatedAt;
  String? quoteId; // Optional link to specific quote
  int? fileSizeBytes; // For PDFs
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
    }
  }

  void updateTitle(String newTitle) {
    title = newTitle;
    updatedAt = DateTime.now();
  }

  void updateSortOrder(int newOrder) {
    sortOrder = newOrder;
    updatedAt = DateTime.now();
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
      updatedAt = DateTime.now();
    }
  }

  void removeTag(String tag) {
    if (tags.remove(tag)) {
      updatedAt = DateTime.now();
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