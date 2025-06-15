import 'package:flutter/material.dart';

import '../../../../../data/models/business/product.dart';
import '../../controllers/product_form_controller.dart';
import '../product_type/product_type_card.dart';

/// Product type tab widget extracted from ProductFormDialog
/// Handles pricing type selection with detailed explanations
class ProductTypeTab extends StatelessWidget {
  final ProductFormController controller;
  final bool isPhone;

  const ProductTypeTab({
    super.key,
    required this.controller,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isPhone ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: isPhone ? 16 : 24),
          _buildTypeSelection(),
          SizedBox(height: isPhone ? 16 : 24),
          _buildSelectedTypeInfo(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Product Type',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isPhone ? 18 : 22,
          ),
        ),
        SizedBox(height: isPhone ? 6 : 8),
        Text(
          'Choose how this product will be priced and displayed in quotes. This affects how customers see and select options.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
            fontSize: isPhone ? 14 : 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelection() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          children: [
            ProductTypeCard(
              type: ProductPricingType.mainDifferentiator,
              selectedType: controller.pricingType,
              onSelected: (type) {
                controller.pricingType = type;
              },
              isPhone: isPhone,
            ),
            ProductTypeCard(
              type: ProductPricingType.subLeveled,
              selectedType: controller.pricingType,
              onSelected: (type) {
                controller.pricingType = type;
              },
              isPhone: isPhone,
            ),
            ProductTypeCard(
              type: ProductPricingType.simple,
              selectedType: controller.pricingType,
              onSelected: (type) {
                controller.pricingType = type;
              },
              isPhone: isPhone,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedTypeInfo(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(isPhone ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: isPhone ? 18 : 20,
                  ),
                  SizedBox(width: isPhone ? 8 : 12),
                  Text(
                    'Selected Type Impact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: isPhone ? 16 : 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isPhone ? 8 : 12),
              Text(
                controller.getPricingTypeDescription(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isPhone ? 14 : 16,
                  height: 1.4,
                ),
              ),
              if (controller.pricingType != ProductPricingType.simple) ...[
                SizedBox(height: isPhone ? 8 : 12),
                Text(
                  'Next: Configure pricing levels for this product type.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: isPhone ? 12 : 14,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}