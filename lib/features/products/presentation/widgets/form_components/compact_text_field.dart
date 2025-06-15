import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact text field component extracted from ProductFormDialog
/// Provides consistent styling and validation for form fields
class CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isRequired;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool isPhone;

  const CompactTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isRequired = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
              vertical: isPhone ? 10 : 12,
            ),
            isDense: isPhone,
          ),
          style: TextStyle(fontSize: isPhone ? 14 : 16),
          validator: validator ?? (isRequired ? _defaultValidator : null),
        ),
      ],
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }
}