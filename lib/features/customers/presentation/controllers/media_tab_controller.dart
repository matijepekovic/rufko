import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/media/project_media.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/media/media_file_service.dart';

enum MediaFilter { 
  all, 
  photos, 
  documents,
  // Category filters
  beforePhotos,
  afterPhotos,
  inspectionPhotos,
  progressPhotos,
  damageReport,
  otherPhotos,
  contracts,
  invoices,
  permits,
  insuranceDocs,
  roofScopeReports,
  general,
}

class MediaTabController extends ChangeNotifier {
  final Customer customer;
  final BuildContext? context;
  
  MediaTabController({required this.customer, this.context});

  // Filter state
  MediaFilter _activeFilter = MediaFilter.all;
  MediaFilter get activeFilter => _activeFilter;

  // Selection state
  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  final Set<String> _selectedMediaIds = {};
  Set<String> get selectedMediaIds => Set.from(_selectedMediaIds);

  // Processing state
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // Filter methods
  void setFilter(MediaFilter filter) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      _selectedMediaIds.clear(); // Clear selection when changing filter
      notifyListeners();
    }
  }

  // Selection methods
  void enterSelectionMode() {
    _isSelectionMode = true;
    _selectedMediaIds.clear();
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedMediaIds.clear();
    notifyListeners();
  }

  void toggleSelection(String mediaId) {
    if (_selectedMediaIds.contains(mediaId)) {
      _selectedMediaIds.remove(mediaId);
    } else {
      _selectedMediaIds.add(mediaId);
    }
    notifyListeners();
  }

  void selectAll(List<ProjectMedia> filteredItems) {
    _selectedMediaIds.clear();
    _selectedMediaIds.addAll(filteredItems.map((item) => item.id));
    notifyListeners();
  }

  void deselectAll() {
    _selectedMediaIds.clear();
    notifyListeners();
  }

  bool get hasSelection => _selectedMediaIds.isNotEmpty;
  bool get isAllSelected => _selectedMediaIds.isNotEmpty;

  // Get filtered media items
  List<ProjectMedia> getFilteredMedia(List<ProjectMedia> allMedia) {
    switch (_activeFilter) {
      case MediaFilter.photos:
        return allMedia.where((item) => item.isImage).toList();
      case MediaFilter.documents:
        return allMedia.where((item) => !item.isImage).toList();
      case MediaFilter.all:
        return allMedia;
      // Category filters
      case MediaFilter.beforePhotos:
        return allMedia.where((item) => item.category == 'before_photos').toList();
      case MediaFilter.afterPhotos:
        return allMedia.where((item) => item.category == 'after_photos').toList();
      case MediaFilter.inspectionPhotos:
        return allMedia.where((item) => item.category == 'inspection_photos').toList();
      case MediaFilter.progressPhotos:
        return allMedia.where((item) => item.category == 'progress_photos').toList();
      case MediaFilter.damageReport:
        return allMedia.where((item) => item.category == 'damage_report').toList();
      case MediaFilter.otherPhotos:
        return allMedia.where((item) => item.category == 'other_photos').toList();
      case MediaFilter.contracts:
        return allMedia.where((item) => item.category == 'contracts').toList();
      case MediaFilter.invoices:
        return allMedia.where((item) => item.category == 'invoices').toList();
      case MediaFilter.permits:
        return allMedia.where((item) => item.category == 'permits').toList();
      case MediaFilter.insuranceDocs:
        return allMedia.where((item) => item.category == 'insurance_docs').toList();
      case MediaFilter.roofScopeReports:
        return allMedia.where((item) => item.category == 'roofscope_reports').toList();
      case MediaFilter.general:
        return allMedia.where((item) => item.category == 'general').toList();
    }
  }

  // Get photos organized by categories
  Map<String, List<ProjectMedia>> getPhotosByCategory(List<ProjectMedia> photos) {
    final photoCategories = <String, List<ProjectMedia>>{
      'before_photos': [],
      'after_photos': [],
      'inspection_photos': [],
      'progress_photos': [],
      'damage_report': [],
      'other_photos': [],
    };

    for (final photo in photos) {
      if (photoCategories.containsKey(photo.category)) {
        photoCategories[photo.category]!.add(photo);
      } else {
        photoCategories['other_photos']!.add(photo);
      }
    }

    // Remove empty categories
    photoCategories.removeWhere((key, value) => value.isEmpty);
    return photoCategories;
  }

  // Get counts for filter chips
  int getTotalCount(List<ProjectMedia> allMedia) => allMedia.length;
  
  // Helper methods for category filtering
  bool get isBasicFilter => [MediaFilter.all, MediaFilter.photos, MediaFilter.documents].contains(_activeFilter);
  bool get isCategoryFilter => !isBasicFilter;
  
  // Get all available categories from media
  List<String> getAvailableCategories(List<ProjectMedia> allMedia) {
    final categories = allMedia.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  // Get count for specific category
  int getCategoryCount(List<ProjectMedia> allMedia, String category) {
    return allMedia.where((item) => item.category == category).length;
  }
  
  // Get count for MediaFilter
  int getFilterCount(List<ProjectMedia> allMedia, MediaFilter filter) {
    return getFilteredMedia(allMedia).length;
  }
  
  // Convert category string to MediaFilter
  static MediaFilter? categoryToFilter(String category) {
    switch (category) {
      case 'before_photos':
        return MediaFilter.beforePhotos;
      case 'after_photos':
        return MediaFilter.afterPhotos;
      case 'inspection_photos':
        return MediaFilter.inspectionPhotos;
      case 'progress_photos':
        return MediaFilter.progressPhotos;
      case 'damage_report':
        return MediaFilter.damageReport;
      case 'other_photos':
        return MediaFilter.otherPhotos;
      case 'contracts':
        return MediaFilter.contracts;
      case 'invoices':
        return MediaFilter.invoices;
      case 'permits':
        return MediaFilter.permits;
      case 'insurance_docs':
        return MediaFilter.insuranceDocs;
      case 'roofscope_reports':
        return MediaFilter.roofScopeReports;
      case 'general':
        return MediaFilter.general;
      default:
        return null;
    }
  }
  
  // Convert MediaFilter to category string
  static String? filterToCategory(MediaFilter filter) {
    switch (filter) {
      case MediaFilter.beforePhotos:
        return 'before_photos';
      case MediaFilter.afterPhotos:
        return 'after_photos';
      case MediaFilter.inspectionPhotos:
        return 'inspection_photos';
      case MediaFilter.progressPhotos:
        return 'progress_photos';
      case MediaFilter.damageReport:
        return 'damage_report';
      case MediaFilter.otherPhotos:
        return 'other_photos';
      case MediaFilter.contracts:
        return 'contracts';
      case MediaFilter.invoices:
        return 'invoices';
      case MediaFilter.permits:
        return 'permits';
      case MediaFilter.insuranceDocs:
        return 'insurance_docs';
      case MediaFilter.roofScopeReports:
        return 'roofscope_reports';
      case MediaFilter.general:
        return 'general';
      default:
        return null;
    }
  }
  int getPhotosCount(List<ProjectMedia> allMedia) => 
      allMedia.where((item) => item.isImage).length;
  int getDocumentsCount(List<ProjectMedia> allMedia) => 
      allMedia.where((item) => !item.isImage).length;

  // Media operations
  Future<void> deleteSelectedMedia() async {
    if (_selectedMediaIds.isEmpty || context == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final appState = context!.read<AppStateProvider>();
      final allMedia = appState.getProjectMediaForCustomer(customer.id);
      final itemsToDelete = allMedia.where((m) => _selectedMediaIds.contains(m.id)).toList();
      
      int successCount = 0;
      int totalCount = itemsToDelete.length;
      
      for (final mediaItem in itemsToDelete) {
        try {
          final result = await MediaFileService.deleteMedia(
            mediaItem: mediaItem,
            appState: appState,
          );
          
          if (result.isSuccess) {
            successCount++;
          }
        } catch (e) {
          debugPrint('Error deleting media ${mediaItem.fileName}: $e');
        }
      }
      
      // Clear selection and exit selection mode
      _selectedMediaIds.clear();
      _isSelectionMode = false;
      
      // Show feedback to user
      if (context!.mounted) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text(successCount == totalCount 
              ? 'Deleted $successCount file${successCount == 1 ? '' : 's'}'
              : 'Deleted $successCount of $totalCount files'),
            backgroundColor: successCount == totalCount ? Colors.red : Colors.orange,
          ),
        );
      }
      
      debugPrint('🗑️ Deleted $successCount of $totalCount selected media items');
    } catch (e) {
      debugPrint('Error in deleteSelectedMedia: $e');
      if (context!.mounted) {
        ScaffoldMessenger.of(context!).showSnackBar(
          SnackBar(
            content: Text('Error deleting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Callback handlers for media operations
  void handleTakePhoto() {
    // TODO: Implement camera functionality
  }

  void handleUpload() {
    // TODO: Implement upload functionality
  }

  void handleViewMedia(ProjectMedia media) {
    if (_isSelectionMode) {
      toggleSelection(media.id);
    } else {
      // TODO: Implement view media functionality
    }
  }

  void handleContextMenu(ProjectMedia media) {
    if (!_isSelectionMode) {
      // TODO: Implement context menu functionality
    }
  }
}