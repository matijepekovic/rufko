import 'package:flutter/foundation.dart';
import '../models/business/simplified_quote.dart';
import '../models/business/customer.dart';
import '../../core/services/database/database_service.dart';
import '../../core/services/pdf/pdf_service.dart';

class QuoteProvider extends ChangeNotifier {
  final DatabaseService _db;
  final PdfService _pdfService = PdfService();
  List<SimplifiedMultiLevelQuote> _quotes = [];

  QuoteProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  List<SimplifiedMultiLevelQuote> get quotes => _quotes;

  Future<void> loadQuotes() async {
    try {
      _quotes = await _db.getAllCurrentQuotes();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addQuote(SimplifiedMultiLevelQuote quote) async {
    await _db.saveSimplifiedMultiLevelQuote(quote);
    _quotes.add(quote);
    notifyListeners();
  }

  Future<void> updateQuote(SimplifiedMultiLevelQuote quote) async {
    quote.updatedAt = DateTime.now();
    await _db.saveSimplifiedMultiLevelQuote(quote);
    final index = _quotes.indexWhere((q) => q.id == quote.id);
    if (index != -1) _quotes[index] = quote;
    notifyListeners();
  }

  Future<void> deleteQuote(String id) async {
    await _db.deleteSimplifiedMultiLevelQuote(id);
    _quotes.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  List<SimplifiedMultiLevelQuote> quotesForCustomer(String customerId) {
    return _quotes.where((q) => q.customerId == customerId).toList();
  }

  Future<String> generateQuotePdf(
      SimplifiedMultiLevelQuote quote, Customer customer,
      {String? selectedLevelId, List<String>? selectedAddonIds}) async {
    return await _pdfService.generateSimplifiedMultiLevelQuotePdf(quote, customer,
        selectedLevelId: selectedLevelId, selectedAddonIds: selectedAddonIds);
  }

  List<SimplifiedMultiLevelQuote> searchQuotes(String query) {
    if (query.isEmpty) return _quotes;
    final lower = query.toLowerCase();
    return _quotes
        .where((q) => q.quoteNumber.toLowerCase().contains(lower))
        .toList();
  }
}
