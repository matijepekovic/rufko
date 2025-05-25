import 'package:flutter/material.dart';
import '../models/simplified_quote.dart';
import '../models/customer.dart';

class SimplifiedQuoteDetailScreen extends StatelessWidget {
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;

  const SimplifiedQuoteDetailScreen({
    Key? key,
    required this.quote,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quote Details: ${quote.quoteNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Quote ID: ${quote.id}'),
            const SizedBox(height: 10),
            Text('Status: ${quote.status}'),
            const SizedBox(height: 20),
            Text('Levels:', style: Theme.of(context).textTheme.titleLarge),
            if (quote.levels.isEmpty)
              const Text('No levels configured.')
            else
              ...quote.levels.map((level) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(level.name),
                  subtitle: Text('Base Price: \$${level.basePrice.toStringAsFixed(2)}\nIncluded Items: ${level.includedItems.length}'),
                  trailing: Text('Subtotal: \$${level.subtotal.toStringAsFixed(2)}'),
                ),
              )),
            const SizedBox(height: 20),
            Text('Optional Add-ons:', style: Theme.of(context).textTheme.titleLarge),
            if (quote.addons.isEmpty)
              const Text('No optional add-ons.')
            else
              ...quote.addons.map((addon) => ListTile(
                title: Text(addon.productName),
                subtitle: Text('${addon.quantity} ${addon.unit}'),
                trailing: Text('\$${addon.totalPrice.toStringAsFixed(2)}'),
              )),
          ],
        ),
      ),
    );
  }
}