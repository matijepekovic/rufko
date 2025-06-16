import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/communication/communication_service.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// UI Controller for communication features that follows clean architecture
/// Separates business logic from UI concerns using service layer and event emission
class CommunicationUIController extends ChangeNotifier {
  CommunicationUIController({
    required this.customer,
    this.onCustomerUpdated,
  }) : _communicationService = const CommunicationService();

  final Customer customer;
  final VoidCallback? onCustomerUpdated;
  final CommunicationService _communicationService;

  // UI state
  bool _isLoading = false;
  String? _lastError;
  String? _lastSuccess;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;

  /// Clear messages
  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  /// Get customer data map for template processing
  Map<String, String> getCustomerDataMap(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    return _communicationService.buildCustomerDataMap(
      customer: customer,
      appState: appState,
    );
  }

  /// Send SMS using template - emits UI events instead of handling them directly
  Future<void> sendTemplateSMS({
    required BuildContext context,
    required dynamic template,
    required String message,
  }) async {
    _setLoading(true);
    clearMessages();

    try {
      final appState = context.read<AppStateProvider>();
      final result = await _communicationService.sendTemplateSMS(
        customer: customer,
        template: template,
        message: message,
        appState: appState,
      );

      if (result.isSuccess) {
        _setSuccess('SMS sent successfully');
        onCustomerUpdated?.call();
      } else {
        _setError(_getErrorMessage(result.errorMessage!));
      }
    } catch (e) {
      _setError('Failed to send SMS: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send email using template - emits UI events instead of handling them directly
  Future<void> sendTemplateEmail({
    required BuildContext context,
    required dynamic template,
    required String subject,
    required String content,
  }) async {
    _setLoading(true);
    clearMessages();

    try {
      final appState = context.read<AppStateProvider>();
      final result = await _communicationService.sendTemplateEmail(
        customer: customer,
        template: template,
        subject: subject,
        content: content,
        appState: appState,
      );

      if (result.isSuccess) {
        _setSuccess('Email sent successfully');
        onCustomerUpdated?.call();
      } else {
        _setError(_getErrorMessage(result.errorMessage!));
      }
    } catch (e) {
      _setError('Failed to send email: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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

  String _getErrorMessage(String errorType) {
    switch (errorType) {
      case 'No phone number':
        return 'Customer has no phone number. Communication logged only.';
      case 'No email address':
        return 'Customer has no email address. Communication logged only.';
      default:
        return errorType;
    }
  }
}