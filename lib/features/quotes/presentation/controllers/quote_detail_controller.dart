import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/simplified_quote.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import 'pdf_generation_controller.dart';

class QuoteDetailController extends ChangeNotifier {
  QuoteDetailController({required this.quote, required this.customer}) {
    selectedLevelId = quote.levels.isNotEmpty ? quote.levels.first.id : null;
  }

  final SimplifiedMultiLevelQuote quote;
  final Customer customer;
  String? selectedLevelId;

  void selectLevel(String levelId) {
    selectedLevelId = levelId;
    notifyListeners();
  }

  void addDiscount(BuildContext context, QuoteDiscount discount) {
    quote.addDiscount(discount);
    context.read<AppStateProvider>().updateSimplifiedQuote(quote);
    notifyListeners();
  }

  void removeDiscount(BuildContext context, String discountId) {
    quote.removeDiscount(discountId);
    context.read<AppStateProvider>().updateSimplifiedQuote(quote);
    notifyListeners();
  }

  Color getStatusColor() {
    switch (quote.status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusButtonText() {
    switch (quote.status.toLowerCase()) {
      case 'draft':
        return 'Send Quote';
      case 'sent':
        return 'Mark Accepted';
      case 'accepted':
        return 'Mark Complete';
      default:
        return 'Update Status';
    }
  }

  void updateQuoteStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Quote Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['draft', 'sent', 'accepted', 'declined']
              .map(
                (status) => ListTile(
                  title: Text(status.toUpperCase()),
                  onTap: () {
                    quote.status = status;
                    quote.updatedAt = DateTime.now();
                    context.read<AppStateProvider>().updateSimplifiedQuote(quote);
                    Navigator.pop(context);
                    notifyListeners();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void deleteQuote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text('Are you sure you want to delete quote ${quote.quoteNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteSimplifiedQuote(quote.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void handleMenuAction(BuildContext context, String action, PDFGenerationController pdfController) {
    switch (action) {
      case 'generate_pdf':
        pdfController.generatePdf();
        break;
      case 'rename':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rename not implemented')), 
        );
        break;
      case 'delete':
        deleteQuote(context);
        break;
      default:
        break;
    }
  }
}
