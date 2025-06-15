import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/settings/custom_app_data.dart';
import '../../../../data/models/media/inspection_document.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for managing inspection tab state and operations
/// Extracted from InspectionTab to separate business logic from UI
class InspectionTabController extends ChangeNotifier {
  final BuildContext context;
  final Customer customer;

  // State variables
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _fieldValues = {};

  InspectionTabController({
    required this.context,
    required this.customer,
  }) {
    _initializeFieldValues();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get fieldValues => _fieldValues;

  // Setters with notification
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Initialize field values from customer's existing data
  void _initializeFieldValues() {
    final appState = context.read<AppStateProvider>();
    final allCustomFields = appState.customAppDataFields;
    final inspectionFields = allCustomFields
        .where((field) => field.category == 'inspection')
        .toList();

    for (final field in inspectionFields) {
      final existingValue = customer.getInspectionValue(field.fieldName);
      _fieldValues[field.fieldName] = existingValue;
    }

    debugPrint('🔍 Initialized ${_fieldValues.length} inspection field values');
  }

  /// Get inspection fields sorted by sort order
  List<CustomAppDataField> getInspectionFields() {
    final appState = context.read<AppStateProvider>();
    final allCustomFields = appState.customAppDataFields;
    return allCustomFields
        .where((field) => field.category == 'inspection')
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get inspection documents for current customer
  List<InspectionDocument> getInspectionDocuments() {
    final appState = context.read<AppStateProvider>();
    return appState.getInspectionDocumentsForCustomer(customer.id);
  }

  /// Update field value and auto-save
  Future<void> updateFieldValue(String fieldName, dynamic value) async {
    _fieldValues[fieldName] = value;
    notifyListeners();

    // Auto-save using Customer's built-in method (same as original implementation)
    try {
      customer.setInspectionValue(fieldName, value);
      final appState = context.read<AppStateProvider>();
      await appState.updateCustomer(customer);
      debugPrint('💾 Auto-saved field: $fieldName = $value');
    } catch (e) {
      _error = 'Failed to save field: $e';
      notifyListeners();
      debugPrint('❌ Auto-save failed: $e');
    }
  }

  /// Select date for date field
  Future<void> selectDate(String fieldName) async {
    final currentValue = customer.getInspectionValue(fieldName);
    DateTime initialDate = DateTime.now();

    if (currentValue != null && currentValue.toString().isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentValue.toString());
      } catch (e) {
        // Use current date if parsing fails
      }
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      await updateFieldValue(fieldName, selectedDate.toIso8601String().split('T')[0]);
    }
  }

  /// Reorder inspection fields
  Future<void> reorderInspectionFields(int oldIndex, int newIndex, List<CustomAppDataField> fields) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = fields.removeAt(oldIndex);
    fields.insert(newIndex, item);

    // Update sort orders
    try {
      for (int i = 0; i < fields.length; i++) {
        fields[i].updateField(sortOrder: i);
      }
      notifyListeners();
      debugPrint('🔄 Reordered inspection fields');
    } catch (e) {
      _error = 'Failed to reorder fields: $e';
      notifyListeners();
      debugPrint('❌ Field reorder failed: $e');
    }
  }

  /// Add inspection note
  Future<void> addInspectionNote(String content) async {
    if (content.trim().isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final appState = context.read<AppStateProvider>();
      
      final inspectionNote = InspectionDocument(
        customerId: customer.id,
        type: 'note',
        title: 'Inspection Note',
        content: content.trim(),
        sortOrder: 0,
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await appState.addInspectionDocument(inspectionNote);
      _isLoading = false;
      notifyListeners();
      
      debugPrint('📝 Added inspection note');
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to add note: $e';
      notifyListeners();
      debugPrint('❌ Add note failed: $e');
    }
  }

  /// Update existing inspection note
  Future<void> updateInspectionNote(String documentId, String content) async {
    if (content.trim().isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final appState = context.read<AppStateProvider>();
      final existingDoc = appState.getInspectionDocumentsForCustomer(customer.id)
          .firstWhere((doc) => doc.id == documentId);

      final updatedDoc = InspectionDocument(
        id: existingDoc.id,
        customerId: existingDoc.customerId,
        type: existingDoc.type,
        title: existingDoc.title,
        content: content.trim(),
        filePath: existingDoc.filePath,
        sortOrder: existingDoc.sortOrder,
        quoteId: existingDoc.quoteId,
        fileSizeBytes: existingDoc.fileSizeBytes,
        tags: existingDoc.tags,
        createdAt: existingDoc.createdAt,
        updatedAt: DateTime.now(),
      );

      // No update method available, so delete and re-add
      await appState.deleteInspectionDocument(existingDoc.id);
      await appState.addInspectionDocument(updatedDoc);
      _isLoading = false;
      notifyListeners();
      
      debugPrint('✏️ Updated inspection note');
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update note: $e';
      notifyListeners();
      debugPrint('❌ Update note failed: $e');
    }
  }

  /// Add inspection PDF
  Future<void> addInspectionPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        _isLoading = true;
        notifyListeners();

        final file = result.files.first;
        final filePath = file.path;

        if (filePath == null) {
          throw Exception('File path is null');
        }

        final appState = context.read<AppStateProvider>();
        final inspectionDoc = InspectionDocument(
          customerId: customer.id,
          type: 'pdf',
          title: file.name,
          filePath: filePath,
          fileSizeBytes: file.size,
          sortOrder: 0,
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await appState.addInspectionDocument(inspectionDoc);
        _isLoading = false;
        notifyListeners();
        
        debugPrint('📄 Added inspection PDF: ${file.name}');
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to add PDF: $e';
      notifyListeners();
      debugPrint('❌ Add PDF failed: $e');
    }
  }

  /// Delete inspection document
  Future<void> deleteInspectionDocument(String documentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final appState = context.read<AppStateProvider>();
      final document = appState.getInspectionDocumentsForCustomer(customer.id)
          .firstWhere((doc) => doc.id == documentId);

      // Delete physical file if it exists
      if (document.filePath != null && document.filePath!.isNotEmpty) {
        final file = File(document.filePath!);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      await appState.deleteInspectionDocument(documentId);
      _isLoading = false;
      notifyListeners();
      
      debugPrint('🗑️ Deleted inspection document: ${document.title}');
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete document: $e';
      notifyListeners();
      debugPrint('❌ Delete document failed: $e');
    }
  }

  /// Get field display value for UI
  String getFieldDisplayValue(String fieldName, String fieldType) {
    final value = _fieldValues[fieldName];
    
    if (value == null) return '';
    
    switch (fieldType.toLowerCase()) {
      case 'date':
        if (value is String && value.isNotEmpty) {
          final date = DateTime.tryParse(value);
          if (date != null) {
            return '${date.day}/${date.month}/${date.year}';
          }
        }
        return '';
      case 'bool':
      case 'boolean':
      case 'checkbox':
        return value.toString() == 'true' ? 'Yes' : 'No';
      default:
        return value.toString();
    }
  }

  /// Check if inspection has any data
  bool hasInspectionData() {
    final inspectionFields = getInspectionFields();
    final inspectionDocuments = getInspectionDocuments();
    
    // Check if any fields have values
    for (final field in inspectionFields) {
      final value = _fieldValues[field.fieldName];
      if (value != null && value.toString().trim().isNotEmpty) {
        return true;
      }
    }
    
    // Check if any documents exist
    return inspectionDocuments.isNotEmpty;
  }

  /// Get completion percentage for inspection
  double getCompletionPercentage() {
    final inspectionFields = getInspectionFields();
    if (inspectionFields.isEmpty) return 0.0;
    
    int completedFields = 0;
    for (final field in inspectionFields) {
      final value = _fieldValues[field.fieldName];
      if (value != null && value.toString().trim().isNotEmpty) {
        completedFields++;
      }
    }
    
    return completedFields / inspectionFields.length;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🧹 InspectionTabController disposed');
    super.dispose();
  }
}