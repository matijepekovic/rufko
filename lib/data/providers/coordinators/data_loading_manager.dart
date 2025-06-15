import 'package:flutter/foundation.dart';
import 'business_domain_coordinator.dart';
import 'content_domain_coordinator.dart';

class DataLoadingManager extends ChangeNotifier {
  final BusinessDomainCoordinator businessCoordinator;
  final ContentDomainCoordinator contentCoordinator;

  bool _isLoading = false;
  String _loadingMessage = '';

  DataLoadingManager({
    required this.businessCoordinator,
    required this.contentCoordinator,
  }) {
    businessCoordinator.addListener(notifyListeners);
    contentCoordinator.addListener(notifyListeners);
  }

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void setLoading(bool loading, [String message = '']) {
    if (_isLoading == loading && _loadingMessage == message) return;
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  Future<void> loadAllData() async {
    setLoading(true, 'Loading data...');
    try {
      await Future.wait([
        businessCoordinator.loadBusinessData(),
        contentCoordinator.loadContentData(),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading all data: $e');
    } finally {
      setLoading(false);
    }
  }

  // Individual load methods for granular control
  Future<void> loadSimplifiedQuotes() async {
    await businessCoordinator.loadQuotes();
  }

  Future<void> loadProjectMedia() async {
    await contentCoordinator.mediaState.loadProjectMedia();
  }

  // Import operations with loading states
  Future<void> importProducts(List<dynamic> products) async {
    setLoading(true, 'Importing products...');
    try {
      await businessCoordinator.importProducts(products.cast());
    } finally {
      setLoading(false);
    }
  }

  Future<void> addTemplateFields(List<dynamic> templateFields) async {
    setLoading(true, 'Adding template fields...');
    try {
      await contentCoordinator.addTemplateFields(templateFields.cast());
    } finally {
      setLoading(false);
    }
  }

  Future<void> importCustomAppData(Map<String, dynamic> data) async {
    setLoading(true, 'Importing custom app data...');
    try {
      await contentCoordinator.importCustomAppData(data);
    } finally {
      setLoading(false);
    }
  }

  // Search operations that span multiple domains
  Map<String, List> performGlobalSearch(String query) {
    return {
      'customers': businessCoordinator.searchCustomers(query),
      'products': businessCoordinator.searchProducts(query),
      'quotes': businessCoordinator.searchSimplifiedQuotes(query),
      'messageTemplates': contentCoordinator.searchMessageTemplates(query),
      'emailTemplates': contentCoordinator.searchEmailTemplates(query),
    };
  }

  // Dashboard statistics aggregation
  Map<String, dynamic> getDashboardStats() {
    final businessStats = businessCoordinator.getBusinessStats();
    return {
      ...businessStats,
      'totalTemplates': {
        'pdf': contentCoordinator.pdfTemplates.length,
        'message': contentCoordinator.messageTemplates.length,
        'email': contentCoordinator.emailTemplates.length,
      },
      'totalMedia': contentCoordinator.projectMedia.length,
      'customFields': contentCoordinator.customAppDataFields.length,
    };
  }
}