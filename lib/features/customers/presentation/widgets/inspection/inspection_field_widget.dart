import 'package:flutter/material.dart';

import '../../../../../data/models/settings/custom_app_data.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';

/// Reusable widget for rendering different types of inspection fields
/// Extracted from InspectionTab for better maintainability
class InspectionFieldWidget extends StatelessWidget 
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin, ResponsiveDimensionsMixin {
  final CustomAppDataField field;
  final int index;
  final dynamic value;
  final Function(String fieldName, dynamic value) onValueChanged;
  final VoidCallback? onDateTap;

  const InspectionFieldWidget({
    super.key,
    required this.field,
    required this.index,
    required this.value,
    required this.onValueChanged,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in Row to add drag handle on the right
    return Row(
      children: [
        Expanded(
          child: _buildFieldContent(context),
        ),
        ReorderableDragStartListener(
          index: index,
          child: Container(
            padding: EdgeInsets.all(spacingSM(context)),
            child: Icon(
              Icons.drag_handle,
              color: Colors.grey[600],
              size: isCompact(context) ? 20 : 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldContent(BuildContext context) {
    // Special layout for checkbox - no header needed since CheckboxListTile has its own title
    if (field.fieldType.toLowerCase() == 'checkbox') {
      return Container(
        padding: responsivePadding(context, all: 3),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: _buildFieldInput(context),
      );
    }

    // Standard layout for other field types
    return Container(
      padding: responsivePadding(context, all: 3),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldHeader(),
          SizedBox(height: spacingSM(context)),
          _buildFieldInput(context),
          if (field.description?.isNotEmpty == true) ...[
            SizedBox(height: spacingXS(context)),
            _buildFieldDescription(),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            field.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        if (field.isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Required',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldInput(BuildContext context) {
    switch (field.fieldType.toLowerCase()) {
      case 'text':
      case 'string':
        return _buildTextInput(context);
      case 'number':
      case 'int':
      case 'double':
        return _buildNumberInput(context);
      case 'bool':
      case 'boolean':
        return _buildBooleanInput();
      case 'checkbox':
        return _buildCheckboxInput();
      case 'date':
        return _buildDateInput(context);
      case 'dropdown':
      case 'select':
        return _buildDropdownInput();
      case 'textarea':
      case 'multiline':
        return _buildTextAreaInput(context);
      default:
        return _buildTextInput(context);
    }
  }

  Widget _buildTextInput(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        hintText: (field.placeholder?.isNotEmpty == true) ? field.placeholder! : 'Enter ${field.displayName.toLowerCase()}',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingSM(context) * 2, 
          vertical: spacingSM(context),
        ),
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (newValue) => onValueChanged(field.fieldName, newValue),
    );
  }

  Widget _buildNumberInput(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        hintText: (field.placeholder?.isNotEmpty == true) ? field.placeholder! : 'Enter number',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingSM(context) * 2, 
          vertical: spacingSM(context),
        ),
        suffixIcon: const Icon(Icons.numbers, size: 18),
      ),
      style: const TextStyle(fontSize: 14),
      keyboardType: TextInputType.number,
      onChanged: (newValue) {
        final numValue = double.tryParse(newValue);
        onValueChanged(field.fieldName, numValue ?? newValue);
      },
    );
  }

  Widget _buildBooleanInput() {
    final boolValue = value?.toString() == 'true';
    
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onValueChanged(field.fieldName, true),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: boolValue ? Colors.green.shade100 : Colors.grey[100],
                border: Border.all(
                  color: boolValue ? Colors.green.shade300 : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: boolValue ? Colors.green.shade700 : Colors.grey[500],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Yes',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: boolValue ? Colors.green.shade700 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => onValueChanged(field.fieldName, false),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: !boolValue ? Colors.red.shade100 : Colors.grey[100],
                border: Border.all(
                  color: !boolValue ? Colors.red.shade300 : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cancel,
                    color: !boolValue ? Colors.red.shade700 : Colors.grey[500],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: !boolValue ? Colors.red.shade700 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxInput() {
    final checkboxValue = value == true || value?.toString() == 'true';
    
    return CheckboxListTile(
      title: Text(
        field.displayName,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: (field.description?.isNotEmpty == true) 
          ? Text(
              field.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      value: checkboxValue,
      onChanged: (newValue) => onValueChanged(field.fieldName, newValue ?? false),
      activeColor: Colors.green.shade600,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildDateInput(BuildContext context) {
    final displayValue = _formatDateDisplay(value);
    
    return InkWell(
      onTap: onDateTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(spacingMD(context)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayValue.isNotEmpty ? displayValue : 'Select date',
                style: TextStyle(
                  fontSize: 14,
                  color: displayValue.isNotEmpty ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownInput() {
    final options = (field.dropdownOptions?.isNotEmpty == true) 
        ? field.dropdownOptions! 
        : ['Option 1', 'Option 2', 'Option 3'];
    
    return DropdownButtonFormField<String>(
      value: options.contains(value?.toString()) ? value.toString() : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: Text(
        (field.placeholder?.isNotEmpty == true) ? field.placeholder! : 'Select option',
        style: const TextStyle(fontSize: 14),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (newValue) => onValueChanged(field.fieldName, newValue),
    );
  }

  Widget _buildTextAreaInput(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        hintText: (field.placeholder?.isNotEmpty == true) ? field.placeholder! : 'Enter details...',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.all(spacingMD(context)),
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: 4,
      onChanged: (newValue) => onValueChanged(field.fieldName, newValue),
    );
  }

  Widget _buildFieldDescription() {
    return Text(
      field.description ?? '',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
  }


  String _formatDateDisplay(dynamic value) {
    if (value == null) return '';
    
    if (value is String && value.isNotEmpty) {
      final date = DateTime.tryParse(value);
      if (date != null) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    
    return '';
  }
}