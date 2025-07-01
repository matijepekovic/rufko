import 'package:flutter/foundation.dart';

import '../../../../data/models/ui/edit_action.dart';

class PdfEditingController extends ChangeNotifier {
  final Map<String, String> editedValues = {};
  final List<EditAction> _editHistory = [];
  int _currentHistoryIndex = -1;

  bool get hasEdits => editedValues.isNotEmpty;
  int get currentHistoryIndex => _currentHistoryIndex;
  List<EditAction> get history => List.unmodifiable(_editHistory);

  void addEdit(String fieldName, String oldValue, String newValue) {
    if (oldValue == newValue) return;

    if (_currentHistoryIndex < _editHistory.length - 1) {
      _editHistory.removeRange(_currentHistoryIndex + 1, _editHistory.length);
    }

    _editHistory.add(EditAction(
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
    ));
    _currentHistoryIndex = _editHistory.length - 1;

    if (_editHistory.length > 50) {
      _editHistory.removeAt(0);
      _currentHistoryIndex--;
    }

    editedValues[fieldName] = newValue;
    notifyListeners();
  }

  void undo() {
    if (_currentHistoryIndex < 0) return;
    final action = _editHistory[_currentHistoryIndex];
    editedValues[action.fieldName] = action.oldValue;
    _currentHistoryIndex--;
    notifyListeners();
  }

  void redo() {
    if (_currentHistoryIndex >= _editHistory.length - 1) return;
    _currentHistoryIndex++;
    final action = _editHistory[_currentHistoryIndex];
    editedValues[action.fieldName] = action.newValue;
    notifyListeners();
  }

  void clearAll() {
    editedValues.clear();
    _editHistory.clear();
    _currentHistoryIndex = -1;
    notifyListeners();
  }

  // Additional methods for PDF preview controller compatibility
  String getFieldValue(String fieldKey) {
    return editedValues[fieldKey] ?? '';
  }

  Map<String, String> getCurrentEdits() {
    return Map.from(editedValues);
  }

  void clearEdits() {
    clearAll();
  }

  void updateField(String fieldName, String value) {
    final oldValue = editedValues[fieldName] ?? '';
    addEdit(fieldName, oldValue, value);
  }

  bool canUndo() {
    return _currentHistoryIndex >= 0;
  }

  bool canRedo() {
    return _currentHistoryIndex < _editHistory.length - 1;
  }
}
