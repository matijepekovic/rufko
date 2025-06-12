import 'package:flutter/material.dart';
import '../../models/pdf_template.dart';
import '../../models/product.dart';
import '../common/field_category_list.dart';
import '../../theme/rufko_theme.dart';

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

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Map Fields'),
        content: const Text(
          'Select a field from the list to link it with the chosen PDF field. '
          'Existing links can be replaced by choosing another field.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text('Map: $pdfFieldName'),
        backgroundColor: RufkoTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Mapping help',
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: FieldCategoryList(
        template: template,
        products: products,
        customFields: customFields,
        onSelect: onSelect,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Dialog.fullscreen(child: scaffold);
        }
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(width: 600, child: scaffold),
        );
      },
    );
  }
}
