import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Product level card widget extracted from ProductFormDialog
/// Handles individual level configuration with name, description, and price
class ProductLevelCard extends StatelessWidget {
  final String levelKey;
  final int index;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final void Function() onRemove;
  final bool canRemove;
  final bool isPhone;

  const ProductLevelCard({
    super.key,
    required this.levelKey,
    required this.index,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.onRemove,
    required this.canRemove,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: isPhone ? 4 : 8),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: isPhone ? 12 : 16),
            _buildForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isPhone ? 24 : 28,
          height: isPhone ? 24 : 28,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 12 : 14,
              ),
            ),
          ),
        ),
        SizedBox(width: isPhone ? 8 : 12),
        Expanded(
          child: Text(
            'Level ${index + 1}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isPhone ? 16 : 18,
            ),
          ),
        ),
        if (canRemove)
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red[600],
              size: isPhone ? 20 : 24,
            ),
            onPressed: onRemove,
            tooltip: 'Remove Level',
            constraints: BoxConstraints(
              minWidth: isPhone ? 32 : 40,
              minHeight: isPhone ? 32 : 40,
            ),
            padding: EdgeInsets.all(isPhone ? 4 : 8),
          ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        _buildNameField(context),
        SizedBox(height: isPhone ? 12 : 16),
        _buildDescriptionField(context),
        SizedBox(height: isPhone ? 12 : 16),
        _buildPriceField(context),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level Name *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isPhone ? 14 : 16,
          ),
        ),
        SizedBox(height: isPhone ? 6 : 8),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Builder, Standard, Premium',
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Level name is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isPhone ? 14 : 16,
          ),
        ),
        SizedBox(height: isPhone ? 6 : 8),
        TextFormField(
          controller: descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Describe this level option...',
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
        ),
      ],
    );
  }

  Widget _buildPriceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Modifier (Optional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isPhone ? 14 : 16,
          ),
        ),
        SizedBox(height: isPhone ? 6 : 8),
        TextFormField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: 'Additional cost for this level',
            prefixText: '\$ ',
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
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final price = double.tryParse(value);
              if (price == null || price < 0) {
                return 'Enter a valid price';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}