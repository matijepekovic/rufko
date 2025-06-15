import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rufko/data/providers/state/custom_fields_provider.dart';
import 'package:rufko/data/models/settings/custom_app_data.dart';
import 'package:rufko/data/models/media/inspection_document.dart';
import 'package:rufko/core/services/database/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService db;
  late CustomFieldsProvider provider;

  setUp(() {
    db = MockDatabaseService();
    provider = CustomFieldsProvider(database: db);
  });

  test('loadFields populates list', () async {
    final field = CustomAppDataField(fieldName: 'f', displayName: 'F');
    when(() => db.getAllCustomAppDataFields()).thenAnswer((_) async => [field]);
    when(() => db.getAllInspectionDocuments())
        .thenAnswer((_) async => <InspectionDocument>[]);

    await provider.loadFields();

    expect(provider.fields, [field]);
  });

  test('addField adds item', () async {
    final field = CustomAppDataField(fieldName: 'f', displayName: 'F');
    when(() => db.saveCustomAppDataField(field)).thenAnswer((_) async {});

    await provider.addField(field);

    expect(provider.fields.contains(field), isTrue);
    verify(() => db.saveCustomAppDataField(field)).called(1);
  });

  test('updateFieldValue updates value', () async {
    final field = CustomAppDataField(fieldName: 'f', displayName: 'F');
    provider.fields.add(field);
    when(() => db.saveCustomAppDataField(field)).thenAnswer((_) async {});

    await provider.updateFieldValue(field.id, 'new');

    expect(provider.fields.first.currentValue, 'new');
  });

  test('deleteField removes item', () async {
    final field = CustomAppDataField(fieldName: 'f', displayName: 'F');
    provider.fields.add(field);
    when(() => db.deleteCustomAppDataField(field.id)).thenAnswer((_) async {});

    await provider.deleteField(field.id);

    expect(provider.fields, isEmpty);
  });
}
