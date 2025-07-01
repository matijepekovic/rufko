import '../../../data/models/business/simplified_quote.dart';
import '../../../data/models/business/quote_edit_history.dart';
import '../../../data/models/business/quote.dart'; // For QuoteItem
import '../../../data/models/business/quote_extras.dart'; // For PermitItem, CustomLineItem
import '../../../data/repositories/quote_repository.dart';
import 'package:uuid/uuid.dart';

/// Result object for quote versioning operations
class QuoteVersionResult {
  final bool isSuccess;
  final String? message;
  final SimplifiedMultiLevelQuote? newQuote;
  final QuoteEditHistory? editHistory;

  const QuoteVersionResult._({
    required this.isSuccess,
    this.message,
    this.newQuote,
    this.editHistory,
  });

  factory QuoteVersionResult.success({
    String? message,
    SimplifiedMultiLevelQuote? newQuote,
    QuoteEditHistory? editHistory,
  }) {
    return QuoteVersionResult._(
      isSuccess: true,
      message: message,
      newQuote: newQuote,
      editHistory: editHistory,
    );
  }

  factory QuoteVersionResult.error(String message) {
    return QuoteVersionResult._(
      isSuccess: false,
      message: message,
    );
  }

  String get errorMessage => message ?? 'Unknown error occurred';
  String get successMessage => message ?? 'Operation completed successfully';
}

/// Pure business logic service for quote versioning
/// Contains no UI dependencies - only business rules and data operations
class QuoteVersioningService {
  final QuoteRepository _repository = QuoteRepository();
  
  /// Determine if changes to a quote warrant creating a new version
  /// Business rule: ANY change to quote data creates new version
  bool shouldCreateNewVersion(
    SimplifiedMultiLevelQuote originalQuote,
    SimplifiedMultiLevelQuote modifiedQuote,
  ) {
    print('🔍 QuoteVersioningService: Checking for ANY changes...');
    
    // Price changes
    print('🔍 Tax rate check: ${originalQuote.taxRate} vs ${modifiedQuote.taxRate}');
    if (originalQuote.taxRate != modifiedQuote.taxRate) {
      print('✅ Tax rate changed!');
      return true;
    }
    
    print('🔍 Discount check: ${originalQuote.discount} vs ${modifiedQuote.discount}');
    if (originalQuote.discount != modifiedQuote.discount) {
      print('✅ Discount changed!');
      return true;
    }
    
    // Main product changes
    print('🔍 Base product ID check: ${originalQuote.baseProductId} vs ${modifiedQuote.baseProductId}');
    if (originalQuote.baseProductId != modifiedQuote.baseProductId) {
      print('✅ Base product changed!');
      return true;
    }
    
    print('🔍 Base product name check: ${originalQuote.baseProductName} vs ${modifiedQuote.baseProductName}');
    if (originalQuote.baseProductName != modifiedQuote.baseProductName) {
      print('✅ Base product name changed!');
      return true;
    }
    
    // Level changes (count, names, prices, quantities, subtotals)
    print('🔍 Level count check: ${originalQuote.levels.length} vs ${modifiedQuote.levels.length}');
    if (originalQuote.levels.length != modifiedQuote.levels.length) {
      print('✅ Level count changed!');
      return true;
    }
    
    for (int i = 0; i < originalQuote.levels.length; i++) {
      final originalLevel = originalQuote.levels[i];
      final modifiedLevel = modifiedQuote.levels[i];
      
      print('🔍 Level $i: ${originalLevel.name}(${originalLevel.basePrice}x${originalLevel.baseQuantity}=${originalLevel.subtotal}) vs ${modifiedLevel.name}(${modifiedLevel.basePrice}x${modifiedLevel.baseQuantity}=${modifiedLevel.subtotal})');
      
      if (originalLevel.name != modifiedLevel.name ||
          originalLevel.basePrice != modifiedLevel.basePrice ||
          originalLevel.baseQuantity != modifiedLevel.baseQuantity ||
          originalLevel.subtotal != modifiedLevel.subtotal ||
          originalLevel.includedItems.length != modifiedLevel.includedItems.length) {
        print('✅ Level $i changed! Name: ${originalLevel.name != modifiedLevel.name}, Price: ${originalLevel.basePrice != modifiedLevel.basePrice}, Qty: ${originalLevel.baseQuantity != modifiedLevel.baseQuantity}, Subtotal: ${originalLevel.subtotal != modifiedLevel.subtotal}, Items: ${originalLevel.includedItems.length != modifiedLevel.includedItems.length}');
        return true;
      }
      
      // Check individual level items
      for (int j = 0; j < originalLevel.includedItems.length; j++) {
        final originalItem = originalLevel.includedItems[j];
        final modifiedItem = modifiedLevel.includedItems[j];
        
        if (originalItem.productId != modifiedItem.productId ||
            originalItem.unitPrice != modifiedItem.unitPrice ||
            originalItem.quantity != modifiedItem.quantity) {
          print('✅ Level $i item $j changed!');
          return true;
        }
      }
    }
    
    // Add-on changes
    print('🔍 Addon count check: ${originalQuote.addons.length} vs ${modifiedQuote.addons.length}');
    if (originalQuote.addons.length != modifiedQuote.addons.length) {
      print('✅ Addon count changed!');
      return true;
    }
    
    for (int i = 0; i < originalQuote.addons.length; i++) {
      final originalAddon = originalQuote.addons[i];
      final modifiedAddon = modifiedQuote.addons[i];
      
      print('🔍 Addon $i: ${originalAddon.productName}(${originalAddon.unitPrice}x${originalAddon.quantity}) vs ${modifiedAddon.productName}(${modifiedAddon.unitPrice}x${modifiedAddon.quantity})');
      
      if (originalAddon.productId != modifiedAddon.productId ||
          originalAddon.productName != modifiedAddon.productName ||
          originalAddon.unitPrice != modifiedAddon.unitPrice ||
          originalAddon.quantity != modifiedAddon.quantity) {
        print('✅ Addon $i changed!');
        return true;
      }
    }
    
    // Discount changes
    print('🔍 Discount list count check: ${originalQuote.discounts.length} vs ${modifiedQuote.discounts.length}');
    if (originalQuote.discounts.length != modifiedQuote.discounts.length) {
      print('✅ Discount list count changed!');
      return true;
    }
    
    for (int i = 0; i < originalQuote.discounts.length; i++) {
      final originalDiscount = originalQuote.discounts[i];
      final modifiedDiscount = modifiedQuote.discounts[i];
      
      print('🔍 Discount $i: ${originalDiscount.type}(${originalDiscount.value}) vs ${modifiedDiscount.type}(${modifiedDiscount.value})');
      
      if (originalDiscount.value != modifiedDiscount.value ||
          originalDiscount.type != modifiedDiscount.type ||
          originalDiscount.code != modifiedDiscount.code ||
          originalDiscount.description != modifiedDiscount.description ||
          originalDiscount.applyToAddons != modifiedDiscount.applyToAddons ||
          originalDiscount.isActive != modifiedDiscount.isActive) {
        print('✅ Discount $i changed!');
        return true;
      }
    }
    
    // Permit changes
    print('🔍 Permit count check: ${originalQuote.permits.length} vs ${modifiedQuote.permits.length}');
    if (originalQuote.permits.length != modifiedQuote.permits.length) {
      print('✅ Permit count changed!');
      return true;
    }
    
    print('🔍 No permits required check: ${originalQuote.noPermitsRequired} vs ${modifiedQuote.noPermitsRequired}');
    if (originalQuote.noPermitsRequired != modifiedQuote.noPermitsRequired) {
      print('✅ No permits required flag changed!');
      return true;
    }
    
    for (int i = 0; i < originalQuote.permits.length; i++) {
      final originalPermit = originalQuote.permits[i];
      final modifiedPermit = modifiedQuote.permits[i];
      
      if (originalPermit.name != modifiedPermit.name ||
          originalPermit.amount != modifiedPermit.amount ||
          originalPermit.isRequired != modifiedPermit.isRequired) {
        print('✅ Permit $i changed!');
        return true;
      }
    }
    
    // Custom line item changes
    print('🔍 Custom line item count check: ${originalQuote.customLineItems.length} vs ${modifiedQuote.customLineItems.length}');
    if (originalQuote.customLineItems.length != modifiedQuote.customLineItems.length) {
      print('✅ Custom line item count changed!');
      return true;
    }
    
    for (int i = 0; i < originalQuote.customLineItems.length; i++) {
      final originalItem = originalQuote.customLineItems[i];
      final modifiedItem = modifiedQuote.customLineItems[i];
      
      if (originalItem.name != modifiedItem.name ||
          originalItem.amount != modifiedItem.amount ||
          originalItem.isTaxable != modifiedItem.isTaxable) {
        print('✅ Custom line item $i changed!');
        return true;
      }
    }
    
    // Notes changes
    print('🔍 Notes check: "${originalQuote.notes}" vs "${modifiedQuote.notes}"');
    if (originalQuote.notes != modifiedQuote.notes) {
      print('✅ Notes changed!');
      return true;
    }
    
    print('❌ No changes found');
    return false;
  }

  /// Generate a summary of changes between two quotes
  Map<String, dynamic> generateChangesSummary(
    SimplifiedMultiLevelQuote originalQuote,
    SimplifiedMultiLevelQuote modifiedQuote,
  ) {
    final changes = <String, dynamic>{};
    
    // Price changes
    final originalTotal = _calculateQuoteTotal(originalQuote);
    final modifiedTotal = _calculateQuoteTotal(modifiedQuote);
    if (originalTotal != modifiedTotal) {
      changes['priceChange'] = {
        'old': originalTotal.toStringAsFixed(2),
        'new': modifiedTotal.toStringAsFixed(2),
        'difference': (modifiedTotal - originalTotal).toStringAsFixed(2),
      };
    }
    
    // Level changes
    if (originalQuote.levels.length != modifiedQuote.levels.length) {
      changes['levelChanges'] = {
        'oldCount': originalQuote.levels.length,
        'newCount': modifiedQuote.levels.length,
      };
    }
    
    // Add-on changes
    if (originalQuote.addons.length != modifiedQuote.addons.length) {
      changes['addonChanges'] = {
        'oldCount': originalQuote.addons.length,
        'newCount': modifiedQuote.addons.length,
      };
    }
    
    // Discount changes
    if (originalQuote.discounts.length != modifiedQuote.discounts.length) {
      changes['discountChanges'] = {
        'oldCount': originalQuote.discounts.length,
        'newCount': modifiedQuote.discounts.length,
      };
    }
    
    return changes;
  }

  /// Create a new version of a quote with specified edit reason
  Future<QuoteVersionResult> createNewVersion(
    SimplifiedMultiLevelQuote originalQuote,
    QuoteEditReason editReason,
    String? editDescription,
  ) async {
    try {
      print('🔄 QuoteVersioningService: Starting version creation for quote ${originalQuote.id}');
      
      // Validation
      if (!originalQuote.isCurrentVersion) {
        print('❌ Quote ${originalQuote.id} is not current version');
        return QuoteVersionResult.error(
          'Can only create new version from current version'
        );
      }

      print('✅ Quote ${originalQuote.id} validated, creating version ${originalQuote.version + 1}');

      // Create new version without modifying original
      final newQuote = _createQuoteCopy(originalQuote);
      newQuote.version = originalQuote.version + 1;
      newQuote.isCurrentVersion = true;
      newQuote.status = 'draft'; // Reset status to draft
      newQuote.previousStatus = null; // Clear previous status
      newQuote.pdfPath = null; // Clear PDF - needs regeneration
      newQuote.pdfTemplateId = null;
      newQuote.pdfGeneratedAt = null;
      newQuote.updatedAt = DateTime.now();

      // CRITICAL FIX: Update quote number to include version to prevent UNIQUE constraint violation
      // This prevents ConflictAlgorithm.replace from deleting previous versions
      final baseQuoteNumber = getBaseQuoteNumber(originalQuote.quoteNumber);
      newQuote.quoteNumber = getVersionedQuoteNumber(baseQuoteNumber, newQuote.version);
      print('🔢 Updated quote number from "${originalQuote.quoteNumber}" to "${newQuote.quoteNumber}"');

      // Determine parent quote ID
      newQuote.parentQuoteId = originalQuote.parentQuoteId ?? originalQuote.id;
      print('✅ New quote created with ID: ${newQuote.id}, version: ${newQuote.version}');

      // Save new version (preserves original)
      await _repository.createQuote(newQuote);
      print('✅ New quote saved to database');

      // Update ONLY the current flag of original
      await _repository.updateQuoteCurrentVersionFlag(originalQuote.id, false);
      print('✅ Original quote marked as non-current');
      
      // Fix parent quote ID for first version if needed
      print('🔍 Original quote parentQuoteId: ${originalQuote.parentQuoteId}');
      if (originalQuote.parentQuoteId == null) {
        print('✅ Fixing parent quote ID for first version...');
        await _repository.updateQuoteParentId(originalQuote.id, originalQuote.id);
        
        // CRITICAL FIX: Update original quote number to include version
        // This ensures the first version also has a versioned quote number
        final baseQuoteNumber = getBaseQuoteNumber(originalQuote.quoteNumber);
        final versionedQuoteNumber = getVersionedQuoteNumber(baseQuoteNumber, originalQuote.version);
        await _repository.updateQuoteNumber(originalQuote.id, versionedQuoteNumber);
        print('🔢 Updated original quote number from "${originalQuote.quoteNumber}" to "$versionedQuoteNumber"');
        
        print('✅ Fixed parent quote ID for original version');
      } else {
        print('⏭️ Parent quote ID already set, skipping update');
      }

      // Create edit history entry
      final editHistory = QuoteEditHistory(
        quoteId: newQuote.id,
        version: newQuote.version,
        editReason: editReason,
        editDescription: editDescription,
        changesSummary: generateChangesSummary(originalQuote, newQuote),
      );
      print('✅ Edit history entry created: ${editHistory.id}');

      // Save edit history to database
      await _repository.createEditHistory(editHistory);
      print('✅ Edit history saved to database');

      print('🎉 Version creation completed successfully');
      return QuoteVersionResult.success(
        message: 'New version v${newQuote.version} created',
        newQuote: newQuote,
        editHistory: editHistory,
      );

    } catch (e) {
      print('❌ Version creation failed: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      return QuoteVersionResult.error('Failed to create new version: $e');
    }
  }

  /// Get all versions of a quote (by parent ID)
  Future<List<SimplifiedMultiLevelQuote>> getQuoteVersions(
    String parentQuoteId,
  ) async {
    return await _repository.getQuoteVersions(parentQuoteId);
  }

  /// Get the current version of a quote family
  SimplifiedMultiLevelQuote? getCurrentVersion(
    List<SimplifiedMultiLevelQuote> versions,
  ) {
    try {
      return versions.firstWhere((quote) => quote.isCurrentVersion);
    } catch (e) {
      // If no current version found, return the highest version number
      if (versions.isNotEmpty) {
        versions.sort((a, b) => b.version.compareTo(a.version));
        return versions.first;
      }
      return null;
    }
  }

  /// Get versioned quote number display
  String getVersionedQuoteNumber(String baseQuoteNumber, int version) {
    // Remove existing version suffix if present
    final cleanQuoteNumber = baseQuoteNumber.replaceAll(RegExp(r' v\d+$'), '');
    return '$cleanQuoteNumber v$version';
  }

  /// Extract base quote number (without version)
  String getBaseQuoteNumber(String versionedQuoteNumber) {
    return versionedQuoteNumber.replaceAll(RegExp(r' v\d+$'), '');
  }

  /// Check if a quote can be edited (must be current version)
  bool canEditQuote(SimplifiedMultiLevelQuote quote) {
    return quote.isCurrentVersion;
  }

  /// Get edit history for a quote family
  Future<List<QuoteEditHistory>> getEditHistory(
    String parentQuoteId,
  ) async {
    return await _repository.getEditHistoryForQuoteFamily(parentQuoteId);
  }

  /// Calculate total for a quote (business logic)
  double _calculateQuoteTotal(SimplifiedMultiLevelQuote quote) {
    double total = 0.0;
    
    // Add level prices (for selected level or all if none selected)
    if (quote.selectedLevelId != null) {
      final selectedLevel = quote.levels
          .where((level) => level.id == quote.selectedLevelId)
          .firstOrNull;
      if (selectedLevel != null) {
        total += selectedLevel.subtotal;
      }
    } else if (quote.levels.isNotEmpty) {
      // If no level selected, use first level for calculation
      total += quote.levels.first.subtotal;
    }
    
    // Add addons
    for (final addon in quote.addons) {
      total += addon.unitPrice * addon.quantity;
    }
    
    // Apply discounts
    double discountAmount = 0.0;
    for (final discount in quote.discounts) {
      if (discount.isValid) {
        discountAmount += discount.calculateDiscountAmount(total);
      }
    }
    total -= discountAmount;
    
    // Add tax
    final taxAmount = total * (quote.taxRate / 100);
    total += taxAmount;
    
    return total;
  }

  /// Create a deep copy of a quote for versioning with NEW unique IDs
  /// CRITICAL: All IDs must be regenerated to prevent shared data corruption
  SimplifiedMultiLevelQuote _createQuoteCopy(SimplifiedMultiLevelQuote original) {
    final uuid = const Uuid();
    print('🔄 Creating quote copy with NEW IDs to prevent shared data corruption');
    
    // Create level ID mapping for referenced updates
    final Map<String, String> levelIdMapping = {};
    
    // Create levels with NEW unique IDs
    final newLevels = original.levels.map((level) {
      final newLevelId = uuid.v4();
      levelIdMapping[level.id] = newLevelId;
      print('   Level ID mapping: ${level.id} -> $newLevelId');
      
      // Copy level items (they use database auto-increment IDs, not model IDs)
      final newLevelItems = level.includedItems.map((item) {
        return QuoteItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          unit: item.unit,
          description: item.description,
        );
      }).toList();
      
      return QuoteLevel(
        id: newLevelId, // NEW unique ID
        name: level.name,
        levelNumber: level.levelNumber,
        basePrice: level.basePrice,
        baseQuantity: level.baseQuantity,
        includedItems: newLevelItems,
        subtotal: level.subtotal,
      );
    }).toList();
    
    // Copy addons (they use database auto-increment IDs, not model IDs)
    final newAddons = original.addons.map((addon) {
      return QuoteItem(
        productId: addon.productId,
        productName: addon.productName,
        quantity: addon.quantity,
        unitPrice: addon.unitPrice,
        unit: addon.unit,
        description: addon.description,
      );
    }).toList();
    
    // Create discounts with NEW unique IDs
    final newDiscounts = original.discounts.map((discount) {
      final newDiscountId = uuid.v4();
      print('   Discount ID mapping: ${discount.id} -> $newDiscountId');
      return QuoteDiscount(
        id: newDiscountId, // NEW unique ID
        type: discount.type,
        value: discount.value,
        code: discount.code,
        description: discount.description,
        applyToAddons: discount.applyToAddons,
        excludedProductIds: List.from(discount.excludedProductIds),
        expiryDate: discount.expiryDate,
        isActive: discount.isActive,
      );
    }).toList();
    
    // Create permits with NEW unique IDs
    final newPermits = original.permits.map((permit) {
      final newPermitId = uuid.v4();
      print('   Permit ID mapping: ${permit.id} -> $newPermitId');
      return PermitItem(
        id: newPermitId, // NEW unique ID
        name: permit.name,
        amount: permit.amount,
        description: permit.description,
        isRequired: permit.isRequired,
      );
    }).toList();
    
    // Create custom line items with NEW unique IDs
    final newCustomLineItems = original.customLineItems.map((item) {
      final newItemId = uuid.v4();
      print('   Custom item ID mapping: ${item.id} -> $newItemId');
      return CustomLineItem(
        id: newItemId, // NEW unique ID
        name: item.name,
        amount: item.amount,
        description: item.description,
        isTaxable: item.isTaxable,
      );
    }).toList();
    
    // Update selectedLevelId to use new level ID if it exists
    String? newSelectedLevelId = original.selectedLevelId;
    if (original.selectedLevelId != null && levelIdMapping.containsKey(original.selectedLevelId)) {
      newSelectedLevelId = levelIdMapping[original.selectedLevelId];
      print('   Selected level ID mapping: ${original.selectedLevelId} -> $newSelectedLevelId');
    }
    
    // Create a new quote with the same data but ALL NEW IDs
    return SimplifiedMultiLevelQuote(
      customerId: original.customerId,
      roofScopeDataId: original.roofScopeDataId,
      quoteNumber: original.quoteNumber, // Will be updated with version
      levels: newLevels,
      addons: newAddons,
      taxRate: original.taxRate,
      discount: original.discount,
      status: original.status,
      previousStatus: original.previousStatus,
      version: original.version, // Will be incremented
      parentQuoteId: original.parentQuoteId,
      isCurrentVersion: original.isCurrentVersion, // Will be set to true
      notes: original.notes,
      validUntil: original.validUntil,
      createdAt: DateTime.now(), // New creation time
      updatedAt: DateTime.now(),
      baseProductId: original.baseProductId,
      baseProductName: original.baseProductName,
      baseProductUnit: original.baseProductUnit,
      discounts: newDiscounts,
      nonDiscountableProductIds: List.from(original.nonDiscountableProductIds),
      permits: newPermits,
      noPermitsRequired: original.noPermitsRequired,
      customLineItems: newCustomLineItems,
      selectedLevelId: newSelectedLevelId,
    );
  }
}