import 'package:flutter/material.dart';

class TemplateTypeSelector extends StatelessWidget {
  final List<String> types;
  final ValueChanged<String> onSelect;

  const TemplateTypeSelector({
    super.key,
    required this.types,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Select Template Type'),
      children: types
          .map((e) => SimpleDialogOption(
                onPressed: () => onSelect(e),
                child: Text(e),
              ))
          .toList(),
    );
  }
}
