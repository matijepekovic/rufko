import 'package:flutter/foundation.dart';

import '../../models/media/project_media.dart';
import '../../../core/services/database/database_service.dart';
import '../helpers/data_loading_helper.dart';

/// Provider responsible for managing [ProjectMedia] records and related
/// file operations. Extracted from `AppStateProvider` to keep media logic
/// isolated.
class MediaStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<ProjectMedia> _projectMedia = [];

  MediaStateProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<ProjectMedia> get projectMedia => _projectMedia;

  /// Loads all media from the database.
  Future<void> loadProjectMedia() async {
    _projectMedia = await DataLoadingHelper.loadProjectMedia(_db);
    notifyListeners();
  }

  /// Adds a new media item and persists it.
  Future<void> addProjectMedia(ProjectMedia media) async {
    await _db.saveProjectMedia(media);
    _projectMedia.add(media);
    notifyListeners();
  }

  /// Updates an existing media item.
  Future<void> updateProjectMedia(ProjectMedia media) async {
    await _db.saveProjectMedia(media);
    final index = _projectMedia.indexWhere((m) => m.id == media.id);
    if (index != -1) _projectMedia[index] = media;
    notifyListeners();
  }

  /// Deletes a media item by [mediaId].
  Future<void> deleteProjectMedia(String mediaId) async {
    await _db.deleteProjectMedia(mediaId);
    _projectMedia.removeWhere((m) => m.id == mediaId);
    notifyListeners();
  }

  /// Returns media belonging to the given [customerId].
  List<ProjectMedia> getProjectMediaForCustomer(String customerId) {
    return _projectMedia.where((m) => m.customerId == customerId).toList();
  }

  /// Returns media associated with the specified [quoteId].
  List<ProjectMedia> getProjectMediaForQuote(String quoteId) {
    return _projectMedia.where((m) => m.quoteId == quoteId).toList();
  }
}
