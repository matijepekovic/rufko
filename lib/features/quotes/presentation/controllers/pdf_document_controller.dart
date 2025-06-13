import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

import '../../../../data/models/ui/pdf_form_field.dart';

class PdfDocumentController {
  PdfDocumentController(this.pdfPath);

  String pdfPath;

  Future<List<PDFFormField>> loadFormFields() async {
    final file = File(pdfPath);
    if (!await file.exists()) return [];

    final bytes = await file.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);
    final fields = <PDFFormField>[];
    try {
      for (var i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final fieldName = field.name ?? 'field_\$i';
        final bounds = Rect.fromLTWH(
          field.bounds.left,
          field.bounds.top,
          field.bounds.width,
          field.bounds.height,
        );

        String fieldType = 'text';
        String currentValue = '';
        List<String>? options;

        if (field is sf_pdf.PdfTextBoxField) {
          currentValue = field.text;
        } else if (field is sf_pdf.PdfComboBoxField) {
          fieldType = 'dropdown';
          currentValue = field.selectedValue;
          options = [
            for (var j = 0; j < field.items.count; j++) field.items[j].text
          ];
        } else if (field is sf_pdf.PdfListBoxField) {
          fieldType = 'listbox';
          currentValue =
              field.selectedValues.isNotEmpty ? field.selectedValues.first : '';
          options = [
            for (var j = 0; j < field.items.count; j++) field.items[j].text
          ];
        } else if (field is sf_pdf.PdfCheckBoxField) {
          fieldType = 'checkbox';
          currentValue = field.isChecked ? 'true' : 'false';
        } else if (field is sf_pdf.PdfRadioButtonListField) {
          fieldType = 'radio';
          currentValue = field.selectedValue;
          options = [
            for (var j = 0; j < field.items.count; j++) field.items[j].value
          ];
        }

        fields.add(PDFFormField(
          name: fieldName,
          type: fieldType,
          currentValue: currentValue,
          bounds: bounds,
          pageNumber: 0,
          options: options,
        ));
      }
    } finally {
      document.dispose();
    }

    return fields;
  }

  Future<File> applyEditsUsingTemplateApproach(
      Map<String, String> edits) async {
    final originalFile = File(pdfPath);
    final bytes = await originalFile.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      for (var i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final fieldName = field.name ?? 'field_\$i';
        if (edits.containsKey(fieldName)) {
          final value = edits[fieldName]!;
          field.readOnly = false;
          if (field is sf_pdf.PdfTextBoxField) {
            field.text = value;
          } else if (field is sf_pdf.PdfCheckBoxField) {
            field.isChecked = value.toLowerCase() == 'true';
          } else if (field is sf_pdf.PdfComboBoxField) {
            field.selectedValue = value;
          } else if (field is sf_pdf.PdfRadioButtonListField) {
            field.selectedValue = value;
          }
        }
      }

      document.form.setDefaultAppearance(false);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/mapped_${DateTime.now().millisecondsSinceEpoch}.pdf');
      final pdfBytes = await document.save();
      await tempFile.writeAsBytes(pdfBytes);
      return tempFile;
    } finally {
      document.dispose();
    }
  }

  Future<File> applyFormFieldEdits(Map<String, String> edits) async {
    final originalFile = File(pdfPath);
    final bytes = await originalFile.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      for (var i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final fieldName = field.name ?? 'field_\$i';
        if (edits.containsKey(fieldName)) {
          final newValue = edits[fieldName]!;
          if (field is sf_pdf.PdfTextBoxField) {
            field.text = newValue;
          } else if (field is sf_pdf.PdfComboBoxField) {
            field.selectedValue = newValue;
          } else if (field is sf_pdf.PdfCheckBoxField) {
            field.isChecked = newValue.toLowerCase() == 'true';
          } else if (field is sf_pdf.PdfRadioButtonListField) {
            field.selectedValue = newValue;
          } else if (field is sf_pdf.PdfListBoxField) {
            field.selectedValues = [newValue];
          }
        }
      }

      for (var i = 0; i < document.form.fields.count; i++) {
        document.form.fields[i].readOnly = false;
      }
      document.form.setDefaultAppearance(false);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf');
      final pdfBytes = await document.save();
      await tempFile.writeAsBytes(pdfBytes);
      return tempFile;
    } finally {
      document.dispose();
    }
  }
}
