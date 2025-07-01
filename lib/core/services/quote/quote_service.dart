import 'dart:io';
import '../../../data/models/business/simplified_quote.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Result object for quote operations
class QuoteOperationResult {
  final bool isSuccess;
  final String? message;
  final SimplifiedMultiLevelQuote? quote;

  const QuoteOperationResult._({
    required this.isSuccess,
    this.message,
    this.quote,
  });

  factory QuoteOperationResult.success({
    String? message,
    SimplifiedMultiLevelQuote? quote,
  }) {
    return QuoteOperationResult._(
      isSuccess: true,
      message: message,
      quote: quote,
    );
  }

  factory QuoteOperationResult.error(String message) {
    return QuoteOperationResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Service layer for quote operations
/// Contains pure business logic without UI dependencies
class QuoteService {
  /// Update quote status
  Future<QuoteOperationResult> updateQuoteStatus({
    required SimplifiedMultiLevelQuote quote,
    required String newStatus,
    required AppStateProvider appState,
  }) async {
    try {
      final validStatuses = ['draft', 'pdf_generated', 'sent', 'accepted', 'declined', 'complete'];
      
      if (!validStatuses.contains(newStatus.toLowerCase())) {
        return QuoteOperationResult.error('Invalid status: $newStatus');
      }

      quote.status = newStatus.toLowerCase();
      quote.updatedAt = DateTime.now();
      
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Quote status updated to ${newStatus.toUpperCase()}',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to update quote status: $e');
    }
  }

  /// Delete quote
  Future<QuoteOperationResult> deleteQuote({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      await appState.deleteSimplifiedQuote(quote.id);
      
      return QuoteOperationResult.success(
        message: 'Quote ${quote.quoteNumber} deleted successfully',
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to delete quote: $e');
    }
  }

  /// Add discount to quote
  Future<QuoteOperationResult> addDiscount({
    required SimplifiedMultiLevelQuote quote,
    required dynamic discount, // QuoteDiscount type
    required AppStateProvider appState,
  }) async {
    try {
      quote.addDiscount(discount);
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Discount added successfully',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to add discount: $e');
    }
  }

  /// Remove discount from quote
  Future<QuoteOperationResult> removeDiscount({
    required SimplifiedMultiLevelQuote quote,
    required String discountId,
    required AppStateProvider appState,
  }) async {
    try {
      quote.removeDiscount(discountId);
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Discount removed successfully',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to remove discount: $e');
    }
  }

  /// Get available quote statuses
  List<String> getAvailableStatuses() {
    return ['draft', 'sent', 'accepted', 'declined'];
  }

  /// Get status display name
  String getStatusDisplayName(String status) {
    return status.toUpperCase();
  }

  /// Get next logical status
  String? getNextLogicalStatus(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'draft':
        return 'sent';
      case 'sent':
        return 'accepted';
      case 'accepted':
        return 'completed';
      default:
        return null;
    }
  }

  /// Validate quote for status update
  QuoteOperationResult validateQuoteForStatusUpdate(SimplifiedMultiLevelQuote quote) {
    if (quote.levels.isEmpty) {
      return QuoteOperationResult.error('Quote must have at least one level');
    }

    if (quote.quoteNumber.isEmpty) {
      return QuoteOperationResult.error('Quote must have a quote number');
    }

    return QuoteOperationResult.success(message: 'Quote is valid for status update');
  }

  /// Check if quote has a generated PDF
  bool hasPdfGenerated(SimplifiedMultiLevelQuote quote) {
    if (quote.pdfPath == null || quote.pdfPath!.isEmpty) {
      return false;
    }
    
    // Check if the file actually exists on disk
    final file = File(quote.pdfPath!);
    return file.existsSync();
  }

  /// Get PDF path for quote (if it exists)
  String? getPdfPath(SimplifiedMultiLevelQuote quote) {
    if (!hasPdfGenerated(quote)) {
      return null;
    }
    return quote.pdfPath;
  }

  /// Get status button text for quote
  String getStatusButtonText(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'draft':
        return 'Send PDF';
      case 'sent':
        return 'Mark Accepted';
      case 'accepted':
        return 'Mark Complete';
      default:
        return 'Update Status';
    }
  }

  /// Check if status button should be enabled
  bool isStatusButtonEnabled(SimplifiedMultiLevelQuote quote) {
    switch (quote.status.toLowerCase()) {
      case 'draft':
        // For draft status, button is only enabled if PDF exists
        return hasPdfGenerated(quote);
      default:
        // For other statuses, button is always enabled
        return true;
    }
  }

  /// Get disabled button tooltip
  String? getDisabledButtonTooltip(SimplifiedMultiLevelQuote quote) {
    if (quote.status.toLowerCase() == 'draft' && !hasPdfGenerated(quote)) {
      return 'Generate PDF first to send via email';
    }
    return null;
  }

  /// Mark quote as accepted (for single level quotes)
  Future<QuoteOperationResult> markQuoteAccepted({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      if (quote.levels.length == 1) {
        // Store current status as previous status for undo functionality
        quote.previousStatus = quote.status;
        quote.status = 'accepted';
        quote.updatedAt = DateTime.now();
        await appState.updateSimplifiedQuote(quote);
        
        return QuoteOperationResult.success(
          message: 'Quote marked as accepted',
          quote: quote,
        );
      } else {
        return QuoteOperationResult.error('Multi-level quotes require level selection');
      }
    } catch (e) {
      return QuoteOperationResult.error('Failed to mark quote as accepted: $e');
    }
  }

  /// Mark quote as declined
  Future<QuoteOperationResult> markQuoteDeclined({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      // Store current status as previous status for undo functionality
      quote.previousStatus = quote.status;
      quote.status = 'declined';
      quote.updatedAt = DateTime.now();
      
      // Note: QuoteLevel doesn't have status field, only the quote itself has status
      // Individual level status is handled by the quote's selectedLevelId
      // All non-selected levels are implicitly declined when quote status is 'declined'
      
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Quote marked as declined',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to mark quote as declined: $e');
    }
  }

  /// Mark specific level as accepted and others as declined (for multi-level quotes)
  Future<QuoteOperationResult> markLevelAccepted({
    required SimplifiedMultiLevelQuote quote,
    required String acceptedLevelId,
    required AppStateProvider appState,
  }) async {
    try {
      // Verify the level exists
      final levelExists = quote.levels.any((level) => level.id == acceptedLevelId);
      if (!levelExists) {
        return QuoteOperationResult.error('Level not found: $acceptedLevelId');
      }
      
      // Store current status as previous status for undo functionality
      quote.previousStatus = quote.status;
      
      // Update quote status and selection
      // The selectedLevelId indicates which level is accepted
      // All other levels are implicitly declined
      quote.status = 'accepted';
      quote.selectedLevelId = acceptedLevelId;
      quote.updatedAt = DateTime.now();
      
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Level accepted, others declined',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to mark level as accepted: $e');
    }
  }

  /// Update quote status to sent (when PDF is emailed)
  Future<QuoteOperationResult> markQuoteAsSent({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      final currentStatus = quote.status.toLowerCase();
      
      // Allow sending from both draft and pdf_generated states
      if (currentStatus == 'draft' || currentStatus == 'pdf_generated') {
        // Store current status as previous status for undo functionality
        quote.previousStatus = quote.status;
        quote.status = 'sent';
        quote.updatedAt = DateTime.now();
        await appState.updateSimplifiedQuote(quote);
        
        return QuoteOperationResult.success(
          message: 'Quote sent to customer successfully',
          quote: quote,
        );
      }
      
      return QuoteOperationResult.error(
        'Cannot send quote with status: ${quote.status.toUpperCase()}. Quote must be in DRAFT or PDF_GENERATED status.'
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to update quote status: $e');
    }
  }

  /// Check if quote is expired (business logic for expiration)
  bool isQuoteExpired(SimplifiedMultiLevelQuote quote) {
    if (quote.status.toLowerCase() == 'accepted' || quote.status.toLowerCase() == 'declined') {
      return false; // Completed quotes don't expire
    }
    
    // Check if quote is older than 30 days
    final now = DateTime.now();
    final daysDiff = now.difference(quote.createdAt).inDays;
    return daysDiff > 30;
  }

  /// Get quotes that should show as expired in UI
  List<SimplifiedMultiLevelQuote> getExpiredQuotes(List<SimplifiedMultiLevelQuote> quotes) {
    return quotes.where(isQuoteExpired).toList();
  }

  /// Validate if quote can be marked with new status
  QuoteOperationResult validateStatusTransition(SimplifiedMultiLevelQuote quote, String newStatus) {
    final currentStatus = quote.status.toLowerCase();
    final targetStatus = newStatus.toLowerCase();
    
    // Define valid transitions
    switch (currentStatus) {
      case 'draft':
        if (!['sent', 'accepted', 'declined'].contains(targetStatus)) {
          return QuoteOperationResult.error('Invalid transition from draft to $targetStatus');
        }
        break;
      case 'sent':
        if (!['accepted', 'declined'].contains(targetStatus)) {
          return QuoteOperationResult.error('Invalid transition from sent to $targetStatus');
        }
        break;
      case 'accepted':
      case 'declined':
        return QuoteOperationResult.error('Cannot change status of completed quote');
      default:
        return QuoteOperationResult.error('Unknown current status: $currentStatus');
    }
    
    return QuoteOperationResult.success(message: 'Status transition is valid');
  }

  /// Check if mark buttons should be shown for a quote
  bool shouldShowMarkButtons(SimplifiedMultiLevelQuote quote) {
    final status = quote.status.toLowerCase();
    return status == 'sent' || status == 'draft';
  }

  /// Check if undo option should be shown for a quote
  bool shouldShowUndoOption(SimplifiedMultiLevelQuote quote) {
    final status = quote.status.toLowerCase();
    final hasAcceptedOrDeclined = status == 'accepted' || status == 'declined';
    final hasPreviousStatus = quote.previousStatus != null && quote.previousStatus!.isNotEmpty;
    
    return hasAcceptedOrDeclined && hasPreviousStatus;
  }

  /// Get mark button text based on quote status
  String getMarkAcceptedButtonText(SimplifiedMultiLevelQuote quote) {
    if (quote.levels.length > 1) {
      return 'Select Level';
    }
    return 'Accept';
  }

  /// Undo status change - revert accepted or declined quote back to previous status
  Future<QuoteOperationResult> undoStatusChange({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      final currentStatus = quote.status.toLowerCase();
      
      // Only allow undoing accepted or declined status
      if (currentStatus != 'accepted' && currentStatus != 'declined') {
        return QuoteOperationResult.error('Cannot undo status: ${quote.status}');
      }
      
      // Check if we have a previous status to restore
      if (quote.previousStatus == null || quote.previousStatus!.isEmpty) {
        return QuoteOperationResult.error('No previous status found to restore');
      }
      
      // Store original status for success message
      final originalStatus = quote.status.toUpperCase();
      final previousStatus = quote.previousStatus!;
      
      // Revert to previous status
      quote.status = previousStatus;
      quote.previousStatus = null; // Clear previous status after undo
      quote.updatedAt = DateTime.now();
      
      // For multi-level quotes that were accepted, clear the selected level
      if (currentStatus == 'accepted' && quote.levels.length > 1) {
        quote.selectedLevelId = null;
      }
      
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: '$originalStatus status undone - quote returned to ${previousStatus.toUpperCase()}',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to undo status change: $e');
    }
  }

  /// Get undo button text based on current status
  String getUndoButtonText(SimplifiedMultiLevelQuote quote) {
    final status = quote.status.toLowerCase();
    switch (status) {
      case 'accepted':
        return 'Undo Accept';
      case 'declined':
        return 'Undo Decline';
      default:
        return 'Undo';
    }
  }

  /// Validate if undo operation is allowed
  QuoteOperationResult validateUndoOperation(SimplifiedMultiLevelQuote quote) {
    final status = quote.status.toLowerCase();
    
    if (status != 'accepted' && status != 'declined') {
      return QuoteOperationResult.error('Cannot undo status: ${quote.status}');
    }
    
    // Check if we have a previous status to restore
    if (quote.previousStatus == null || quote.previousStatus!.isEmpty) {
      return QuoteOperationResult.error('No previous status found to restore');
    }
    
    // Check if quote is too old to undo (optional business rule)
    final daysSinceUpdate = DateTime.now().difference(quote.updatedAt).inDays;
    if (daysSinceUpdate > 30) {
      return QuoteOperationResult.error('Cannot undo status changes older than 30 days');
    }
    
    return QuoteOperationResult.success(message: 'Undo operation is valid');
  }

  /// Mark quote as complete
  Future<QuoteOperationResult> markQuoteComplete({
    required SimplifiedMultiLevelQuote quote,
    required AppStateProvider appState,
  }) async {
    try {
      // Validate that quote can be marked complete
      if (quote.status.toLowerCase() != 'accepted') {
        return QuoteOperationResult.error(
          'Only accepted quotes can be marked as complete'
        );
      }

      quote.previousStatus = quote.status;
      quote.status = 'complete';
      quote.updatedAt = DateTime.now();
      
      await appState.updateSimplifiedQuote(quote);
      
      return QuoteOperationResult.success(
        message: 'Quote ${quote.quoteNumber} marked as complete',
        quote: quote,
      );
    } catch (e) {
      return QuoteOperationResult.error('Failed to mark quote as complete: $e');
    }
  }
}