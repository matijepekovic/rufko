import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rufko/data/providers/state/quote_state_provider.dart';
import 'package:rufko/data/models/business/simplified_quote.dart';
import 'package:rufko/core/services/database/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService db;
  late QuoteStateProvider provider;

  setUp(() {
    db = MockDatabaseService();
    provider = QuoteStateProvider(database: db);
  });

  test('loadQuotes populates list', () async {
    final quote = SimplifiedMultiLevelQuote(customerId: '1');
    when(() => db.getAllSimplifiedMultiLevelQuotes())
        .thenAnswer((_) async => [quote]);

    await provider.loadQuotes();

    expect(provider.quotes, [quote]);
  });

  test('addQuote adds item to list', () async {
    final quote = SimplifiedMultiLevelQuote(customerId: '1');
    when(() => db.saveSimplifiedMultiLevelQuote(quote))
        .thenAnswer((_) async {});

    await provider.addSimplifiedQuote(quote);

    expect(provider.quotes.contains(quote), isTrue);
    verify(() => db.saveSimplifiedMultiLevelQuote(quote)).called(1);
  });

  test('updateQuote updates existing item', () async {
    final quote = SimplifiedMultiLevelQuote(customerId: '1');
    provider.quotes.add(quote);

    final updated = SimplifiedMultiLevelQuote(id: quote.id, customerId: '1');
    when(() => db.saveSimplifiedMultiLevelQuote(updated))
        .thenAnswer((_) async {});

    await provider.updateSimplifiedQuote(updated);

    expect(provider.quotes.first.id, updated.id);
  });

  test('deleteQuote removes item from list', () async {
    final quote = SimplifiedMultiLevelQuote(customerId: '1');
    provider.quotes.add(quote);
    when(() => db.deleteSimplifiedMultiLevelQuote(quote.id))
        .thenAnswer((_) async {});

    await provider.deleteSimplifiedQuote(quote.id);

    expect(provider.quotes, isEmpty);
  });
}
