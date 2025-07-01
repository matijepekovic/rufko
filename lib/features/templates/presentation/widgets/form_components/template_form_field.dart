import 'package:flutter/material.dart';

/// Reusable template form field component
/// Consistent styling and validation for template forms
class TemplateFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isRequired;
  final int maxLines;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final bool readOnly;
  final Widget? suffixIcon;

  const TemplateFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isRequired = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: 6),
        _buildTextField(context),
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
          fontSize: 14,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 8,
        ),
        suffixIcon: suffixIcon,
      ),
      style: const TextStyle(fontSize: 14),
      validator: validator ?? (isRequired ? _defaultValidator : null),
      onChanged: onChanged != null ? (_) => onChanged!() : null,
    );
  }

  String? _defaultValidator(String? value) {
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '$label is required';
    }
    return null;
  }
}

/// Template-specific text area for content editing
class TemplateContentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isRequired;
  final VoidCallback? onChanged;

  const TemplateContentField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isRequired = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TemplateFormField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      maxLines: 8,
      onChanged: onChanged,
    );
  }
}