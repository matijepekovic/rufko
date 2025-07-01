import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/communication/communication_service.dart';
import 'communication_history_controller.dart';

/// Controller for email composition functionality
/// Handles both new emails and replies with proper threading
class EmailCompositionController extends ChangeNotifier {
  final Customer customer;
  final BuildContext context;
  final CommunicationHistoryController communicationController;
  
  EmailCompositionController({
    required this.customer,
    required this.context,
    required this.communicationController,
  });

  final CommunicationService _communicationService = const CommunicationService();
  
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  List<dynamic> _availableTemplates = [];
  dynamic _selectedTemplate;
  
  // Email composition state
  String _subject = '';
  String _body = '';
  bool _isReply = false;
  String? _replyToThreadSubject;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  List<dynamic> get availableTemplates => _availableTemplates;
  dynamic get selectedTemplate => _selectedTemplate;
  String get subject => _subject;
  String get body => _body;
  bool get isReply => _isReply;
  String? get replyToThreadSubject => _replyToThreadSubject;
  
  /// Initialize controller for composing new email
  Future<void> initializeForNewEmail() async {
    _isReply = false;
    _replyToThreadSubject = null;
    _subject = '';
    _body = '';
    _selectedTemplate = null;
    await _loadEmailTemplates();
  }
  
  /// Initialize controller for replying to email thread
  Future<void> initializeForReply(String threadSubject) async {
    _isReply = true;
    _replyToThreadSubject = threadSubject;
    _subject = _generateReplySubject(threadSubject);
    _body = '';
    _selectedTemplate = null;
    await _loadEmailTemplates();
  }
  
  /// Load available email templates
  Future<void> _loadEmailTemplates() async {
    _setLoading(true);
    try {
      final appState = context.read<AppStateProvider>();
      _availableTemplates = appState.activeEmailTemplates ?? [];
      _clearError();
    } catch (e) {
      _setError('Failed to load email templates: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Generate reply subject with "Re:" prefix
  String _generateReplySubject(String originalSubject) {
    final normalized = originalSubject.trim();
    if (normalized.toLowerCase().startsWith('re:')) {
      return normalized; // Already has Re: prefix
    }
    return 'Re: $normalized';
  }
  
  /// Update subject
  void updateSubject(String newSubject) {
    _subject = newSubject;
    notifyListeners();
  }
  
  /// Update body content
  void updateBody(String newBody) {
    _body = newBody;
    notifyListeners();
  }
  
  /// Select email template and populate content
  void selectTemplate(dynamic template) {
    _selectedTemplate = template;
    
    if (template != null) {
      try {
        final appState = context.read<AppStateProvider>();
        final customerData = _communicationService.buildCustomerDataMap(
          customer: customer,
          appState: appState,
        );
        
        // Replace template variables in subject and body
        String templateSubject = template.subject ?? '';
        String templateBody = template.emailContent ?? '';
        
        // Replace variables in both subject and body
        customerData.forEach((key, value) {
          final placeholder = '{$key}';
          templateSubject = templateSubject.replaceAll(placeholder, value);
          templateBody = templateBody.replaceAll(placeholder, value);
        });
        
        // Update subject (only for new emails, not replies)
        if (!_isReply) {
          _subject = templateSubject;
        }
        
        // Update body content
        _body = templateBody;
        
        _clearError();
      } catch (e) {
        _setError('Failed to process template: $e');
      }
    } else {
      // Clear template content
      if (!_isReply) {
        _subject = '';
      }
      _body = '';
    }
    
    notifyListeners();
  }
  
  /// Validate email before sending
  bool _validateEmail() {
    _clearError();
    
    if (customer.email == null || customer.email!.trim().isEmpty) {
      _setError('Customer has no email address');
      return false;
    }
    
    if (_subject.trim().isEmpty) {
      _setError('Subject is required');
      return false;
    }
    
    if (_body.trim().isEmpty) {
      _setError('Email content is required');
      return false;
    }
    
    return true;
  }
  
  /// Send email using communication service
  Future<bool> sendEmail() async {
    if (!_validateEmail()) {
      return false;
    }
    
    _setSending(true);
    
    try {
      final appState = context.read<AppStateProvider>();
      
      // Send email using communication service
      final result = await _communicationService.sendTemplateEmail(
        customer: customer,
        template: _selectedTemplate ?? _createDynamicTemplate(),
        subject: _subject.trim(),
        content: _body.trim(),
        appState: appState,
      );
      
      if (result.isSuccess) {
        // Log outbound email with proper threading
        await communicationController.addOutboundEmail(
          subject: _subject.trim(),
          content: _body.trim(),
          replyToThread: _isReply ? _replyToThreadSubject : null,
        );
        
        _clearError();
        return true;
      } else {
        _setError(result.errorMessage ?? 'Failed to send email');
        return false;
      }
    } catch (e) {
      _setError('Email sending failed: $e');
      return false;
    } finally {
      _setSending(false);
    }
  }
  
  /// Create dynamic template object when no template is selected
  dynamic _createDynamicTemplate() {
    return _DynamicTemplate(
      templateName: _isReply ? 'Reply Email' : 'Custom Email',
      subject: _subject,
      emailContent: _body,
    );
  }
  
  /// Get available email threads for reply selection
  List<Map<String, dynamic>> getAvailableThreads() {
    try {
      return communicationController.groupEmailsByThread();
    } catch (e) {
      return [];
    }
  }
  
  /// Check if subject would create new thread
  bool wouldCreateNewThread(String subject) {
    return communicationController.wouldCreateNewThread(subject);
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setSending(bool sending) {
    _isSending = sending;
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
}

/// Simple template implementation for dynamic emails
class _DynamicTemplate {
  final String templateName;
  final String subject;
  final String emailContent;
  
  _DynamicTemplate({
    required this.templateName,
    required this.subject,
    required this.emailContent,
  });
}