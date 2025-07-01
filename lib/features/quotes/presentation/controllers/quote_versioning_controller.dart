import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/quote_edit_history.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/quote/quote_versioning_service.dart';

/// Controller for managing quote versioning UI state
/// Follows clean architecture - no business logic, only UI coordination
class QuoteVersioningController extends ChangeNotifier {
  final BuildContext context;
  final QuoteVersioningService _versioningService;
  final AppStateProvider _appState;

  // UI State
  bool _isCreatingVersion = false;
  bool _isLoadingVersions = false;
  bool _isLoadingHistory = false;
  String? _lastError;
  String? _lastSuccess;

  // Version Data
  List<SimplifiedMultiLevelQuote> _versions = [];
  List<QuoteEditHistory> _editHistory = [];
  SimplifiedMultiLevelQuote? _currentQuote;

  // Edit Reason State
  QuoteEditReason? _selectedEditReason;
  String? _editDescription;

  QuoteVersioningController({
    required this.context,
    required QuoteVersioningService versioningService,
    required AppStateProvider appState,
  }) : _versioningService = versioningService,
       _appState = appState;

  /// Factory constructor to create from context (follows existing pattern)
  factory QuoteVersioningController.fromContext(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final versioningService = QuoteVersioningService();
    
    return QuoteVersioningController(
      context: context,
      versioningService: versioningService,
      appState: appState,
    );
  }

  // Getters for UI state
  bool get isCreatingVersion => _isCreatingVersion;
  bool get isLoadingVersions => _isLoadingVersions;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoading => _isCreatingVersion || _isLoadingVersions || _isLoadingHistory;
  String? get lastError => _lastError;
  String? get lastSuccess => _lastSuccess;

  // Getters for version data
  List<SimplifiedMultiLevelQuote> get versions => List.unmodifiable(_versions);
  List<QuoteEditHistory> get editHistory => List.unmodifiable(_editHistory);
  SimplifiedMultiLevelQuote? get currentQuote => _currentQuote;

  // Getters for edit reason state
  QuoteEditReason? get selectedEditReason => _selectedEditReason;
  String? get editDescription => _editDescription;
  bool get canCreateVersion => _selectedEditReason != null;

  /// Set the current quote being managed
  void setCurrentQuote(SimplifiedMultiLevelQuote quote) {
    _currentQuote = quote;
    notifyListeners();
  }

  /// Set edit reason for version creation
  void setEditReason(QuoteEditReason reason) {
    _selectedEditReason = reason;
    notifyListeners();
  }

  /// Set edit description
  void setEditDescription(String? description) {
    _editDescription = description;
    notifyListeners();
  }

  /// Clear edit reason state
  void clearEditReason() {
    _selectedEditReason = null;
    _editDescription = null;
    notifyListeners();
  }

  /// Clear error and success messages
  void clearMessages() {
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();
  }

  /// Create a new version of the current quote
  Future<SimplifiedMultiLevelQuote?> createNewVersion({
    required SimplifiedMultiLevelQuote originalQuote,
    QuoteEditReason? reason,
    String? description,
  }) async {
    if (_isCreatingVersion) return null;

    final editReason = reason ?? _selectedEditReason;
    if (editReason == null) {
      _lastError = 'Edit reason is required';
      notifyListeners();
      return null;
    }

    _isCreatingVersion = true;
    _lastError = null;
    _lastSuccess = null;
    notifyListeners();

    try {
      final result = await _versioningService.createNewVersion(
        originalQuote,
        editReason,
        description ?? _editDescription,
      );

      if (result.isSuccess && result.newQuote != null) {
        _lastSuccess = result.successMessage;
        _currentQuote = result.newQuote;
        
        // Update app state with new version (proper architectural separation)
        await _appState.addSimplifiedQuote(result.newQuote!);
        
        // Update in-memory app state to match database (service handles DB updates)
        // Note: Don't call updateSimplifiedQuote as it triggers destructive repository.updateQuote()
        final wasFirstVersion = originalQuote.parentQuoteId == null;
        if (wasFirstVersion) {
          originalQuote.parentQuoteId = originalQuote.id;
          // In-memory update only - service already updated database correctly
        }
        
        // Clear edit reason state after successful creation
        clearEditReason();
        
        // Refresh versions list
        await loadVersions(result.newQuote!.parentQuoteId ?? result.newQuote!.id);
        
        return result.newQuote;
      } else {
        _lastError = result.errorMessage;
        return null;
      }
    } catch (e) {
      _lastError = 'Failed to create new version: $e';
      return null;
    } finally {
      _isCreatingVersion = false;
      notifyListeners();
    }
  }

  /// Load all versions of a quote family
  Future<void> loadVersions(String parentQuoteId) async {
    if (_isLoadingVersions) return;

    print('📚 QuoteVersioningController: Loading versions for parent ID: $parentQuoteId');
    _isLoadingVersions = true;
    _lastError = null;
    notifyListeners();

    try {
      _versions = await _versioningService.getQuoteVersions(parentQuoteId);
      print('📚 Loaded ${_versions.length} versions');
      for (final version in _versions) {
        print('📚 Version ${version.version}: ${version.id} (current: ${version.isCurrentVersion})');
      }
      
      // Update current quote if it's not set or no longer current
      if (_currentQuote == null || !_currentQuote!.isCurrentVersion) {
        _currentQuote = _versioningService.getCurrentVersion(_versions);
        print('📚 Set current quote to: ${_currentQuote?.id} v${_currentQuote?.version}');
      }
    } catch (e) {
      print('❌ Failed to load versions: $e');
      _lastError = 'Failed to load versions: $e';
      _versions = [];
    } finally {
      _isLoadingVersions = false;
      notifyListeners();
    }
  }

  /// Load edit history for a quote family
  Future<void> loadEditHistory(String parentQuoteId) async {
    if (_isLoadingHistory) return;

    print('📜 QuoteVersioningController: Loading edit history for parent ID: $parentQuoteId');
    _isLoadingHistory = true;
    _lastError = null;
    notifyListeners();

    try {
      _editHistory = await _versioningService.getEditHistory(parentQuoteId);
      print('📜 Loaded ${_editHistory.length} edit history entries');
      for (final entry in _editHistory) {
        print('📜 Edit: ${entry.editReason.displayName} v${entry.version} - ${entry.displayText}');
      }
    } catch (e) {
      print('❌ Failed to load edit history: $e');
      _lastError = 'Failed to load edit history: $e';
      _editHistory = [];
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Check if a quote has significant changes that warrant versioning
  bool hasSignificantChanges(
    SimplifiedMultiLevelQuote originalQuote,
    SimplifiedMultiLevelQuote modifiedQuote,
  ) {
    return _versioningService.shouldCreateNewVersion(originalQuote, modifiedQuote);
  }

  /// Get versioned quote number for display
  String getVersionedQuoteNumber(SimplifiedMultiLevelQuote quote) {
    return _versioningService.getVersionedQuoteNumber(quote.quoteNumber, quote.version);
  }

  /// Check if a quote can be edited
  bool canEditQuote(SimplifiedMultiLevelQuote quote) {
    return _versioningService.canEditQuote(quote);
  }

  /// Get the highest version number in the current versions list
  int get highestVersion {
    if (_versions.isEmpty) return 1;
    return _versions.map((v) => v.version).reduce((a, b) => a > b ? a : b);
  }

  /// Get version by version number
  SimplifiedMultiLevelQuote? getVersionByNumber(int versionNumber) {
    try {
      return _versions.firstWhere((quote) => quote.version == versionNumber);
    } catch (e) {
      return null;
    }
  }

  /// Switch to a specific version (for viewing/navigation)
  void switchToVersion(SimplifiedMultiLevelQuote version) {
    _currentQuote = version;
    notifyListeners();
  }

  /// Get summary of changes for UI display
  Map<String, dynamic> getChangesSummary(
    SimplifiedMultiLevelQuote originalQuote,
    SimplifiedMultiLevelQuote modifiedQuote,
  ) {
    return _versioningService.generateChangesSummary(originalQuote, modifiedQuote);
  }

}