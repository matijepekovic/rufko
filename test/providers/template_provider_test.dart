import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rufko/data/providers/template_provider.dart';
import 'package:rufko/data/models/templates/pdf_template.dart';
import 'package:rufko/data/models/templates/message_template.dart';
import 'package:rufko/data/models/templates/email_template.dart';
import 'package:rufko/data/models/templates/template_category.dart';
import 'package:rufko/core/services/database/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService db;
  late TemplateProvider provider;

  setUp(() {
    db = MockDatabaseService();
    provider = TemplateProvider(database: db);
  });

  test('loadTemplates populates lists', () async {
    final pdf = PDFTemplate(templateName: 't', pdfFilePath: 'a', pageWidth: 1, pageHeight: 1);
    when(() => db.getAllPDFTemplates()).thenAnswer((_) async => [pdf]);
    when(() => db.getAllMessageTemplates()).thenAnswer((_) async => <MessageTemplate>[]);
    when(() => db.getAllEmailTemplates()).thenAnswer((_) async => <EmailTemplate>[]);
    when(() => db.getRawCategoriesBoxValues()).thenReturn(<TemplateCategory>[]);

    await provider.loadTemplates();

    expect(provider.pdfTemplates, [pdf]);
  });

  test('addPDFTemplate adds item', () async {
    final pdf = PDFTemplate(templateName: 't', pdfFilePath: 'a', pageWidth: 1, pageHeight: 1);
    when(() => db.savePDFTemplate(pdf)).thenAnswer((_) async {});

    await provider.addPDFTemplate(pdf);

    expect(provider.pdfTemplates.contains(pdf), isTrue);
    verify(() => db.savePDFTemplate(pdf)).called(1);
  });

  test('updatePDFTemplate updates item', () async {
    final pdf = PDFTemplate(templateName: 't', pdfFilePath: 'a', pageWidth: 1, pageHeight: 1);
    provider.pdfTemplates.add(pdf);
    final updated = PDFTemplate(id: pdf.id, templateName: 'u', pdfFilePath: 'b', pageWidth: 1, pageHeight: 1);
    when(() => db.savePDFTemplate(updated)).thenAnswer((_) async {});

    await provider.updatePDFTemplate(updated);

    expect(provider.pdfTemplates.first.templateName, 'u');
  });

  test('deletePDFTemplate removes item', () async {
    final pdf = PDFTemplate(templateName: 't', pdfFilePath: 'a', pageWidth: 1, pageHeight: 1);
    provider.pdfTemplates.add(pdf);
    when(() => db.deletePDFTemplate(pdf.id)).thenAnswer((_) async {});

    await provider.deletePDFTemplate(pdf.id);

    expect(provider.pdfTemplates, isEmpty);
  });
}
