import 'package:flutter/foundation.dart';

import '../../models/business/simplified_quote.dart';
import '../../../core/services/database/database_service.dart';

/// Helper methods for managing [SimplifiedMultiLevelQuote] records.
class QuoteHelper {
  static Future<void> addQuote({
    required DatabaseService db,
    required List<SimplifiedMultiLevelQuote> quotes,
    required SimplifiedMultiLevelQuote quote,
  }) async {
    await db.saveSimplifiedMultiLevelQuote(quote);
    quotes.add(quote);
    if (kDebugMode) {
      debugPrint('➕ Added quote: ${quote.quoteNumber}');
    }
  }

  static Future<void> updateQuote({
    required DatabaseService db,
    required List<SimplifiedMultiLevelQuote> quotes,
    required SimplifiedMultiLevelQuote quote,
  }) async {
    quote.updatedAt = DateTime.now();
    await db.saveSimplifiedMultiLevelQuote(quote);
    final index = quotes.indexWhere((q) => q.id == quote.id);
    if (index != -1) {
      quotes[index] = quote;
      if (kDebugMode) debugPrint('✅ Updated quote in memory');
    } else {
      quotes.add(quote);
      if (kDebugMode) debugPrint('⚠️ Quote not found in memory, adding it');
    }
  }

  static Future<void> deleteQuote({
    required DatabaseService db,
    required List<SimplifiedMultiLevelQuote> quotes,
    required String quoteId,
  }) async {
    await db.deleteSimplifiedMultiLevelQuote(quoteId);
    quotes.removeWhere((q) => q.id == quoteId);
    if (kDebugMode) debugPrint('🗑️ Deleted quote $quoteId');
  }

  static Future<void> updateStatus({
    required DatabaseService db,
    required List<SimplifiedMultiLevelQuote> quotes,
    required String quoteId,
    required String status,
  }) async {
    final index = quotes.indexWhere((q) => q.id == quoteId);
    if (index != -1) {
      final quote = quotes[index];
      quote.status = status;
      quote.updatedAt = DateTime.now();
      await db.saveSimplifiedMultiLevelQuote(quote);
      quotes[index] = quote;
      if (kDebugMode) debugPrint('🔄 Updated status for $quoteId to $status');
    }
  }
}
