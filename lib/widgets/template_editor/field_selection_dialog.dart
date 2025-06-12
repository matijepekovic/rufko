import 'package:flutter/material.dart';
import '../../models/pdf_template.dart';
import "../../models/product.dart";
import '../common/field_category_list.dart';

class FieldSelectionDialog extends StatelessWidget {
  final String pdfFieldName;
  final PDFTemplate template;
  final List<Product> products;
  final List<dynamic> customFields;
  final void Function(String) onSelect;

  const FieldSelectionDialog({
    super.key,
    required this.pdfFieldName,
    required this.template,
    required this.products,
    required this.customFields,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map: $pdfFieldName')),
      body: FieldCategoryList(
        template: template,
        products: products,
        customFields: customFields,
        onSelect: onSelect,
      ),
    );
  }
}
