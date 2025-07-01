import '../../../data/providers/state/app_state_provider.dart';
import '../../../data/models/media/inspection_document.dart';

/// Service that contains inspection viewer business operations
/// This is extracted from InspectionViewerController following the same pattern
class InspectionViewerService {
  
  /// EXACT COPY of the document loading logic from the controller
  /// This is the ORIGINAL working code, just moved to a service
  static List<InspectionDocument> loadInspectionDocuments({
    required AppStateProvider appState,
    required String customerId,
  }) {
    // EXACT COPY of lines 31-32 from InspectionViewerController._loadDocuments()
    final documents = appState.getInspectionDocumentsForCustomer(customerId)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return documents;
  }
}