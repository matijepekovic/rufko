import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../core/services/pdf/pdf_interaction_service.dart';

/// Controller for PDF viewer operations in template editor
/// Handles PDF display, page management, and user interaction
class TemplatePdfController extends ChangeNotifier {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  PDFTemplate? _currentTemplate;
  List<Map<String, dynamic>> _detectedPdfFieldsList = [];
  int _currentPageZeroBased = 0;
  int _totalPagesInPdf = 1;

  // Getters
  PdfViewerController get pdfController => _pdfViewerController;
  int get currentPage => _currentPageZeroBased;
  int get totalPages => _totalPagesInPdf;
  List<Map<String, dynamic>> get detectedFields => _detectedPdfFieldsList;
  File? get pdfFile => _currentTemplate?.pdfFilePath.isNotEmpty == true 
      ? File(_currentTemplate!.pdfFilePath) 
      : null;

  /// Initialize PDF controller with template
  void initializeWithTemplate(PDFTemplate? template) {
    _currentTemplate = template;
    if (template != null) {
      _loadPdfDetails();
    }
    _pdfViewerController.addListener(_viewerControllerListener);
  }

  /// Load PDF details from template metadata
  void _loadPdfDetails() {
    if (_currentTemplate == null) return;
    
    _totalPagesInPdf = _currentTemplate!.totalPages;
    
    // Extract detected PDF fields from metadata
    var detectedFieldsRaw = _currentTemplate!.metadata['detectedPdfFields'];
    if (detectedFieldsRaw is List) {
      _detectedPdfFieldsList = List<Map<String, dynamic>>.from(
          detectedFieldsRaw.map((e) => Map<String, dynamic>.from(e as Map)));
    } else {
      _detectedPdfFieldsList = [];
    }
    
    _currentPageZeroBased = 0;
    notifyListeners();

    // Navigate to first page with delay to ensure PDF is loaded
    Future.delayed(Duration.zero, () {
      if (_totalPagesInPdf > 0) {
        if (_pdfViewerController.pageCount >= 1) {
          _pdfViewerController.jumpToPage(1);
        } else {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (_pdfViewerController.pageCount >= 1) {
              _pdfViewerController.jumpToPage(1);
            }
          });
        }
      }
    });
  }

  /// Handle PDF viewer controller changes
  void _viewerControllerListener() {
    int controllerPageOneBased = _pdfViewerController.pageNumber;
    if (controllerPageOneBased > 0 &&
        (controllerPageOneBased - 1) != _currentPageZeroBased) {
      _currentPageZeroBased = controllerPageOneBased - 1;
      notifyListeners();
    }
  }

  /// Handle page change events from PDF viewer
  void onPageChanged(int page) {
    _currentPageZeroBased = page;
    _totalPagesInPdf = _pdfViewerController.pageCount;
    notifyListeners();
  }

  /// Handle PDF tap events and detect field interactions
  Map<String, dynamic>? handlePdfTap(PdfGestureDetails details) {
    if (_currentTemplate == null || details.pageNumber < 1) {
      return null;
    }

    return PdfInteractionService.instance.getTappedField(
      _detectedPdfFieldsList,
      details.pageNumber - 1,
      details.pagePosition,
    );
  }

  /// Update template reference
  void updateTemplate(PDFTemplate template) {
    _currentTemplate = template;
    _loadPdfDetails();
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_viewerControllerListener);
    _pdfViewerController.dispose();
    super.dispose();
  }
}