import 'package:flutter/material.dart';

import '../../../../../data/models/business/product.dart';

/// Product type selection card extracted from ProductFormDialog
/// Displays pricing type options with descriptions and examples
class ProductTypeCard extends StatelessWidget {
  final ProductPricingType type;
  final ProductPricingType selectedType;
  final void Function(ProductPricingType) onSelected;
  final bool isPhone;

  const ProductTypeCard({
    super.key,
    required this.type,
    required this.selectedType,
    required this.onSelected,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selectedType;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: EdgeInsets.symmetric(vertical: isPhone ? 4 : 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onSelected(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isPhone ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isSelected),
              SizedBox(height: isPhone ? 8 : 12),
              _buildDescription(context),
              SizedBox(height: isPhone ? 8 : 12),
              _buildExample(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSelected) {
    return Row(
      children: [
        Icon(
          _getTypeIcon(),
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
          size: isPhone ? 20 : 24,
        ),
        SizedBox(width: isPhone ? 8 : 12),
        Expanded(
          child: Text(
            _getTypeTitle(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              fontSize: isPhone ? 16 : 18,
            ),
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
            size: isPhone ? 20 : 24,
          ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      _getTypeDescription(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: isPhone ? 14 : 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildExample(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Example:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isPhone ? 12 : 14,
            ),
          ),
          SizedBox(height: isPhone ? 4 : 6),
          Text(
            _getTypeExample(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isPhone ? 12 : 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (type) {
      case ProductPricingType.mainDifferentiator:
        return Icons.view_column;
      case ProductPricingType.subLeveled:
        return Icons.layers;
      case ProductPricingType.simple:
        return Icons.straighten;
    }
  }

  String _getTypeTitle() {
    switch (type) {
      case ProductPricingType.mainDifferentiator:
        return 'Main Differentiator';
      case ProductPricingType.subLeveled:
        return 'Material Swap (Sub-leveled)';
      case ProductPricingType.simple:
        return 'Simple Product';
    }
  }

  String _getTypeDescription() {
    switch (type) {
      case ProductPricingType.mainDifferentiator:
        return 'This product defines the main quote columns (Builder/Standard/Premium). Used for primary differentiation between quote levels.';
      case ProductPricingType.subLeveled:
        return 'Independent customer choice within each quote level. Customers can select different options without affecting the main quote structure.';
      case ProductPricingType.simple:
        return 'Same price across all quote levels. No customer choice variations - consistent pricing everywhere.';
    }
  }

  String _getTypeExample() {
    switch (type) {
      case ProductPricingType.mainDifferentiator:
        return 'Metal roofing system: Builder, Standard, Premium';
      case ProductPricingType.subLeveled:
        return 'Gutter guards: Basic mesh vs Premium micro-mesh';
      case ProductPricingType.simple:
        return 'Labor hours: Same rate across all quote levels';
    }
  }
}