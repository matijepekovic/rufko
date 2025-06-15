import 'package:flutter/foundation.dart';
import '../models/templates/pdf_template.dart';
import '../models/templates/message_template.dart';
import '../models/templates/email_template.dart';
import '../models/templates/template_category.dart';
import '../../core/services/database/database_service.dart';

class TemplateProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<PDFTemplate> _pdfTemplates = [];
  List<MessageTemplate> _messageTemplates = [];
  List<EmailTemplate> _emailTemplates = [];
  final List<TemplateCategory> _categories = [];

  TemplateProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<PDFTemplate> get pdfTemplates => _pdfTemplates;
  List<MessageTemplate> get messageTemplates => _messageTemplates;
  List<EmailTemplate> get emailTemplates => _emailTemplates;
  List<TemplateCategory> get categories => _categories;

  Future<void> loadTemplates() async {
    _pdfTemplates = await _db.getAllPDFTemplates();
    _messageTemplates = await _db.getAllMessageTemplates();
    _emailTemplates = await _db.getAllEmailTemplates();
    _categories.clear();
    _categories.addAll(_db.getRawCategoriesBoxValues().whereType<TemplateCategory>());
    notifyListeners();
  }

  Future<void> addPDFTemplate(PDFTemplate t) async {
    await _db.savePDFTemplate(t);
    _pdfTemplates.add(t);
    notifyListeners();
  }

  Future<void> updatePDFTemplate(PDFTemplate t) async {
    await _db.savePDFTemplate(t);
    final idx = _pdfTemplates.indexWhere((e) => e.id == t.id);
    if (idx != -1) _pdfTemplates[idx] = t;
    notifyListeners();
  }

  Future<void> deletePDFTemplate(String id) async {
    await _db.deletePDFTemplate(id);
    _pdfTemplates.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
