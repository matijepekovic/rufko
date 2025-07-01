import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import 'communication_history_controller.dart';
import 'email_composition_controller.dart';

/// Pure controller for email dialog functionality
/// Separates all business logic from UI components
class EmailDialogController extends ChangeNotifier {
  final Customer customer;
  final BuildContext context;
  final CommunicationHistoryController communicationController;
  final bool isReply;
  final String? replyToThreadSubject;
  final String? initialPdfAttachment; // NEW: Initial PDF file path to attach
  final String? initialSubject; // NEW: Pre-filled subject line
  
  EmailDialogController({
    required this.customer,
    required this.context,
    required this.communicationController,
    this.isReply = false,
    this.replyToThreadSubject,
    this.initialPdfAttachment, // NEW: Optional PDF attachment
    this.initialSubject, // NEW: Optional initial subject
  }) {
    _initialize();
  }

  // Core composition controller
  late EmailCompositionController _compositionController;
  
  // Attachment state
  final List<PlatformFile> _fileAttachments = [];
  final List<String> _selectedQuoteAttachments = [];
  final List<String> _selectedMediaAttachments = [];
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  
  // Text controllers (managed by controller, not UI)
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  
  // Getters
  EmailCompositionController get compositionController => _compositionController;
  List<PlatformFile> get fileAttachments => _fileAttachments;
  List<String> get selectedQuoteAttachments => _selectedQuoteAttachments;
  List<String> get selectedMediaAttachments => _selectedMediaAttachments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TextEditingController get subjectController => _subjectController;
  TextEditingController get bodyController => _bodyController;
  
  // Computed getters
  bool get hasAttachments => 
    _fileAttachments.isNotEmpty || 
    _selectedQuoteAttachments.isNotEmpty || 
    _selectedMediaAttachments.isNotEmpty;
    
  int get totalAttachmentCount => 
    _fileAttachments.length + 
    _selectedQuoteAttachments.length + 
    _selectedMediaAttachments.length;
  
  bool get canSend => 
    !_compositionController.isSending && 
    _compositionController.subject.trim().isNotEmpty && 
    _compositionController.body.trim().isNotEmpty &&
    (customer.email?.isNotEmpty ?? false);

  void _initialize() {
    _compositionController = EmailCompositionController(
      customer: customer,
      context: context,
      communicationController: communicationController,
    );
    
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    
    // Initialize based on mode
    _initializeController();
    
    // Listen to composition controller changes
    _compositionController.addListener(_onCompositionChanged);
  }
  
  Future<void> _initializeController() async {
    _setLoading(true);
    try {
      if (isReply && replyToThreadSubject != null) {
        await _compositionController.initializeForReply(replyToThreadSubject!);
      } else {
        await _compositionController.initializeForNewEmail();
      }
      
      // Set initial subject if provided
      if (initialSubject != null && initialSubject!.isNotEmpty) {
        _compositionController.updateSubject(initialSubject!);
      }
      
      // Add initial PDF attachment if provided
      if (initialPdfAttachment != null && initialPdfAttachment!.isNotEmpty) {
        await _addPdfFileAttachment(initialPdfAttachment!);
      }
      
      _updateTextControllers();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize email dialog: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void _onCompositionChanged() {
    _updateTextControllers();
    notifyListeners();
  }
  
  void _updateTextControllers() {
    if (_subjectController.text != _compositionController.subject) {
      _subjectController.text = _compositionController.subject;
    }
    if (_bodyController.text != _compositionController.body) {
      _bodyController.text = _compositionController.body;
    }
  }
  
  // Template operations
  void selectTemplate(dynamic template) {
    _compositionController.selectTemplate(template);
  }
  
  // Content operations
  void updateSubject(String subject) {
    _compositionController.updateSubject(subject);
  }
  
  void updateBody(String body) {
    _compositionController.updateBody(body);
  }
  
  // File attachment operations
  Future<void> attachFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        _fileAttachments.addAll(result.files);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick files: $e');
    }
  }
  
  void removeFileAttachment(PlatformFile file) {
    _fileAttachments.remove(file);
    notifyListeners();
  }
  
  // Customer data attachment operations
  Future<void> attachCustomerData() async {
    try {
      final appState = context.read<AppStateProvider>();
      final customerQuotes = appState.getSimplifiedQuotesForCustomer(customer.id);
      final customerMedia = appState.getProjectMediaForCustomer(customer.id);
      
      if (customerQuotes.isEmpty && customerMedia.isEmpty) {
        _setError('No customer documents or media found');
        return;
      }

      // Store selection data for UI to use
      for (final quote in customerQuotes) {
        _selectedQuoteAttachments.add(quote.id);
      }
      for (final media in customerMedia) {
        _selectedMediaAttachments.add(media.id);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load customer data: $e');
    }
  }
  
  void addQuoteAttachment(String quoteId) {
    if (!_selectedQuoteAttachments.contains(quoteId)) {
      _selectedQuoteAttachments.add(quoteId);
      notifyListeners();
    }
  }
  
  void removeQuoteAttachment(String quoteId) {
    _selectedQuoteAttachments.remove(quoteId);
    notifyListeners();
  }
  
  void addMediaAttachment(String mediaId) {
    if (!_selectedMediaAttachments.contains(mediaId)) {
      _selectedMediaAttachments.add(mediaId);
      notifyListeners();
    }
  }
  
  void removeMediaAttachment(String mediaId) {
    _selectedMediaAttachments.remove(mediaId);
    notifyListeners();
  }
  
  void clearAllAttachments() {
    _fileAttachments.clear();
    _selectedQuoteAttachments.clear();
    _selectedMediaAttachments.clear();
    notifyListeners();
  }
  
  /// Add PDF file as attachment from file path
  Future<void> _addPdfFileAttachment(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found at path: $pdfPath');
      }

      // Create PlatformFile from the PDF file
      final fileName = file.path.split('/').last;
      final fileBytes = await file.readAsBytes();
      
      final platformFile = PlatformFile(
        name: fileName,
        size: fileBytes.length,
        path: pdfPath,
        bytes: fileBytes,
      );

      _fileAttachments.add(platformFile);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to attach PDF file: $e');
      _setError('Failed to attach PDF file: $e');
    }
  }
  
  // Email sending
  Future<bool> sendEmail() async {
    if (!canSend) {
      _setError('Cannot send email - missing required fields or recipient');
      return false;
    }
    
    try {
      final success = await _compositionController.sendEmail();
      
      if (success) {
        _clearError();
        return true;
      } else {
        // Error message is set by composition controller
        return false;
      }
    } catch (e) {
      _setError('Failed to send email: $e');
      return false;
    }
  }
  
  // Customer data helpers
  Map<String, dynamic> getCustomerDataForAttachment() {
    try {
      final appState = context.read<AppStateProvider>();
      return {
        'quotes': appState.getSimplifiedQuotesForCustomer(customer.id),
        'media': appState.getProjectMediaForCustomer(customer.id),
      };
    } catch (e) {
      return {'quotes': [], 'media': []};
    }
  }
  
  // State management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Success message generation
  String generateSuccessMessage() {
    final hasCustomerAttachments = _selectedQuoteAttachments.isNotEmpty || _selectedMediaAttachments.isNotEmpty;
    final hasFileAttachments = _fileAttachments.isNotEmpty;
    
    String message = 'Email app opened successfully!';
    if (hasCustomerAttachments || hasFileAttachments) {
      message += '\n\nNote: Please manually attach the selected files in your email app:';
      if (hasCustomerAttachments) {
        final totalCustomerFiles = _selectedQuoteAttachments.length + _selectedMediaAttachments.length;
        message += '\n• $totalCustomerFiles customer document${totalCustomerFiles > 1 ? 's' : ''}';
      }
      if (hasFileAttachments) {
        message += '\n• ${_fileAttachments.length} selected file${_fileAttachments.length > 1 ? 's' : ''}';
      }
    }
    return message;
  }
  
  @override
  void dispose() {
    _compositionController.removeListener(_onCompositionChanged);
    _compositionController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}