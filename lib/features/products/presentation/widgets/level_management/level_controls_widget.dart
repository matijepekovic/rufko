import 'package:flutter/material.dart';

import '../../../../../data/models/business/product.dart';

/// Level controls widget for adding/removing levels
/// Extracted from ProductFormDialog for reusability
class LevelControlsWidget extends StatelessWidget {
  final ProductPricingType pricingType;
  final int currentLevelCount;
  final bool canAddLevel;
  final bool canRemoveLevel;
  final VoidCallback onAddLevel;
  final bool isPhone;

  const LevelControlsWidget({
    super.key,
    required this.pricingType,
    required this.currentLevelCount,
    required this.canAddLevel,
    required this.canRemoveLevel,
    required this.onAddLevel,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: isPhone ? 8 : 12),
          _buildLevelInfo(context),
          if (canAddLevel) ...[
            SizedBox(height: isPhone ? 12 : 16),
            _buildAddButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.layers_outlined,
          color: Theme.of(context).primaryColor,
          size: isPhone ? 18 : 20,
        ),
        SizedBox(width: isPhone ? 6 : 8),
        Text(
          'Level Management',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isPhone ? 16 : 18,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelInfo(BuildContext context) {
    final minLevels = _getMinLevels();
    final maxLevels = _getMaxLevels();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current levels: $currentLevelCount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: isPhone ? 14 : 16,
          ),
        ),
        SizedBox(height: isPhone ? 4 : 6),
        Text(
          'Range: $minLevels - $maxLevels levels',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: isPhone ? 12 : 14,
          ),
        ),
        if (!canRemoveLevel && currentLevelCount == minLevels) ...[
          SizedBox(height: isPhone ? 4 : 6),
          Text(
            'Minimum levels reached',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange[700],
              fontSize: isPhone ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (!canAddLevel && currentLevelCount == maxLevels) ...[
          SizedBox(height: isPhone ? 4 : 6),
          Text(
            'Maximum levels reached',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange[700],
              fontSize: isPhone ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onAddLevel,
        icon: Icon(
          Icons.add,
          size: isPhone ? 16 : 18,
        ),
        label: Text(
          'Add Level',
          style: TextStyle(fontSize: isPhone ? 14 : 16),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          padding: EdgeInsets.symmetric(
            vertical: isPhone ? 8 : 12,
            horizontal: isPhone ? 12 : 16,
          ),
        ),
      ),
    );
  }

  int _getMinLevels() {
    switch (pricingType) {
      case ProductPricingType.mainDifferentiator:
        return 2;
      case ProductPricingType.subLeveled:
        return 2;
      case ProductPricingType.simple:
        return 0;
    }
  }

  int _getMaxLevels() {
    switch (pricingType) {
      case ProductPricingType.mainDifferentiator:
        return 6;
      case ProductPricingType.subLeveled:
        return 4;
      case ProductPricingType.simple:
        return 0;
    }
  }
}