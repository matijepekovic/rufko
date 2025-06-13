// lib/services/simple_pdf_editing_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:path_provider/path_provider.dart';
import '../../../data/models/media/project_media.dart';
import '../../utils/helpers/common_utils.dart';

enum EditingTool {
  none,
  formField,
  text,
}

enum EditActionType {
  formFieldEdit,
  textEdit,
}

class PdfEditAction {
  final String id;
  final EditActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PdfEditAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PdfEditAction.fromMap(Map<String, dynamic> map) {
    return PdfEditAction(
      id: map['id'],
      type: EditActionType.values.firstWhere((e) => e.name == map['type']),
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class PdfEditingState {
  final List<PdfEditAction> history;
  final int currentHistoryIndex;
  final EditingTool currentTool;
  final Map<String, dynamic> formFieldChanges;

  const PdfEditingState({
    this.history = const [],
    this.currentHistoryIndex = -1,
    this.currentTool = EditingTool.none,
    this.formFieldChanges = const {},
  });

  PdfEditingState copyWith({
    List<PdfEditAction>? history,
    int? currentHistoryIndex,
    EditingTool? currentTool,
    Map<String, dynamic>? formFieldChanges,
  }) {
    return PdfEditingState(
      history: history ?? this.history,
      currentHistoryIndex: currentHistoryIndex ?? this.currentHistoryIndex,
      currentTool: currentTool ?? this.currentTool,
      formFieldChanges: formFieldChanges ?? this.formFieldChanges,
    );
  }

  bool get canUndo => currentHistoryIndex >= 0;
  bool get canRedo => currentHistoryIndex < history.length - 1;
  bool get hasUnsavedChanges => formFieldChanges.isNotEmpty;
}

class SimplePdfEditingService {
  static final SimplePdfEditingService _instance = SimplePdfEditingService._internal();
  factory SimplePdfEditingService() => _instance;
  SimplePdfEditingService._internal();

  static SimplePdfEditingService get instance => _instance;

  /// Save edited PDF with form field changes
  Future<String> saveEditedPdf({
    required String originalPdfPath,
    required Map<String, dynamic> formFieldValues,
    required String customerId,
    required String quoteId,
    String? fileName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Starting PDF save with ${formFieldValues.length} form field changes');
      }

      // Read original PDF
      final originalFile = File(originalPdfPath);
      if (!await originalFile.exists()) {
        throw Exception('Original PDF file not found: $originalPdfPath');
      }

      final originalBytes = await originalFile.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: originalBytes);

      // Update form fields
      if (formFieldValues.isNotEmpty) {
        await _updateFormFields(document, formFieldValues);
      }

      // Save the modified PDF
      final List<int> savedBytes = document.saveSync();
      document.dispose();

      // Generate unique filename
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'edited_pdf_$timestamp.pdf';
      final outputFile = File('${directory.path}/$finalFileName');
      await outputFile.writeAsBytes(savedBytes);

      if (kDebugMode) {
        debugPrint('✅ Edited PDF saved: ${outputFile.path}');
        debugPrint('📊 File size: ${(savedBytes.length / 1024).toStringAsFixed(1)} KB');
      }

      return outputFile.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving edited PDF: $e');
      }
      rethrow;
    }
  }

  /// Update form fields in the PDF document
  Future<void> _updateFormFields(
      syncfusion.PdfDocument document,
      Map<String, dynamic> formFieldValues,
      ) async {
    try {
      if (document.form.fields.count == 0) {
        if (kDebugMode) debugPrint('⚠️ No form fields found in PDF');
        return;
      }

      int updatedFields = 0;
      for (int i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final fieldName = field.name;

        if (fieldName != null && formFieldValues.containsKey(fieldName)) {
          final newValue = formFieldValues[fieldName]?.toString() ?? '';

          if (field is syncfusion.PdfTextBoxField) {
            field.text = newValue;
            updatedFields++;
          } else if (field is syncfusion.PdfCheckBoxField) {
            final isChecked = newValue.toLowerCase() == 'true' ||
                newValue == '1' ||
                newValue.toLowerCase() == 'yes' ||
                newValue.toLowerCase() == 'checked';
            field.isChecked = isChecked;
            updatedFields++;
          } else if (field is syncfusion.PdfComboBoxField) {
            field.selectedValue = newValue;
            updatedFields++;
          } else if (field is syncfusion.PdfRadioButtonListField) {
            // Find matching radio button option
            for (int j = 0; j < field.items.count; j++) {
              final item = field.items[j];
              if (item.value == newValue) {
                field.selectedIndex = j;
                updatedFields++;
                break;
              }
            }
          }

          if (kDebugMode) {
            debugPrint('🔧 Updated form field "$fieldName" = "$newValue"');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Updated $updatedFields form fields');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating form fields: $e');
      }
      rethrow;
    }
  }

  /// Create ProjectMedia entry for saved PDF
  Future<ProjectMedia> createProjectMediaEntry({
    required String pdfPath,
    required String customerId,
    required String quoteId,
    String? description,
    List<String>? tags,
  }) async {
    try {
      final file = File(pdfPath);
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      final projectMedia = ProjectMedia(
        customerId: customerId,
        quoteId: quoteId,
        filePath: pdfPath,
        fileName: fileName,
        fileType: 'pdf',
        description: description ?? 'Edited PDF with form field updates',
        tags: tags ?? ['edited', 'form-fields', 'quote'],
        category: 'edited_quotes',
        fileSizeBytes: fileSize,
      );

      if (kDebugMode) {
        debugPrint('📎 Created ProjectMedia entry: $fileName (${projectMedia.formattedFileSize})');
      }

      return projectMedia;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating ProjectMedia entry: $e');
      }
      rethrow;
    }
  }

  /// Extract form field values from PDF
  Future<Map<String, dynamic>> extractFormFieldValues(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);

      final formFieldValues = <String, dynamic>{};

      if (document.form.fields.count > 0) {
        for (int i = 0; i < document.form.fields.count; i++) {
          final field = document.form.fields[i];
          final fieldName = field.name ?? 'field_$i';

          if (field is syncfusion.PdfTextBoxField) {
            formFieldValues[fieldName] = field.text;
          } else if (field is syncfusion.PdfCheckBoxField) {
            formFieldValues[fieldName] = field.isChecked;
          } else if (field is syncfusion.PdfComboBoxField) {
            formFieldValues[fieldName] = field.selectedValue;
          } else if (field is syncfusion.PdfRadioButtonListField) {
            formFieldValues[fieldName] = field.selectedValue;
          }
        }
      }

      document.dispose();

      if (kDebugMode) {
        debugPrint('📋 Extracted ${formFieldValues.length} form field values');
      }

      return formFieldValues;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error extracting form field values: $e');
      }
      return {};
    }
  }

  /// Get list of form fields in PDF
  Future<List<Map<String, dynamic>>> getFormFieldInfo(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);

      final formFields = <Map<String, dynamic>>[];

      if (document.form.fields.count > 0) {
        for (int i = 0; i < document.form.fields.count; i++) {
          final field = document.form.fields[i];
          final fieldName = field.name ?? 'field_$i';

          String fieldType = 'unknown';
          dynamic currentValue;

          if (field is syncfusion.PdfTextBoxField) {
            fieldType = 'text';
            currentValue = field.text;
          } else if (field is syncfusion.PdfCheckBoxField) {
            fieldType = 'checkbox';
            currentValue = field.isChecked;
          } else if (field is syncfusion.PdfComboBoxField) {
            fieldType = 'combo';
            currentValue = field.selectedValue;
          } else if (field is syncfusion.PdfRadioButtonListField) {
            fieldType = 'radio';
            currentValue = field.selectedValue;
          }

          formFields.add({
            'name': fieldName,
            'type': fieldType,
            'currentValue': currentValue,
            'bounds': {
              'x': field.bounds.left,
              'y': field.bounds.top,
              'width': field.bounds.width,
              'height': field.bounds.height,
            },
          });
        }
      }

      document.dispose();

      if (kDebugMode) {
        debugPrint('📋 Found ${formFields.length} form fields');
      }

      return formFields;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting form field info: $e');
      }
      return [];
    }
  }

  /// Validate PDF file for editing
  Future<bool> canEditPdf(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);

      // Check if PDF is valid and has form fields
      final isValid = document.pages.count > 0;
      final hasFormFields = document.form.fields.count > 0;

      document.dispose();

      if (kDebugMode) {
        debugPrint('📄 PDF validation - Valid: $isValid, Has form fields: $hasFormFields');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PDF validation failed: $e');
      }
      return false;
    }
  }

  /// Get PDF information
  Future<Map<String, dynamic>> getPdfInfo(String pdfPath) async {
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);

      final info = {
        'pageCount': document.pages.count,
        'hasFormFields': document.form.fields.count > 0,
        'formFieldCount': document.form.fields.count,
        'fileSize': bytes.length,
        'fileSizeFormatted': formatFileSize(bytes.length),
        'canEdit': document.form.fields.count > 0,
      };

      // Get first page dimensions
      if (document.pages.count > 0) {
        final firstPage = document.pages[0];
        info['pageWidth'] = firstPage.size.width;
        info['pageHeight'] = firstPage.size.height;
      }

      document.dispose();
      return info;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting PDF info: $e');
      }
      return {};
    }
  }

}