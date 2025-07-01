import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/quote/quote_service.dart';
import '../../../../core/services/pdf/pdf_generation_service.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote.dart';
import '../../../../data/models/business/quote_extras.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../customers/presentation/widgets/dialogs/email_composition_dialog.dart';
import '../../../customers/presentation/controllers/communication_history_controller.dart';
import 'pdf_generation_ui_controller.dart';

/// UI Controller for quote detail operations
/// Handles state management and event emission without UI concerns
class QuoteDetailUIController extends ChangeNotifier {
  QuoteDetailUIController({
    required this.quote,
    required this.customer,
    required AppStateProvider appState,
  }) : _appState = appState, _service = QuoteService() {
    selectedLevelId = quote.effectiveSelectedLevelId;
  }

  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  final AppStateProvider _appState;
  final QuoteService _service;

  String? selectedLevelId;
  bool _isProcessing = false;
  String? _lastError;
  String? _lastSuccess;
  PDFGenerationData? _lastGeneratedPdf;
  bool _isPreviewAction = false;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
  PDFGenerationData? get lastGeneratedPdf => _lastGeneratedPdf;
  bool get isPreviewAction => _isPreviewAction;
  List<String> get availableStatuses => _service.getAvailableStatuses();

  /// Factory constructor for easy creation with context
  factory QuoteDetailUIController.fromContext({
    required BuildContext context,
    required SimplifiedMultiLevelQuote quote,
    required Customer customer,
  }) {
    return QuoteDetailUIController(
      quote: quote,
      customer: customer,
      appState: context.read<AppStateProvider>(),
    );
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _lastSuccess = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _lastSuccess = success;
    _lastError = null;
    notifyListeners();
  }

  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    _lastGeneratedPdf = null;
    _isPreviewAction = false;
    notifyListeners();
  }

  /// Select quote level (preview-only, no database persistence)
  void selectLevel(String levelId) {
    selectedLevelId = levelId;
    
    // Note: This is now preview-only. The selection is NOT persisted to the database.
    // To commit a level selection, use extractLevel() instead.
    
    notifyListeners();
  }

  /// Extract the selected level as a new single-level quote
  Future<SimplifiedMultiLevelQuote?> extractLevel() async {
    if (selectedLevelId == null) {
      debugPrint('Cannot extract level: no level selected');
      return null;
    }
    
    if (_isProcessing) {
      debugPrint('Cannot extract level: already processing');
      return null;
    }
    
    _setProcessing(true);
    
    try {
      // Add timeout to prevent indefinite hanging
      return await _extractLevelInternal().timeout(const Duration(seconds: 30));
      
    } catch (e) {
      debugPrint('❌ Failed to extract level: $e');
      rethrow;
    } finally {
      _setProcessing(false);
    }
  }
  
  /// Internal method for extracting level
  Future<SimplifiedMultiLevelQuote> _extractLevelInternal() async {
    // Find the selected level
    final selectedLevel = quote.levels.firstWhere(
      (level) => level.id == selectedLevelId,
      orElse: () => throw Exception('Selected level not found'),
    );
    
    debugPrint('🔄 Creating deep copy of level: ${selectedLevel.name}');
    
    // Create a new quote with only the selected level (deep copied with new UUID)
    final copiedLevel = _createLevelCopy(selectedLevel);
    final extractedQuote = SimplifiedMultiLevelQuote(
      customerId: quote.customerId,
      roofScopeDataId: quote.roofScopeDataId,
      quoteNumber: _generateNewQuoteNumber(quote),
      levels: [copiedLevel], // Deep copy with new UUID
      addons: _deepCopyAddons(quote.addons), // Deep copy addons too
      taxRate: quote.taxRate,
      discount: quote.discount,
      status: 'draft', // Reset to draft
      notes: quote.notes,
      validUntil: quote.validUntil,
      baseProductId: quote.baseProductId,
      baseProductName: quote.baseProductName,
      baseProductUnit: quote.baseProductUnit,
      discounts: _deepCopyDiscounts(quote.discounts),
      nonDiscountableProductIds: List.from(quote.nonDiscountableProductIds),
      permits: _deepCopyPermits(quote.permits),
      noPermitsRequired: quote.noPermitsRequired,
      customLineItems: _deepCopyCustomLineItems(quote.customLineItems),
      selectedLevelId: copiedLevel.id, // Use the NEW level ID
    );
    
    debugPrint('🔄 Saving extracted quote: ${extractedQuote.quoteNumber}');
    
    // Save the new extracted quote with retry mechanism
    await _saveWithRetry(extractedQuote);
    
    debugPrint('✅ Successfully extracted level: ${extractedQuote.quoteNumber}');
    return extractedQuote;
  }
  
  /// Save quote with retry mechanism to handle database locks
  Future<void> _saveWithRetry(SimplifiedMultiLevelQuote quote) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);
    
    while (retryCount < maxRetries) {
      try {
        await _appState.addSimplifiedQuote(quote);
        return; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        debugPrint('⚠️ Save attempt $retryCount failed: $e');
        
        if (retryCount >= maxRetries) {
          throw Exception('Failed to save quote after $maxRetries attempts: $e');
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay);
      }
    }
  }
  
  /// Generate a new quote number for extracted quotes
  String _generateNewQuoteNumber(SimplifiedMultiLevelQuote originalQuote) {
    return '${originalQuote.quoteNumber} - Extracted for Contract';
  }

  /// Create a deep copy of a quote level with new UUID to prevent database conflicts
  QuoteLevel _createLevelCopy(QuoteLevel originalLevel) {
    final uuid = const Uuid();
    
    // Create copies of all included items with new UUIDs (if they have them)
    final List<QuoteItem> copiedItems = originalLevel.includedItems.map((item) {
      return QuoteItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        unit: item.unit,
        description: item.description,
      );
    }).toList();
    
    // Create new level with new UUID
    return QuoteLevel(
      id: uuid.v4(), // NEW UUID to prevent conflicts
      name: originalLevel.name,
      levelNumber: originalLevel.levelNumber,
      basePrice: originalLevel.basePrice,
      baseQuantity: originalLevel.baseQuantity,
      includedItems: copiedItems,
      subtotal: originalLevel.subtotal,
    );
  }

  /// Deep copy addons with new UUIDs
  List<QuoteItem> _deepCopyAddons(List<QuoteItem> addons) {
    return addons.map((addon) {
      return QuoteItem(
        productId: addon.productId,
        productName: addon.productName,
        quantity: addon.quantity,
        unitPrice: addon.unitPrice,
        unit: addon.unit,
        description: addon.description,
      );
    }).toList();
  }

  /// Deep copy discounts with new UUIDs
  List<QuoteDiscount> _deepCopyDiscounts(List<QuoteDiscount> discounts) {
    final uuid = const Uuid();
    return discounts.map((discount) {
      return QuoteDiscount(
        id: uuid.v4(), // New UUID
        type: discount.type,
        value: discount.value,
        code: discount.code,
        description: discount.description,
        applyToAddons: discount.applyToAddons,
        excludedProductIds: List.from(discount.excludedProductIds),
        expiryDate: discount.expiryDate,
        isActive: discount.isActive,
      );
    }).toList();
  }

  /// Deep copy permits with new UUIDs
  List<PermitItem> _deepCopyPermits(List<PermitItem> permits) {
    final uuid = const Uuid();
    return permits.map((permit) {
      return PermitItem(
        id: uuid.v4(), // New UUID
        name: permit.name,
        amount: permit.amount,
        description: permit.description,
        isRequired: permit.isRequired,
      );
    }).toList();
  }

  /// Deep copy custom line items with new UUIDs
  List<CustomLineItem> _deepCopyCustomLineItems(List<CustomLineItem> items) {
    final uuid = const Uuid();
    return items.map((item) {
      return CustomLineItem(
        id: uuid.v4(), // New UUID
        name: item.name,
        amount: item.amount,
        description: item.description,
        isTaxable: item.isTaxable,
      );
    }).toList();
  }

  /// Update quote status
  Future<void> updateQuoteStatus(String newStatus) async {
    _setProcessing(true);
    
    try {
      final result = await _service.updateQuoteStatus(
        quote: quote,
        newStatus: newStatus,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        notifyListeners(); // Notify for quote changes
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Delete quote
  Future<bool> deleteQuote() async {
    _setProcessing(true);
    
    try {
      final result = await _service.deleteQuote(
        quote: quote,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Add discount
  Future<void> addDiscount(dynamic discount) async {
    _setProcessing(true);
    
    try {
      final result = await _service.addDiscount(
        quote: quote,
        discount: discount,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        notifyListeners(); // Notify for quote changes
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Remove discount
  Future<void> removeDiscount(String discountId) async {
    _setProcessing(true);
    
    try {
      final result = await _service.removeDiscount(
        quote: quote,
        discountId: discountId,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        notifyListeners(); // Notify for quote changes
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Get status color (UI helper)
  Color getStatusColor() {
    switch (quote.status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status button text (UI helper)
  String getStatusButtonText() {
    return _service.getStatusButtonText(quote.status);
  }

  /// Check if status button should be enabled
  bool isStatusButtonEnabled() {
    return _service.isStatusButtonEnabled(quote);
  }

  /// Get disabled button tooltip
  String? getDisabledButtonTooltip() {
    return _service.getDisabledButtonTooltip(quote);
  }

  /// Check if PDF is available for this quote
  bool get hasPdfAvailable => _service.hasPdfGenerated(quote);

  /// Send PDF via email - opens email composition dialog with PDF attached
  Future<void> sendPdfViaEmail(BuildContext context) async {
    if (!hasPdfAvailable) {
      _setError('No PDF available to send. Please generate PDF first.');
      return;
    }

    try {
      final pdfPath = _service.getPdfPath(quote);
      if (pdfPath == null) {
        _setError('PDF file not found. Please regenerate PDF.');
        return;
      }

      // Create communication history controller for email functionality
      final communicationController = CommunicationHistoryController(
        customer: customer,
        context: context,
      );

      // Navigate to email composition dialog with PDF attachment
      if (context.mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmailCompositionDialog(
              customer: customer,
              communicationController: communicationController,
              initialPdfAttachment: pdfPath,
              initialSubject: 'Quote ${quote.quoteNumber} - ${customer.name}',
            ),
            fullscreenDialog: true,
          ),
        );

        // If email was sent successfully, update quote status to 'sent'
        if (result == true) {
          await _updateQuoteStatusToSent();
        }
      }
    } catch (e) {
      debugPrint('Send PDF via email error: $e');
      _setError('Failed to open email dialog: $e');
    }
  }

  /// Get next logical status for quick update
  String? getNextLogicalStatus() {
    return _service.getNextLogicalStatus(quote.status);
  }

  /// Preview existing PDF or generate new one if none exists
  Future<PDFGenerationData?> previewExistingOrGeneratePdf({
    required BuildContext context,
  }) async {
    _setProcessing(true);
    _isPreviewAction = true;
    
    try {
      // Create PDF generation UI controller to check for existing PDFs
      final pdfController = PDFGenerationUIController(
        quote: quote,
        customer: customer,
        selectedLevelId: selectedLevelId,
      );
      
      // First, check if existing PDF exists
      final existingPdfPath = await pdfController.checkExistingPdf(context);
      
      if (existingPdfPath != null) {
        // Found existing PDF - create result for direct preview
        final suggestedFileName = PDFGenerationService().generateSuggestedFileName(quote, customer);
        final result = PDFGenerationData(
          pdfPath: existingPdfPath,
          suggestedFileName: suggestedFileName,
          isPreview: true,
        );
        
        _lastGeneratedPdf = result;
        _setSuccess('Opening existing PDF');
        return result;
      } else {
        // No existing PDF found - fall back to generating new one
        _setSuccess('No existing PDF found. Generating new PDF...');
        
        // Check if context is still mounted before proceeding
        if (!context.mounted) {
          _setError('Operation cancelled');
          return null;
        }
        
        // Generate new PDF (this will show template selection if needed)
        return await _generatePdfInternal(context: context);
      }
    } catch (e) {
      debugPrint('Preview PDF Error: $e');
      _setError('Failed to preview PDF: $e');
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Generate PDF for quote with template selection
  Future<PDFGenerationData?> generatePdf({
    required BuildContext context,
    String? selectedTemplateId,
  }) async {
    _isPreviewAction = false;
    return await _generatePdfInternal(
      context: context,
      selectedTemplateId: selectedTemplateId,
    );
  }

  /// Internal PDF generation method (shared by both preview and generate)
  Future<PDFGenerationData?> _generatePdfInternal({
    required BuildContext context,
    String? selectedTemplateId,
  }) async {
    try {
      String? templateId = selectedTemplateId;
      
      // If no template specified, check available templates and show selection
      if (templateId == null) {
        final availableTemplates = _appState.activePDFTemplates;
        
        if (availableTemplates != null && availableTemplates.isNotEmpty) {
          // Show template selection dialog
          templateId = await _showTemplateSelectionDialog(context, availableTemplates);
          if (templateId == null) {
            // User cancelled template selection
            _setError('PDF generation cancelled');
            return null;
          }
        }
        // If no templates available, templateId remains null for standard PDF
      }
      
      // Create PDF generation UI controller for this operation
      final pdfController = PDFGenerationUIController(
        quote: quote,
        customer: customer,
        selectedLevelId: selectedLevelId,
      );
      
      // Generate the PDF - check if context is still mounted
      if (!context.mounted) {
        _setError('Operation cancelled');
        return null;
      }
      
      final result = await pdfController.generatePdf(
        context: context,
        selectedTemplateId: templateId,
      );
      
      if (result != null) {
        _lastGeneratedPdf = result;
        
        // Update quote with PDF information for button state
        quote.pdfPath = result.pdfPath;
        quote.pdfTemplateId = result.templateId;
        quote.pdfGeneratedAt = DateTime.now();
        
        // Update status to pdf_generated if it was draft
        if (quote.status.toLowerCase() == 'draft') {
          quote.status = 'pdf_generated';
        }
        quote.updatedAt = DateTime.now();
        
        // Save updated quote to persist PDF information
        try {
          await _appState.updateSimplifiedQuote(quote);
          debugPrint('Quote updated with PDF path: ${result.pdfPath}, status: ${quote.status}');
        } catch (e) {
          debugPrint('Failed to update quote with PDF path: $e');
          // Don't fail the operation, just log the error
        }
        
        _setSuccess('PDF generated successfully');
        notifyListeners(); // Refresh button state
      } else {
        // More specific error message
        final errorMessage = templateId == 'standard' || templateId == null 
            ? 'Failed to generate standard PDF - please check quote data'
            : 'Failed to generate PDF from template - template may be invalid';
        _setError(errorMessage);
      }
      
      return result;
    } catch (e) {
      // Enhanced error logging for debugging
      debugPrint('PDF Generation Error: $e');
      debugPrint('Quote ID: ${quote.id}');
      debugPrint('Customer ID: ${customer.id}');
      debugPrint('Selected Level ID: $selectedLevelId');
      
      _setError('Failed to generate PDF: $e');
      return null;
    }
  }
  
  /// Show template selection dialog
  Future<String?> _showTemplateSelectionDialog(BuildContext context, dynamic templates) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select PDF Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Standard PDF option
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Standard Quote PDF'),
                subtitle: const Text('Generate using default format'),
                onTap: () => Navigator.of(context).pop('standard'),
              ),
              const Divider(),
              // Template options
              ...templates.map<Widget>((template) {
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(template.templateName),
                  subtitle: Text(template.description.isNotEmpty ? template.description : 'Custom PDF template'),
                  onTap: () => Navigator.of(context).pop(template.id),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Update quote status to 'sent' after successful email sending
  Future<void> _updateQuoteStatusToSent() async {
    try {
      final result = await _service.markQuoteAsSent(
        quote: quote,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
        notifyListeners(); // Refresh UI to show new status
      } else {
        _setError(result.errorMessage);
      }
    } catch (e) {
      debugPrint('Error updating quote status to sent: $e');
      _setError('Failed to update quote status: $e');
    }
  }
}