import 'package:flutter/material.dart';
import '../../../data/models/templates/pdf_template.dart';
import '../../../data/models/business/product.dart';
import '../../../data/models/ui/field_definition.dart';
import '../../../core/utils/helpers/pdf_field_utils.dart';

class FieldCategoryList extends StatefulWidget {
  final PDFTemplate template;
  final List<Product> products;
  final List<dynamic> customFields;
  final void Function(String) onSelect;

  const FieldCategoryList({
    super.key,
    required this.template,
    required this.products,
    required this.customFields,
    required this.onSelect,
  });

  @override
  State<FieldCategoryList> createState() => _FieldCategoryListState();
}

class _FieldCategoryListState extends State<FieldCategoryList> {
  final TextEditingController _searchController = TextEditingController();
  String searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorized =
        PDFTemplate.getCategorizedQuoteFieldTypes(widget.products, widget.customFields);
    final filtered = <String, List<String>>{};
    categorized.forEach((k, v) {
      final f = v.where((e) => e.toLowerCase().contains(searchTerm)).toList();
      if (f.isNotEmpty || k.toLowerCase().contains(searchTerm)) {
        filtered[k] = f;
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search fields',
            ),
            onChanged: (val) => setState(() => searchTerm = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final categoryName = filtered.keys.elementAt(index);
              final categoryFields = filtered[categoryName]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      getCategoryIcon(categoryName),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${categoryFields.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  initiallyExpanded: categoryName.contains('Customer') ||
                      categoryName.contains('Quote Information'),
                  children: categoryFields.map(_buildFieldItem).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldItem(String appDataType) {
    final existing = widget.template.fieldMappings.where(
      (m) => m.appDataType == appDataType && m.pdfFormFieldName.isNotEmpty,
    ).firstOrNull;
    final isMapped = existing != null && !existing.appDataType.startsWith('unmapped_');

    final def = PDFTemplate.getFieldDefinitions(widget.products, widget.customFields).firstWhere(
      (d) => d.appDataType == appDataType,
      orElse: () => FieldDefinition(
        appDataType: appDataType,
        displayName: appDataType,
        category: '',
        source: '',
      ),
    );

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isMapped ? Colors.orange.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isMapped ? Icons.warning : Icons.radio_button_unchecked,
          size: 20,
          color: isMapped ? Colors.orange.shade600 : Colors.green.shade600,
        ),
      ),
      title: Text(
        PDFTemplate.getFieldDisplayName(appDataType, widget.customFields),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: isMapped
          ? Text(
              'Already mapped to: ${existing.pdfFormFieldName}',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            )
          : Text(
              'Source: ${def.source}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
      trailing: Icon(
        isMapped ? Icons.swap_horiz : Icons.add_link,
        color: isMapped ? Colors.orange.shade600 : Colors.green.shade600,
      ),
      onTap: () => widget.onSelect(appDataType),
    );
  }
}
