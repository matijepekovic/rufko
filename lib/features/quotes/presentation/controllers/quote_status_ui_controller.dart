import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/quote/quote_service.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for quote status operations
/// Handles dialogs, navigation, and user interactions without business logic
class QuoteStatusUIController extends ChangeNotifier {
  QuoteStatusUIController({
    required AppStateProvider appState,
  }) : _appState = appState, _service = QuoteService();

  final AppStateProvider _appState;
  final QuoteService _service;

  bool _isProcessing = false;
  String? _lastError;
  String? _lastSuccess;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;

  /// Factory constructor for easy creation with context
  factory QuoteStatusUIController.fromContext(BuildContext context) {
    return QuoteStatusUIController(
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

  /// Handle mark accepted button tap
  Future<void> handleMarkAccepted(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    if (quote.levels.length == 1) {
      // Single level quote - mark directly
      await _markSingleLevelAccepted(quote);
    } else {
      // Multi-level quote - show selection dialog
      await _showMultiLevelSelectionDialog(context, quote);
    }
  }

  /// Handle mark declined button tap
  Future<void> handleMarkDeclined(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    final confirmed = await _showDeclineConfirmationDialog(context, quote);
    if (confirmed) {
      await _markQuoteDeclined(quote);
    }
  }

  /// Handle mark complete button tap
  Future<void> handleMarkComplete(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    final confirmed = await _showCompleteConfirmationDialog(context, quote);
    if (confirmed) {
      await _markQuoteComplete(quote);
    }
  }

  /// Mark single level quote as accepted
  Future<void> _markSingleLevelAccepted(SimplifiedMultiLevelQuote quote) async {
    _setProcessing(true);
    
    try {
      final result = await _service.markQuoteAccepted(
        quote: quote,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Mark quote as declined
  Future<void> _markQuoteDeclined(SimplifiedMultiLevelQuote quote) async {
    _setProcessing(true);
    
    try {
      final result = await _service.markQuoteDeclined(
        quote: quote,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Mark specific level as accepted
  Future<void> _markLevelAccepted(
    SimplifiedMultiLevelQuote quote,
    String levelId,
  ) async {
    _setProcessing(true);
    
    try {
      final result = await _service.markLevelAccepted(
        quote: quote,
        acceptedLevelId: levelId,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Show multi-level selection dialog
  Future<void> _showMultiLevelSelectionDialog(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    if (!context.mounted) return;

    final selectedLevelId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Level to Accept'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select which level to accept. All other levels will be marked as declined.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...quote.levels.map((level) {
                final levelTotal = quote.getDisplayTotalForLevel(level.id);
                return ListTile(
                  title: Text(level.name),
                  subtitle: Text('\$${levelTotal.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.of(context).pop(level.id),
                );
              }),
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

    if (selectedLevelId != null) {
      await _markLevelAccepted(quote, selectedLevelId);
    }
  }

  /// Show decline confirmation dialog
  Future<bool> _showDeclineConfirmationDialog(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    if (!context.mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Quote'),
        content: Text(
          quote.levels.length > 1
              ? 'Are you sure you want to decline this quote? All levels will be marked as declined.'
              : 'Are you sure you want to decline this quote?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Show success snackbar
  void showSuccessMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Check if mark buttons should be shown
  bool shouldShowMarkButtons(SimplifiedMultiLevelQuote quote) {
    return _service.shouldShowMarkButtons(quote);
  }

  /// Check if undo option should be shown
  bool shouldShowUndoOption(SimplifiedMultiLevelQuote quote) {
    return _service.shouldShowUndoOption(quote);
  }

  /// Get accept button text
  String getAcceptButtonText(SimplifiedMultiLevelQuote quote) {
    return _service.getMarkAcceptedButtonText(quote);
  }

  /// Get undo button text
  String getUndoButtonText(SimplifiedMultiLevelQuote quote) {
    return _service.getUndoButtonText(quote);
  }

  /// Handle undo status change button tap
  Future<void> handleUndoStatusChange(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    final confirmed = await _showUndoConfirmationDialog(context, quote);
    if (confirmed) {
      await _undoStatusChange(quote);
    }
  }

  /// Undo status change
  Future<void> _undoStatusChange(SimplifiedMultiLevelQuote quote) async {
    _setProcessing(true);
    
    try {
      final result = await _service.undoStatusChange(
        quote: quote,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Show undo confirmation dialog
  Future<bool> _showUndoConfirmationDialog(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    if (!context.mounted) return false;

    final currentStatus = quote.status.toUpperCase();
    final undoText = getUndoButtonText(quote);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$undoText?'),
        content: Text(
          'Are you sure you want to undo the $currentStatus status? '
          'The quote will be returned to SENT status and can be accepted or declined again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(undoText),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Mark quote as complete
  Future<void> _markQuoteComplete(SimplifiedMultiLevelQuote quote) async {
    _setProcessing(true);
    
    try {
      final result = await _service.markQuoteComplete(
        quote: quote,
        appState: _appState,
      );
      
      if (result.isSuccess) {
        _setSuccess(result.successMessage);
      } else {
        _setError(result.errorMessage);
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Show complete confirmation dialog
  Future<bool> _showCompleteConfirmationDialog(
    BuildContext context,
    SimplifiedMultiLevelQuote quote,
  ) async {
    if (!context.mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Quote Complete?'),
        content: Text(
          'Are you sure you want to mark quote ${quote.quoteNumber} as complete? '
          'This indicates that the work has been finished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}