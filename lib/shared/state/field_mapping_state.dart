import 'package:flutter/material.dart';
import '../../data/models/templates/pdf_template.dart';

class FieldMappingState extends ChangeNotifier {
  Map<String, dynamic>? selectedPdfField;
  FieldMapping? currentMapping;

  void selectPdfField(Map<String, dynamic> info, FieldMapping? mapping) {
    selectedPdfField = info;
    currentMapping = mapping;
    notifyListeners();
  }

  void clear() {
    selectedPdfField = null;
    currentMapping = null;
    notifyListeners();
  }
}
