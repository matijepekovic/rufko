import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/models/media/inspection_document.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for the inspection viewer screen to load documents and handle navigation.
class InspectionViewerController extends ChangeNotifier {
  InspectionViewerController({
    required this.context,
    required this.customer,
    required int initialIndex,
  })  : pageController = PageController(initialPage: initialIndex),
        _currentPage = initialIndex {
    _loadDocuments();
  }

  final BuildContext context;
  final Customer customer;
  final PageController pageController;

  List<InspectionDocument> _documents = [];
  int _currentPage;

  List<InspectionDocument> get documents => _documents;
  int get currentPage => _currentPage;

  void _loadDocuments() {
    final appState = context.read<AppStateProvider>();
    _documents = appState.getInspectionDocumentsForCustomer(customer.id)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void updateCurrentPage(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void goToPreviousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToNextPage() {
    if (_currentPage < _documents.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPage(int index) {
    if (index >= 0 && index < _documents.length) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
