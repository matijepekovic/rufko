import 'package:flutter/material.dart';

import '../../../../../data/models/business/product.dart';
import '../../controllers/product_form_controller.dart';
import '../level_management/product_level_card.dart';
import '../level_management/level_controls_widget.dart';

/// Pricing levels tab widget extracted from ProductFormDialog
/// Handles dynamic level management based on product type
class PricingLevelsTab extends StatelessWidget {
  final ProductFormController controller;
  final bool isPhone;

  const PricingLevelsTab({
    super.key,
    required this.controller,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (controller.pricingType == ProductPricingType.simple) {
          return _buildSimpleTypeMessage(context);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isPhone ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: isPhone ? 16 : 24),
              _buildLevelControls(),
              SizedBox(height: isPhone ? 16 : 24),
              _buildLevelCards(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleTypeMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten,
              size: isPhone ? 48 : 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: isPhone ? 16 : 24),
            Text(
              'Simple Product Type',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: isPhone ? 18 : 22,
              ),
            ),
            SizedBox(height: isPhone ? 8 : 12),
            Text(
              'Simple products use the same price across all quote levels.\nNo additional level configuration needed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: isPhone ? 14 : 16,
                height: 1.4,
              ),
            ),
            SizedBox(height: isPhone ? 16 : 24),
            Container(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[700],
                    size: isPhone ? 18 : 20,
                  ),
                  SizedBox(width: isPhone ? 8 : 12),
                  Text(
                    'Ready to save!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: isPhone ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final typeTitle = controller.pricingType == ProductPricingType.mainDifferentiator
        ? 'Main Differentiator Levels'
        : 'Sub-leveled Options';
    
    final typeDescription = controller.pricingType == ProductPricingType.mainDifferentiator
        ? 'Configure the levels that define your quote columns (e.g., Builder, Standard, Premium)'
        : 'Set up the different options customers can choose from within each quote level';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          typeTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isPhone ? 18 : 22,
          ),
        ),
        SizedBox(height: isPhone ? 6 : 8),
        Text(
          typeDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
            fontSize: isPhone ? 14 : 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelControls() {
    return LevelControlsWidget(
      pricingType: controller.pricingType,
      currentLevelCount: controller.currentLevelKeys.length,
      canAddLevel: controller.canAddLevel(),
      canRemoveLevel: controller.canRemoveLevel(),
      onAddLevel: controller.addLevel,
      isPhone: isPhone,
    );
  }

  Widget _buildLevelCards(BuildContext context) {
    if (controller.currentLevelKeys.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'No levels configured yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: isPhone ? 14 : 16,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < controller.currentLevelKeys.length; i++)
          ProductLevelCard(
            levelKey: controller.currentLevelKeys[i],
            index: i,
            nameController: controller.levelNameControllers[controller.currentLevelKeys[i]]!,
            descriptionController: controller.levelDescriptionControllers[controller.currentLevelKeys[i]]!,
            priceController: controller.levelPriceControllers[controller.currentLevelKeys[i]]!,
            onRemove: () => controller.removeLevel(i),
            canRemove: controller.canRemoveLevel(),
            isPhone: isPhone,
          ),
      ],
    );
  }
}