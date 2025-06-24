import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../data/providers/state/app_state_provider.dart';
import '../../controllers/product_form_controller.dart';
import '../form_components/compact_text_field.dart';
import '../form_components/compact_dropdown.dart';
import '../form_components/compact_switch.dart';
import '../product_photo_section.dart';

/// Basic info tab widget extracted from ProductFormDialog
/// Handles product name, description, price, category, unit, and settings
class BasicInfoTab extends StatelessWidget {
  final ProductFormController controller;
  final bool isPhone;

  const BasicInfoTab({
    super.key,
    required this.controller,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final categories = appState.appSettings?.productCategories ?? 
                          ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
        final units = appState.appSettings?.productUnits ?? 
                     ['each', 'sq ft', 'lin ft', 'hour', 'day'];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isPhone ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequiredFields(),
              SizedBox(height: isPhone ? 16 : 24),
              _buildCategoryAndUnit(categories, units),
              SizedBox(height: isPhone ? 16 : 24),
              _buildAdvancedSettings(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequiredFields() {
    return Column(
      children: [
        CompactTextField(
          controller: controller.nameController,
          label: 'Product Name',
          hint: 'Enter product name',
          isRequired: true,
          isPhone: isPhone,
        ),
        SizedBox(height: isPhone ? 16 : 20),
        CompactTextField(
          controller: controller.descriptionController,
          label: 'Description',
          hint: 'Optional product description',
          maxLines: 3,
          isPhone: isPhone,
        ),
        SizedBox(height: isPhone ? 16 : 20),
        CompactTextField(
          controller: controller.basePriceController,
          label: 'Base Unit Price',
          hint: 'Enter base price',
          isRequired: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Base price is required';
            }
            final price = double.tryParse(value);
            if (price == null || price < 0) {
              return 'Enter a valid price';
            }
            return null;
          },
          isPhone: isPhone,
        ),
      ],
    );
  }

  Widget _buildCategoryAndUnit(List<String> categories, List<String> units) {
    return Row(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return CompactDropdown<String>(
                label: 'Category',
                value: controller.selectedCategory,
                items: categories,
                itemLabel: (category) => category,
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedCategory = value;
                  }
                },
                isPhone: isPhone,
              );
            },
          ),
        ),
        SizedBox(width: isPhone ? 12 : 16),
        Expanded(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return CompactDropdown<String>(
                label: 'Unit',
                value: controller.selectedUnit,
                items: units,
                itemLabel: (unit) => unit,
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedUnit = value;
                  }
                },
                isPhone: isPhone,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            return InkWell(
              onTap: () {
                controller.settingsExpanded = !controller.settingsExpanded;
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 12 : 16,
                  vertical: isPhone ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.grey[600],
                      size: isPhone ? 18 : 20,
                    ),
                    SizedBox(width: isPhone ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Advanced Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isPhone ? 14 : 16,
                        ),
                      ),
                    ),
                    Icon(
                      controller.settingsExpanded 
                        ? Icons.expand_less 
                        : Icons.expand_more,
                      color: Colors.grey[600],
                      size: isPhone ? 20 : 24,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            if (!controller.settingsExpanded) {
              return const SizedBox.shrink();
            }
            
            return Container(
              margin: EdgeInsets.only(top: isPhone ? 12 : 16),
              child: Column(
                children: [
                  // NEW: Product Photo Section
                  ProductPhotoSection(controller: controller),
                  SizedBox(height: isPhone ? 12 : 16),
                  // NEW: Inventory Tracking
                  CompactSwitch(
                    label: 'Has Inventory',
                    subtitle: 'Track inventory levels for this product',
                    value: controller.hasInventory,
                    onChanged: (value) {
                      controller.hasInventory = value;
                    },
                    isPhone: isPhone,
                  ),
                  SizedBox(height: isPhone ? 12 : 16),
                  CompactSwitch(
                    label: 'Active Product',
                    subtitle: 'Available for use in quotes',
                    value: controller.isActive,
                    onChanged: (value) {
                      controller.isActive = value;
                    },
                    isPhone: isPhone,
                  ),
                  SizedBox(height: isPhone ? 12 : 16),
                  CompactSwitch(
                    label: 'Discountable',
                    subtitle: 'Can be discounted in quotes',
                    value: controller.isDiscountable,
                    onChanged: (value) {
                      controller.isDiscountable = value;
                    },
                    isPhone: isPhone,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}