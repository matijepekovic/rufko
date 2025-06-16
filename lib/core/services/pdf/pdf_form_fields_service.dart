import '../../../data/models/ui/pdf_form_field.dart';
import '../../../features/quotes/presentation/controllers/pdf_document_controller.dart';

/// Service layer for PDF form field operations
/// Contains pure business logic without UI dependencies
class PdfFormFieldsService {
  /// Load form fields from PDF file
  static Future<List<PDFFormField>> loadFormFields(String pdfPath) async {
    // Business logic copied exactly from screen _loadFormFields method
    final controller = PdfDocumentController(pdfPath);
    final fields = await controller.loadFormFields();
    return fields;
  }
}