import 'package:flutter/foundation.dart';

import '../../models/business/simplified_quote.dart';
import '../../models/business/customer.dart';
import '../../../core/services/database/database_service.dart';
import '../../../core/services/pdf/pdf_service.dart';
import '../helpers/data_loading_helper.dart';
import '../helpers/quote_helper.dart';

/// Provider responsible for managing [SimplifiedMultiLevelQuote] data and
/// related operations. Extracted from `AppStateProvider` to isolate quote
/// management logic.
class QuoteStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  final PdfService _pdfService = PdfService();
  List<SimplifiedMultiLevelQuote> _quotes = [];

  QuoteStateProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<SimplifiedMultiLevelQuote> get quotes => _quotes;

  /// Loads all quotes from the database.
  Future<void> loadQuotes() async {
    _quotes = await DataLoadingHelper.loadSimplifiedQuotes(_db);
    notifyListeners();
  }

  /// Adds a new quote and persists it.
  Future<void> addSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await QuoteHelper.addQuote(db: _db, quotes: _quotes, quote: quote);
    notifyListeners();
  }

  /// Updates an existing quote.
  Future<void> updateSimplifiedQuote(SimplifiedMultiLevelQuote quote) async {
    await QuoteHelper.updateQuote(db: _db, quotes: _quotes, quote: quote);
    notifyListeners();
  }

  /// Deletes a quote by [quoteId].
  Future<void> deleteSimplifiedQuote(String quoteId) async {
    await QuoteHelper.deleteQuote(db: _db, quotes: _quotes, quoteId: quoteId);
    notifyListeners();
  }

  /// Updates a quote's [status].
  Future<void> updateQuoteStatus(String quoteId, String status) async {
    await QuoteHelper.updateStatus(
        db: _db, quotes: _quotes, quoteId: quoteId, status: status);
    notifyListeners();
  }

  /// Returns quotes belonging to the given [customerId].
  List<SimplifiedMultiLevelQuote> getSimplifiedQuotesForCustomer(
      String customerId) {
    return _quotes.where((q) => q.customerId == customerId).toList();
  }

  /// Finds quotes matching the search [query].
  List<SimplifiedMultiLevelQuote> searchSimplifiedQuotes(String query) {
    if (query.isEmpty) return _quotes;
    final lower = query.toLowerCase();
    return _quotes
        .where((q) => q.quoteNumber.toLowerCase().contains(lower))
        .toList();
  }

  /// Generates a PDF for the given [quote] and [customer].
  Future<String> generateSimplifiedQuotePdf(
    SimplifiedMultiLevelQuote quote,
    Customer customer, {
    String? selectedLevelId,
    List<String>? selectedAddonIds,
  }) async {
    return await _pdfService.generateSimplifiedMultiLevelQuotePdf(
      quote,
      customer,
      selectedLevelId: selectedLevelId,
      selectedAddonIds: selectedAddonIds,
    );
  }
}
