import 'package:flutter/foundation.dart';
import '../../models/settings/custom_app_data.dart';
import '../../models/media/inspection_document.dart';
import '../../../core/services/database/database_service.dart';
import '../helpers/data_loading_helper.dart';

class CustomFieldsProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<CustomAppDataField> _fields = [];
  List<InspectionDocument> _inspectionDocs = [];

  CustomFieldsProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<CustomAppDataField> get fields => _fields;
  List<InspectionDocument> get inspectionDocs =>
      List.unmodifiable(_inspectionDocs);

  Future<void> loadFields() async {
    _fields = await DataLoadingHelper.loadCustomAppDataFields(_db);
    notifyListeners();
  }

  Future<void> loadInspectionDocuments() async {
    _inspectionDocs = await DataLoadingHelper.loadInspectionDocuments(_db);
    notifyListeners();
  }

  Future<void> addField(CustomAppDataField field) async {
    await _db.saveCustomAppDataField(field);
    _fields.add(field);
    notifyListeners();
  }

  Future<void> updateFieldValue(String fieldId, String newValue) async {
    final index = _fields.indexWhere((f) => f.id == fieldId);
    if (index != -1) {
      final field = _fields[index];
      field.updateValue(newValue);
      await _db.saveCustomAppDataField(field);
      notifyListeners();
    }
  }

  Future<void> updateFieldStructure(CustomAppDataField updatedField) async {
    await _db.saveCustomAppDataField(updatedField);
    final index = _fields.indexWhere((f) => f.id == updatedField.id);
    if (index != -1) {
      _fields[index] = updatedField;
    } else {
      _fields.add(updatedField);
    }
    notifyListeners();
  }

  Future<void> deleteField(String fieldId) async {
    await _db.deleteCustomAppDataField(fieldId);
    _fields.removeWhere((f) => f.id == fieldId);
    notifyListeners();
  }

  Future<void> reorderFields(
      String category, List<CustomAppDataField> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].updateField(sortOrder: i);
    }
    await DatabaseService.instance.saveMultipleCustomAppDataFields(reordered);
    for (final field in reordered) {
      final index = _fields.indexWhere((f) => f.id == field.id);
      if (index != -1) {
        _fields[index] = field;
      }
    }
    notifyListeners();
  }

  List<CustomAppDataField> fieldsByCategory(String category) {
    return _fields.where((f) => f.category == category).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Map<String, String> dataMap() {
    final map = <String, String>{};
    for (final field in _fields) {
      map[field.fieldName] = field.currentValue;
    }
    return map;
  }

  Future<void> addTemplateFields(
      List<CustomAppDataField> templateFields) async {
    for (final field in templateFields) {
      final existing = _fields.where((f) => f.fieldName == field.fieldName);
      if (existing.isEmpty) {
        await addField(field);
      }
    }
  }

  Map<String, dynamic> exportData() {
    return {
      'customAppDataFields': _fields.map((f) => f.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (data['customAppDataFields'] != null) {
      final imported = (data['customAppDataFields'] as List)
          .map((e) => CustomAppDataField.fromMap(e))
          .toList();
      for (final field in imported) {
        final existingIndex =
            _fields.indexWhere((f) => f.fieldName == field.fieldName);
        if (existingIndex != -1) {
          await updateFieldStructure(field);
        } else {
          await addField(field);
        }
      }
    }
  }

  List<InspectionDocument> documentsForCustomer(String customerId) {
    return _inspectionDocs.where((doc) => doc.customerId == customerId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> addInspectionDocument(InspectionDocument doc) async {
    await DatabaseService.instance.saveInspectionDocument(doc);
    _inspectionDocs.add(doc);
    if (doc.sortOrder == 0) {
      final customerDocs = documentsForCustomer(doc.customerId);
      doc.updateSortOrder(customerDocs.length);
      await DatabaseService.instance.saveInspectionDocument(doc);
    }
    notifyListeners();
  }

  Future<void> deleteInspectionDocument(String id) async {
    await DatabaseService.instance.deleteInspectionDocument(id);
    _inspectionDocs.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }
}
