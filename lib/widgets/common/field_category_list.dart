import 'package:flutter/material.dart';
import '../../models/pdf_template.dart';
import '../../models/product.dart';
import '../../utils/pdf_field_utils.dart';

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
  String search = "";
  @override
  Widget build(BuildContext context) {
    final categorized = PDFTemplate.getCategorizedQuoteFieldTypes(
        widget.products, widget.customFields);
    final filtered = <String, List<String>>{};
    categorized.forEach((k, v) {
      final f = v.where((e) => e.toLowerCase().contains(search)).toList();
      if (f.isNotEmpty) filtered[k] = f;
    });
    return Column(
      children: [
        TextField(
            onChanged: (v) => setState(() => search = v.toLowerCase()),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: "Search")),
        Expanded(
          child: ListView(
            children: filtered.entries
                .map((e) => ListTile(
                      title: Row(children: [
                        getCategoryIcon(e.key),
                        const SizedBox(width: 4),
                        Text(e.key)
                      ]),
                      subtitle: Wrap(
                          children: e.value
                              .map((f) => TextButton(
                                  onPressed: () => widget.onSelect(f),
                                  child: Text(f)))
                              .toList()),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
