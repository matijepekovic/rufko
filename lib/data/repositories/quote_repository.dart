import 'package:sqflite/sqflite.dart';

import '../database/quote_database.dart';
import '../models/business/simplified_quote.dart';
import '../models/business/quote_edit_history.dart';

/// Repository class for quote-related database operations
/// Provides a clean interface for CRUD operations on quote data
class QuoteRepository {
  final QuoteDatabase _database = QuoteDatabase();

  // QUOTE OPERATIONS

  /// Create a new quote with all its related data
  Future<void> createQuote(SimplifiedMultiLevelQuote quote) async {
    print('🟢 QuoteRepository.createQuote() - Creating quote ${quote.id} v${quote.version}');
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Insert the main quote
      await txn.insert(
        QuoteDatabase.quotesTable,
        _database.quoteToMap(quote),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert quote levels
      for (final level in quote.levels) {
        await txn.insert(
          QuoteDatabase.quoteLevelsTable,
          _database.quoteLevelToMap(level, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert level items
        for (final item in level.includedItems) {
          await txn.insert(
            QuoteDatabase.quoteItemsTable,
            _database.quoteItemToMap(item, quote.id, level.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Insert addons
      for (final addon in quote.addons) {
        await txn.insert(
          QuoteDatabase.quoteItemsTable,
          _database.quoteItemToMap(addon, quote.id, null, itemType: 'addon'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert discounts
      for (final discount in quote.discounts) {
        await txn.insert(
          QuoteDatabase.quoteDiscountsTable,
          _database.quoteDiscountToMap(discount, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert permits
      for (final permit in quote.permits) {
        await txn.insert(
          QuoteDatabase.quotePermitsTable,
          _database.permitItemToMap(permit, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert custom line items
      for (final customItem in quote.customLineItems) {
        await txn.insert(
          QuoteDatabase.quoteCustomLineItemsTable,
          _database.customLineItemToMap(customItem, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    print('✅ QuoteRepository.createQuote() - Successfully created quote ${quote.id} v${quote.version}');
  }

  /// Get all quotes with their related data (includes all versions)
  Future<List<SimplifiedMultiLevelQuote>> getAllQuotes() async {
    final db = await _database.database;
    
    // Get all quotes
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      orderBy: 'created_at DESC',
    );

    // Build quotes with their related data
    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get only current version quotes with their related data
  Future<List<SimplifiedMultiLevelQuote>> getAllCurrentQuotes() async {
    final db = await _database.database;
    
    // Get only current version quotes
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'is_current_version = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    // Build quotes with their related data
    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get quote by ID with all related data
  Future<SimplifiedMultiLevelQuote?> getQuoteById(String id) async {
    final db = await _database.database;
    
    // Get the quote
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (quoteMaps.isEmpty) return null;

    return await _buildCompleteQuote(id, quoteMaps.first);
  }

  /// Update a quote and all its related data
  Future<void> updateQuote(SimplifiedMultiLevelQuote quote) async {
    print('🔴 QuoteRepository.updateQuote() - UPDATING quote ${quote.id} v${quote.version}');
    print('🔴 THIS METHOD DELETES AND RECREATES ALL RELATED DATA!');
    
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Update the main quote
      await txn.update(
        QuoteDatabase.quotesTable,
        _database.quoteToMap(quote),
        where: 'id = ?',
        whereArgs: [quote.id],
      );

      // Delete and recreate all related data for simplicity
      await _deleteQuoteRelatedData(txn, quote.id);

      // Insert quote levels
      for (final level in quote.levels) {
        await txn.insert(
          QuoteDatabase.quoteLevelsTable,
          _database.quoteLevelToMap(level, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert level items
        for (final item in level.includedItems) {
          await txn.insert(
            QuoteDatabase.quoteItemsTable,
            _database.quoteItemToMap(item, quote.id, level.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Insert addons
      for (final addon in quote.addons) {
        await txn.insert(
          QuoteDatabase.quoteItemsTable,
          _database.quoteItemToMap(addon, quote.id, null, itemType: 'addon'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert discounts
      for (final discount in quote.discounts) {
        await txn.insert(
          QuoteDatabase.quoteDiscountsTable,
          _database.quoteDiscountToMap(discount, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert permits
      for (final permit in quote.permits) {
        await txn.insert(
          QuoteDatabase.quotePermitsTable,
          _database.permitItemToMap(permit, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert custom line items
      for (final customItem in quote.customLineItems) {
        await txn.insert(
          QuoteDatabase.quoteCustomLineItemsTable,
          _database.customLineItemToMap(customItem, quote.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    print('✅ QuoteRepository.updateQuote() - Finished updating quote ${quote.id} v${quote.version}');
  }

  /// Delete a quote and all its related data
  Future<void> deleteQuote(String id) async {
    print('🗑️ QuoteRepository.deleteQuote() - DELETING quote ${id}');
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Delete related data first
      await _deleteQuoteRelatedData(txn, id);

      // Delete the main quote
      await txn.delete(
        QuoteDatabase.quotesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Get quotes by customer ID (includes all versions)
  Future<List<SimplifiedMultiLevelQuote>> getQuotesByCustomerId(String customerId) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get only current version quotes by customer ID
  Future<List<SimplifiedMultiLevelQuote>> getCurrentQuotesByCustomerId(String customerId) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'customer_id = ? AND is_current_version = ?',
      whereArgs: [customerId, 1],
      orderBy: 'created_at DESC',
    );

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get quotes by status
  Future<List<SimplifiedMultiLevelQuote>> getQuotesByStatus(String status) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Search quotes by quote number, customer name, or notes
  Future<List<SimplifiedMultiLevelQuote>> searchQuotes(String query) async {
    final db = await _database.database;
    final lowerQuery = '%${query.toLowerCase()}%';
    
    // Search in quotes and join with customers for customer name search
    final List<Map<String, dynamic>> quoteMaps = await db.rawQuery('''
      SELECT DISTINCT q.* FROM ${QuoteDatabase.quotesTable} q
      LEFT JOIN customers c ON q.customer_id = c.id
      WHERE 
        LOWER(q.quote_number) LIKE ? OR 
        LOWER(q.notes) LIKE ? OR
        LOWER(c.full_name) LIKE ? OR
        LOWER(c.company_name) LIKE ?
      ORDER BY q.created_at DESC
    ''', [lowerQuery, lowerQuery, lowerQuery, lowerQuery]);

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get recent quotes (last 30 days)
  Future<List<SimplifiedMultiLevelQuote>> getRecentQuotes({int days = 30}) async {
    final db = await _database.database;
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: days));
    
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'created_at >= ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get expired quotes
  Future<List<SimplifiedMultiLevelQuote>> getExpiredQuotes() async {
    final db = await _database.database;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'valid_until < ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'valid_until ASC',
    );

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    return quotes;
  }

  /// Get quote statistics
  Future<Map<String, dynamic>> getQuoteStatistics() async {
    final db = await _database.database;
    
    final totalQuotes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${QuoteDatabase.quotesTable}')
    ) ?? 0;
    
    final draftQuotes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${QuoteDatabase.quotesTable} WHERE status = "draft"')
    ) ?? 0;
    
    final sentQuotes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${QuoteDatabase.quotesTable} WHERE status = "sent"')
    ) ?? 0;
    
    final acceptedQuotes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${QuoteDatabase.quotesTable} WHERE status = "accepted"')
    ) ?? 0;
    
    final rejectedQuotes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${QuoteDatabase.quotesTable} WHERE status = "rejected"')
    ) ?? 0;

    final expiredQuotes = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${QuoteDatabase.quotesTable} WHERE valid_until < ?', [DateTime.now().toIso8601String()])
    ) ?? 0;

    // Get total value of all quotes
    final totalValue = await db.rawQuery('''
      SELECT SUM(
        CASE 
          WHEN levels.subtotal > 0 THEN levels.subtotal 
          ELSE levels.base_price * levels.base_quantity 
        END
      ) as total_value
      FROM ${QuoteDatabase.quotesTable} quotes
      LEFT JOIN ${QuoteDatabase.quoteLevelsTable} levels ON quotes.id = levels.quote_id
    ''');

    final totalQuoteValue = totalValue.first['total_value'] ?? 0.0;

    // Get status distribution
    final statusStats = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM ${QuoteDatabase.quotesTable} 
      GROUP BY status 
      ORDER BY count DESC
    ''');

    return {
      'totalQuotes': totalQuotes,
      'draftQuotes': draftQuotes,
      'sentQuotes': sentQuotes,
      'acceptedQuotes': acceptedQuotes,
      'rejectedQuotes': rejectedQuotes,
      'expiredQuotes': expiredQuotes,
      'totalQuoteValue': totalQuoteValue,
      'statusDistribution': statusStats,
    };
  }

  /// Batch insert quotes (useful for migration)
  Future<void> insertQuotes(List<SimplifiedMultiLevelQuote> quotes) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      for (final quote in quotes) {
        // Insert the main quote
        await txn.insert(
          QuoteDatabase.quotesTable,
          _database.quoteToMap(quote),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert quote levels
        for (final level in quote.levels) {
          await txn.insert(
            QuoteDatabase.quoteLevelsTable,
            _database.quoteLevelToMap(level, quote.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert level items
          for (final item in level.includedItems) {
            await txn.insert(
              QuoteDatabase.quoteItemsTable,
              _database.quoteItemToMap(item, quote.id, level.id),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // Insert addons
        for (final addon in quote.addons) {
          await txn.insert(
            QuoteDatabase.quoteItemsTable,
            _database.quoteItemToMap(addon, quote.id, null, itemType: 'addon'),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Insert discounts
        for (final discount in quote.discounts) {
          await txn.insert(
            QuoteDatabase.quoteDiscountsTable,
            _database.quoteDiscountToMap(discount, quote.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Insert permits
        for (final permit in quote.permits) {
          await txn.insert(
            QuoteDatabase.quotePermitsTable,
            _database.permitItemToMap(permit, quote.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Insert custom line items
        for (final customItem in quote.customLineItems) {
          await txn.insert(
            QuoteDatabase.quoteCustomLineItemsTable,
            _database.customLineItemToMap(customItem, quote.id),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Clear all quotes (useful for testing)
  Future<void> clearAllQuotes() async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      await txn.delete(QuoteDatabase.quoteCustomLineItemsTable);
      await txn.delete(QuoteDatabase.quotePermitsTable);
      await txn.delete(QuoteDatabase.quoteDiscountsTable);
      await txn.delete(QuoteDatabase.quoteItemsTable);
      await txn.delete(QuoteDatabase.quoteLevelsTable);
      await txn.delete(QuoteDatabase.quotesTable);
    });
  }

  // HELPER METHODS

  /// Build a complete quote with all related data
  Future<SimplifiedMultiLevelQuote> _buildCompleteQuote(String quoteId, Map<String, dynamic> quoteMap) async {
    final db = await _database.database;

    // Get quote levels
    final levelMaps = await db.query(
      QuoteDatabase.quoteLevelsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'level_number ASC',
    );

    List<QuoteLevel> levels = [];
    for (final levelMap in levelMaps) {
      final levelId = levelMap['id'];
      
      // Get level items
      final levelItemMaps = await db.query(
        QuoteDatabase.quoteItemsTable,
        where: 'level_id = ?',
        whereArgs: [levelId],
      );

      final levelItems = levelItemMaps
          .map((itemMap) => _database.quoteItemFromMap(itemMap))
          .toList();

      final level = _database.quoteLevelFromMap(levelMap, includedItems: levelItems);
      levels.add(level);
    }

    // Get addons
    final addonMaps = await db.query(
      QuoteDatabase.quoteItemsTable,
      where: 'addon_quote_id = ? AND item_type = ?',
      whereArgs: [quoteId, 'addon'],
    );

    final addons = addonMaps
        .map((itemMap) => _database.quoteItemFromMap(itemMap))
        .toList();

    // Get discounts
    final discountMaps = await db.query(
      QuoteDatabase.quoteDiscountsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );

    final discounts = discountMaps
        .map((discountMap) => _database.quoteDiscountFromMap(discountMap))
        .toList();

    // Get permits
    final permitMaps = await db.query(
      QuoteDatabase.quotePermitsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );

    final permits = permitMaps
        .map((permitMap) => _database.permitItemFromMap(permitMap))
        .toList();

    // Get custom line items
    final customItemMaps = await db.query(
      QuoteDatabase.quoteCustomLineItemsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );

    final customLineItems = customItemMaps
        .map((customMap) => _database.customLineItemFromMap(customMap))
        .toList();

    return _database.quoteFromMap(
      quoteMap,
      levels: levels,
      addons: addons,
      discounts: discounts,
      permits: permits,
      customLineItems: customLineItems,
    );
  }

  /// Delete all related data for a quote
  Future<void> _deleteQuoteRelatedData(Transaction txn, String quoteId) async {
    await txn.delete(
      QuoteDatabase.quoteCustomLineItemsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );

    await txn.delete(
      QuoteDatabase.quotePermitsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );

    await txn.delete(
      QuoteDatabase.quoteDiscountsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );

    await txn.delete(
      QuoteDatabase.quoteItemsTable,
      where: 'quote_id = ? OR level_id IN (SELECT id FROM ${QuoteDatabase.quoteLevelsTable} WHERE quote_id = ?) OR addon_quote_id = ?',
      whereArgs: [quoteId, quoteId, quoteId],
    );

    await txn.delete(
      QuoteDatabase.quoteLevelsTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );
  }

  // QUOTE EDIT HISTORY OPERATIONS

  /// Create a new edit history record
  Future<void> createEditHistory(QuoteEditHistory history) async {
    try {
      print('📝 QuoteRepository: Creating edit history for quote ${history.quoteId}');
      final db = await _database.database;
      
      final historyMap = history.toMap();
      print('📝 Edit history data: $historyMap');
      
      final result = await db.insert(
        QuoteDatabase.quoteEditHistoryTable,
        historyMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Edit history saved with row ID: $result');
    } catch (e) {
      print('❌ Failed to save edit history: $e');
      rethrow;
    }
  }

  /// Get edit history for a specific quote
  Future<List<QuoteEditHistory>> getEditHistoryForQuote(String quoteId) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> historyMaps = await db.query(
      QuoteDatabase.quoteEditHistoryTable,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'edited_at DESC',
    );

    return historyMaps
        .map((map) => QuoteEditHistory.fromMap(map))
        .toList();
  }

  /// Get edit history for a quote family (all versions)
  Future<List<QuoteEditHistory>> getEditHistoryForQuoteFamily(String parentQuoteId) async {
    print('📜 QuoteRepository: Getting edit history for parent ID: $parentQuoteId');
    final db = await _database.database;
    
    // First get all quotes in the family
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'id = ? OR parent_quote_id = ?',
      whereArgs: [parentQuoteId, parentQuoteId],
      columns: ['id'],
    );

    print('📜 Found ${quoteMaps.length} quotes in family');
    if (quoteMaps.isEmpty) return [];

    // Get all quote IDs
    final quoteIds = quoteMaps.map((map) => map['id'] as String).toList();
    print('📜 Quote IDs: $quoteIds');
    final placeholders = List.filled(quoteIds.length, '?').join(',');

    // Get all history for these quotes
    final List<Map<String, dynamic>> historyMaps = await db.query(
      QuoteDatabase.quoteEditHistoryTable,
      where: 'quote_id IN ($placeholders)',
      whereArgs: quoteIds,
      orderBy: 'edited_at DESC',
    );

    print('📜 Found ${historyMaps.length} edit history entries');
    
    final historyList = historyMaps
        .map((map) => QuoteEditHistory.fromMap(map))
        .toList();
        
    return historyList;
  }

  /// Get all versions of a quote (by parent ID)
  Future<List<SimplifiedMultiLevelQuote>> getQuoteVersions(String parentQuoteId) async {
    print('🗄️ QuoteRepository: Getting versions for parent ID: $parentQuoteId');
    final db = await _database.database;
    
    // Debug: Check all quotes in database
    final allQuotes = await db.query(QuoteDatabase.quotesTable, columns: ['id', 'version', 'parent_quote_id']);
    print('🗄️ All quotes in DB:');
    for (final quote in allQuotes) {
      print('🗄️   ID: ${quote['id']}, Version: ${quote['version']}, ParentID: ${quote['parent_quote_id']}');
    }
    
    // Get all quotes in the family
    final List<Map<String, dynamic>> quoteMaps = await db.query(
      QuoteDatabase.quotesTable,
      where: 'id = ? OR parent_quote_id = ?',
      whereArgs: [parentQuoteId, parentQuoteId],
      orderBy: 'version ASC',
    );

    print('🗄️ Found ${quoteMaps.length} quotes in database for parent $parentQuoteId');
    for (final quote in quoteMaps) {
      print('🗄️   Match: ID: ${quote['id']}, Version: ${quote['version']}, ParentID: ${quote['parent_quote_id']}');
    }

    List<SimplifiedMultiLevelQuote> quotes = [];
    for (final quoteMap in quoteMaps) {
      final quoteId = quoteMap['id'];
      final version = quoteMap['version'];
      final isCurrentVersion = quoteMap['is_current_version'] == 1;
      print('🗄️ Building quote: $quoteId v$version (current: $isCurrentVersion)');
      
      final quote = await _buildCompleteQuote(quoteId, quoteMap);
      quotes.add(quote);
    }

    print('🗄️ Returning ${quotes.length} built quotes');
    return quotes;
  }

  /// Update only the is_current_version flag for a quote
  /// This preserves all other quote data immutably
  Future<void> updateQuoteCurrentVersionFlag(String quoteId, bool isCurrent) async {
    final db = await _database.database;
    
    await db.update(
      QuoteDatabase.quotesTable,
      {'is_current_version': isCurrent ? 1 : 0},
      where: 'id = ?',
      whereArgs: [quoteId],
    );
    
    print('✅ Updated quote $quoteId current version flag to: $isCurrent');
  }

  /// Update parent quote ID for versioning
  /// Used to fix first version's parent ID
  Future<void> updateQuoteParentId(String quoteId, String parentId) async {
    final db = await _database.database;
    
    await db.update(
      QuoteDatabase.quotesTable,
      {'parent_quote_id': parentId},
      where: 'id = ?',
      whereArgs: [quoteId],
    );
    
    print('✅ Updated quote $quoteId parent ID to: $parentId');
  }

  /// Update quote number for versioning
  /// Used to add version suffix to quote numbers
  Future<void> updateQuoteNumber(String quoteId, String quoteNumber) async {
    final db = await _database.database;
    
    await db.update(
      QuoteDatabase.quotesTable,
      {'quote_number': quoteNumber},
      where: 'id = ?',
      whereArgs: [quoteId],
    );
    
    print('✅ Updated quote $quoteId number to: $quoteNumber');
  }
}