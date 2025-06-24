import 'package:flutter/material.dart';

/// Compact dropdown component extracted from ProductFormDialog
/// Provides consistent styling for dropdown selections
class CompactDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final bool isPhone;

  const CompactDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = items.toSet().toList();
    final currentValue = items.contains(value) ? value : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isPhone ? 14 : 16,
          ),
        ),
        SizedBox(height: isPhone ? 6 : 8),
        DropdownButtonFormField<T>(
          value: currentValue,
          items: uniqueItems.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: TextStyle(fontSize: isPhone ? 14 : 16),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isPhone ? 12 : 16,
              vertical: isPhone ? 8 : 10,
            ),
            isDense: isPhone,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: isPhone ? 20 : 24,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}