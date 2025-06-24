import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/quote/quote_service.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

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

  // Getters
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;
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
    notifyListeners();
  }

  /// Select quote level
  Future<void> selectLevel(String levelId) async {
    selectedLevelId = levelId;
    
    // Persist the selection to the quote
    quote.selectedLevelId = levelId;
    quote.updatedAt = DateTime.now();
    
    try {
      await _appState.updateSimplifiedQuote(quote);
    } catch (e) {
      // If save fails, we keep the UI updated but log the error
      debugPrint('Failed to save level selection: $e');
    }
    
    notifyListeners();
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
    switch (quote.status.toLowerCase()) {
      case 'draft':
        return 'Send Quote';
      case 'sent':
        return 'Mark Accepted';
      case 'accepted':
        return 'Mark Complete';
      default:
        return 'Update Status';
    }
  }

  /// Get next logical status for quick update
  String? getNextLogicalStatus() {
    return _service.getNextLogicalStatus(quote.status);
  }
}