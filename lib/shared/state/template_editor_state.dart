import 'package:flutter/material.dart';
import '../../data/models/templates/pdf_template.dart';

class TemplateEditorState extends ChangeNotifier {
  PDFTemplate? currentTemplate;
  bool isLoading = false;
  String loadingMessage = '';
  String? selectedCategoryKey;
  int currentPageZeroBased = 0;
  int totalPagesInPdf = 1;
  List<Map<String, dynamic>> detectedPdfFieldsList = [];

  void setLoading(bool value, [String message = '']) {
    isLoading = value;
    loadingMessage = message;
    notifyListeners();
  }
}
