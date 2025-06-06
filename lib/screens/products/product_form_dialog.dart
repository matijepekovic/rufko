import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/app_state_provider.dart';
class ProductFormDialog extends StatefulWidget {
  final Product? product;
  const ProductFormDialog({this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Basic info controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();

  // Basic info state
  String _selectedCategory = 'Materials';
  String _selectedUnit = 'each';
  bool _isActive = true;
  bool _isDiscountable = true;

  // 3-Tier System State
  ProductPricingType _pricingType = ProductPricingType.simple;
  bool _isMainDifferentiator = false;

  // Level pricing controllers
  final Map<String, TextEditingController> _levelPriceControllers = {};
  final Map<String, TextEditingController> _levelNameControllers = {};
  final Map<String, TextEditingController> _levelDescriptionControllers = {};
  List<String> _currentLevelKeys = [];
  bool _isInitialized = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFormData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _levelPriceControllers.forEach((_, controller) => controller.dispose());
    _levelNameControllers.forEach((_, controller) => controller.dispose());
    _levelDescriptionControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;

        return Dialog(
          insetPadding: EdgeInsets.all(isPhone ? 8 : 16),
          child: Container(
            width: isPhone ? constraints.maxWidth * 0.98 : 600,
            height: isPhone ? constraints.maxHeight * 0.92 : constraints.maxHeight * 0.85,
            child: Column(
              children: [
                _buildHeader(isPhone),
                _buildTabBar(isPhone),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBasicInfoTab(isPhone),
                        _buildProductTypeTab(isPhone),
                        _buildPricingLevelsTab(isPhone),
                      ],
                    ),
                  ),
                ),
                _buildFooter(isPhone),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit_note : Icons.add_box,
            color: Theme.of(context).primaryColor,
            size: isPhone ? 20 : 24,
          ),
          SizedBox(width: isPhone ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Product' : 'Create New Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 16 : 18,
                  ),
                ),
                Text(
                  _getPricingTypeDescription(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isPhone ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            iconSize: isPhone ? 20 : 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isPhone) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
        tabs: [
          Tab(icon: Icon(Icons.info_outline, size: isPhone ? 16 : 18), text: 'Basic Info'),
          Tab(icon: Icon(Icons.tune, size: isPhone ? 16 : 18), text: 'Product Type'),
          Tab(icon: Icon(Icons.layers_outlined, size: isPhone ? 16 : 18), text: 'Pricing Levels'),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isPhone) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final categories = appState.appSettings?.productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
        final units = appState.appSettings?.productUnits ?? ['each', 'sq ft', 'lin ft', 'hour', 'day'];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isPhone ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernTextField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.label_outline,
                isPhone: isPhone,
                validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
              ),
              SizedBox(height: isPhone ? 16 : 20),
              _buildModernTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.notes,
                isPhone: isPhone,
                maxLines: isPhone ? 2 : 3,
                hint: 'Describe what this product is and its key features...',
              ),
              SizedBox(height: isPhone ? 16 : 20),
              _buildModernTextField(
                controller: _basePriceController,
                label: 'Base Unit Price',
                icon: Icons.attach_money,
                isPhone: isPhone,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || (double.tryParse(v) == null || double.parse(v) < 0) ? 'Enter a valid price' : null,
              ),
              SizedBox(height: isPhone ? 16 : 20),
              Row(
                children: [
                  Expanded(
                    child: _buildModernDropdown<String>(
                      value: _selectedCategory,
                      label: 'Category',
                      icon: Icons.category,
                      items: categories,
                      isPhone: isPhone,
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  SizedBox(width: isPhone ? 12 : 16),
                  Expanded(
                    child: _buildModernDropdown<String>(
                      value: _selectedUnit,
                      label: 'Unit',
                      icon: Icons.straighten,
                      items: units,
                      isPhone: isPhone,
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isPhone ? 24 : 32),
              Text(
                'Product Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: isPhone ? 16 : 18,
                ),
              ),
              SizedBox(height: isPhone ? 16 : 20),
              _buildModernSwitch(
                title: 'Active Product',
                subtitle: 'Available for use in quotes and estimates',
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                icon: Icons.visibility,
                isPhone: isPhone,
              ),
              SizedBox(height: isPhone ? 16 : 20),
              _buildModernSwitch(
                title: 'Discountable Product',
                subtitle: 'Can be affected by quote discounts and promotions',
                value: _isDiscountable,
                onChanged: (v) => setState(() => _isDiscountable = v),
                icon: Icons.local_offer_outlined,
                isPhone: isPhone,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductTypeTab(bool isPhone) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isPhone ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Choose Product Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isPhone ? 18 : 22,
            ),
          ),
          SizedBox(height: isPhone ? 8 : 12),
          Text(
            'Select how this product behaves in quotes:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: isPhone ? 14 : 16,
            ),
          ),
          SizedBox(height: isPhone ? 24 : 32),

          _buildProductTypeCard(
            type: ProductPricingType.mainDifferentiator,
            title: '🏠 Main Differentiator',
            subtitle: 'Sets quote column headers',
            description: 'Creates Builder/Homeowner/Platinum columns.\nExample: Roofing Shingles with different quality levels.',
            color: Colors.blue,
            example: 'Builder (\$120) | Homeowner (\$180) | Platinum (\$240)',
            isPhone: isPhone,
          ),
          SizedBox(height: isPhone ? 16 : 20),

          _buildProductTypeCard(
            type: ProductPricingType.subLeveled,
            title: '🌧️ Sub-Leveled Options',
            subtitle: 'Independent internal choices',
            description: 'Customer picks ONE option regardless of main product level.\nExample: Gutters with/without mesh.',
            color: Colors.orange,
            example: 'Basic Gutters (\$8) OR Mesh Gutters (\$18)',
            isPhone: isPhone,
          ),
          SizedBox(height: isPhone ? 16 : 20),

          _buildProductTypeCard(
            type: ProductPricingType.simple,
            title: '👷 Simple Product',
            subtitle: 'Same price everywhere',
            description: 'One price used across all quote levels.\nExample: Labor, nails, installation.',
            color: Colors.green,
            example: 'Labor: \$85/hour (same for all roof types)',
            isPhone: isPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingLevelsTab(bool isPhone) {
    if (_pricingType == ProductPricingType.simple) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isPhone ? 60 : 80),
            Icon(Icons.check_circle, size: isPhone ? 64 : 80, color: Colors.green.shade400),
            SizedBox(height: isPhone ? 16 : 24),
            Text(
              'Simple Product Selected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 18 : 22,
              ),
            ),
            SizedBox(height: isPhone ? 8 : 12),
            Text(
              'This product uses the base price across all quote levels.\nNo additional configuration needed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: isPhone ? 14 : 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isPhone ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isPhone ? 8 : 10),
                decoration: BoxDecoration(
                  color: _getPricingTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.layers, color: _getPricingTypeColor(), size: isPhone ? 20 : 24),
              ),
              SizedBox(width: isPhone ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pricingType == ProductPricingType.mainDifferentiator
                          ? 'Main Differentiator Levels'
                          : 'Sub-Level Options',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isPhone ? 18 : 22,
                      ),
                    ),
                    Text(
                      _pricingType == ProductPricingType.mainDifferentiator
                          ? 'These create the quote column headers'
                          : 'Customer picks ONE of these options',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isPhone ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isPhone ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: isPhone ? 16 : 18),
                SizedBox(width: isPhone ? 8 : 12),
                Expanded(
                  child: Text(
                    _pricingType == ProductPricingType.mainDifferentiator
                        ? 'These levels appear as separate columns in quotes for side-by-side comparison.'
                        : 'Customer chooses one option independent of the main product level.',
                    style: TextStyle(
                      fontSize: isPhone ? 12 : 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isPhone ? 24 : 32),

          // Level configuration cards
          ...List.generate(_currentLevelKeys.length, (index) {
            final levelKey = _currentLevelKeys[index];
            final cardColor = _getLevelCardColor(index);

            return Container(
              margin: EdgeInsets.only(bottom: isPhone ? 16 : 20),
              decoration: BoxDecoration(
                border: Border.all(color: cardColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                color: cardColor.withOpacity(0.05),
              ),
              child: Column(
                children: [
                  // Card header
                  Container(
                    padding: EdgeInsets.all(isPhone ? 16 : 20),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isPhone ? 32 : 36,
                          height: isPhone ? 32 : 36,
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                                fontSize: isPhone ? 14 : 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isPhone ? 12 : 16),
                        Expanded(
                          child: Text(
                            _pricingType == ProductPricingType.mainDifferentiator
                                ? 'Level ${index + 1} Configuration'
                                : 'Option ${index + 1} Configuration',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cardColor,
                              fontSize: isPhone ? 15 : 17,
                            ),
                          ),
                        ),
                        if (_currentLevelKeys.length > 1)
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400, size: isPhone ? 20 : 24),
                            onPressed: () => _removeLevel(index),
                            tooltip: 'Remove this level',
                          ),
                      ],
                    ),
                  ),

                  // Card content
                  Padding(
                    padding: EdgeInsets.all(isPhone ? 16 : 20),
                    child: Column(
                      children: [
                        // Level name
                        TextFormField(
                          controller: _levelNameControllers[levelKey],
                          decoration: InputDecoration(
                            labelText: _pricingType == ProductPricingType.mainDifferentiator ? 'Level Name' : 'Option Name',
                            hintText: _pricingType == ProductPricingType.mainDifferentiator ? 'Builder Grade' : 'Basic Version',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_outline, color: cardColor, size: isPhone ? 18 : 20),
                            helperText: _pricingType == ProductPricingType.mainDifferentiator
                                ? 'This name appears as column header'
                                : 'Customer sees this option name',
                            helperStyle: TextStyle(fontSize: isPhone ? 11 : 12),
                            labelStyle: TextStyle(fontSize: isPhone ? 14 : 16),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 12 : 16,
                              vertical: isPhone ? 12 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: isPhone ? 14 : 16),
                          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        SizedBox(height: isPhone ? 16 : 20),

                        // Level description
                        TextFormField(
                          controller: _levelDescriptionControllers[levelKey],
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Describe what makes this different...',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description_outlined, color: cardColor, size: isPhone ? 18 : 20),
                            helperText: 'Explains value differences to customers',
                            helperStyle: TextStyle(fontSize: isPhone ? 11 : 12),
                            labelStyle: TextStyle(fontSize: isPhone ? 14 : 16),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 12 : 16,
                              vertical: isPhone ? 12 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: isPhone ? 14 : 16),
                          maxLines: 2,
                        ),
                        SizedBox(height: isPhone ? 16 : 20),

                        // Level price
                        TextFormField(
                          controller: _levelPriceControllers[levelKey],
                          decoration: InputDecoration(
                            labelText: 'Price',
                            prefixText: '\$ ',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money, color: cardColor, size: isPhone ? 18 : 20),
                            hintText: _basePriceController.text.isNotEmpty
                                ? 'Defaults to \$${_basePriceController.text}'
                                : 'e.g. 150.00',
                            helperText: 'Leave empty to use base price',
                            helperStyle: TextStyle(fontSize: isPhone ? 11 : 12),
                            labelStyle: TextStyle(fontSize: isPhone ? 14 : 16),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 12 : 16,
                              vertical: isPhone ? 12 : 16,
                            ),
                          ),
                          style: TextStyle(fontSize: isPhone ? 14 : 16),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final price = double.tryParse(v);
                              if (price == null || price < 0) {
                                return 'Enter a valid price';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Add/Remove level controls
          SizedBox(height: isPhone ? 16 : 20),
          _buildLevelControls(isPhone),
        ],
      ),
    );
  }


  Widget _buildLevelControls(bool isPhone) {
    final maxLevels = _pricingType == ProductPricingType.mainDifferentiator ? 6 : 4;
    final minLevels = _pricingType == ProductPricingType.mainDifferentiator ? 2 : 2;

    return Row(
      children: [
        if (_currentLevelKeys.length > minLevels)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _removeLevel(_currentLevelKeys.length - 1),
              icon: Icon(Icons.remove, size: isPhone ? 16 : 18),
              label: Text(
                'Remove (${_currentLevelKeys.length} total)',
                style: TextStyle(fontSize: isPhone ? 12 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 8 : 12,
                  vertical: isPhone ? 6 : 8,
                ),
              ),
            ),
          ),
        if (_currentLevelKeys.length > minLevels) SizedBox(width: isPhone ? 8 : 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentLevelKeys.length < maxLevels ? _addLevel : null,
            icon: Icon(Icons.add, size: isPhone ? 16 : 18),
            label: Text(
              'Add ${_pricingType == ProductPricingType.mainDifferentiator ? 'Level' : 'Option'} (${_currentLevelKeys.length}/$maxLevels)',
              style: TextStyle(fontSize: isPhone ? 12 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 8 : 12,
                vertical: isPhone ? 6 : 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isPhone) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16 : 20,
                vertical: isPhone ? 8 : 12,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isPhone ? 13 : 15),
            ),
          ),
          SizedBox(width: isPhone ? 8 : 12),
          ElevatedButton.icon(
            onPressed: _saveProduct,
            icon: Icon(_isEditing ? Icons.update : Icons.add, size: isPhone ? 16 : 18),
            label: Text(
              _isEditing ? 'Update Product' : 'Create Product',
              style: TextStyle(fontSize: isPhone ? 13 : 15),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16 : 20,
                vertical: isPhone ? 8 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // All the helper methods and widget builders continue here...
  Widget _buildProductTypeCard({
    required ProductPricingType type,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required String example,
    required bool isPhone,
  }) {
    final isSelected = _pricingType == type;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 16),
      child: InkWell(
        onTap: () => _setPricingType(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isPhone ? 14 : 18),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withOpacity(0.05) : Colors.white,
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isPhone ? 8 : 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: color,
                      size: isPhone ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isPhone ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isPhone ? 15 : 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.black87,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: isPhone ? 12 : 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isPhone ? 12 : 16),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: isPhone ? 13 : 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              SizedBox(height: isPhone ? 10 : 12),

              // Example
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isPhone ? 10 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example:',
                      style: TextStyle(
                        fontSize: isPhone ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: isPhone ? 4 : 6),
                    Text(
                      example,
                      style: TextStyle(
                        fontSize: isPhone ? 11 : 12,
                        fontFamily: 'monospace',
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Selected indicator
              if (isSelected) ...[
                SizedBox(height: isPhone ? 8 : 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: color, size: isPhone ? 16 : 18),
                    SizedBox(width: isPhone ? 4 : 6),
                    Text(
                      'SELECTED',
                      style: TextStyle(
                        fontSize: isPhone ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPhone,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7), size: isPhone ? 18 : 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPhone ? 8 : 10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isPhone ? 8 : 12,
          vertical: isPhone ? 8 : 12,
        ),
      ),
      style: TextStyle(fontSize: isPhone ? 13 : 15),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildModernDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required bool isPhone,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7), size: isPhone ? 18 : 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(isPhone ? 8 : 10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(fontSize: isPhone ? 12 : 14),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isPhone ? 8 : 12,
          vertical: isPhone ? 8 : 12,
        ),
      ),
      style: TextStyle(fontSize: isPhone ? 13 : 15, color: Colors.black),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isPhone,
  }) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 6 : 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: isPhone ? 16 : 20),
          ),
          SizedBox(width: isPhone ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isPhone ? 14 : 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isPhone ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _getPricingTypeDescription() {
    switch (_pricingType) {
      case ProductPricingType.mainDifferentiator:
        return 'Main differentiator - sets quote column headers';
      case ProductPricingType.subLeveled:
        return 'Sub-leveled - independent customer choices';
      case ProductPricingType.simple:
        return 'Simple product - same price everywhere';
    }
  }

  Color _getPricingTypeColor() {
    switch (_pricingType) {
      case ProductPricingType.mainDifferentiator:
        return Colors.blue.shade600;
      case ProductPricingType.subLeveled:
        return Colors.orange.shade600;
      case ProductPricingType.simple:
        return Colors.green.shade600;
    }
  }

  Color _getLevelCardColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];
    return colors[index % colors.length];
  }

  void _setPricingType(ProductPricingType type) {
    setState(() {
      _pricingType = type;
      _isMainDifferentiator = (type == ProductPricingType.mainDifferentiator);

      if (type == ProductPricingType.simple) {
        _currentLevelKeys.clear();
      } else {
        if (type == ProductPricingType.mainDifferentiator) {
          final appState = context.read<AppStateProvider>();
          final settingsLevels = appState.appSettings?.defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'];
          _currentLevelKeys = settingsLevels.map((name) => name.toLowerCase().replaceAll(' ', '_')).toList();
        } else {
          _currentLevelKeys = ['option_1', 'option_2'];
        }
        _initializeLevelControllers();
      }
    });
  }

  void _addLevel() {
    final maxLevels = _pricingType == ProductPricingType.mainDifferentiator ? 6 : 4;
    if (_currentLevelKeys.length < maxLevels) {
      setState(() {
        final newKey = '${_pricingType == ProductPricingType.mainDifferentiator ? 'level' : 'option'}_${DateTime.now().millisecondsSinceEpoch}';
        _currentLevelKeys.add(newKey);
        _levelPriceControllers[newKey] = TextEditingController();
        _levelNameControllers[newKey] = TextEditingController(
            text: '${_pricingType == ProductPricingType.mainDifferentiator ? 'Level' : 'Option'} ${_currentLevelKeys.length}'
        );
        _levelDescriptionControllers[newKey] = TextEditingController();
      });
    }
  }

  void _removeLevel(int index) {
    final minLevels = 2;
    if (_currentLevelKeys.length > minLevels && index < _currentLevelKeys.length) {
      setState(() {
        final keyToRemove = _currentLevelKeys[index];
        _currentLevelKeys.removeAt(index);
        _levelPriceControllers[keyToRemove]?.dispose();
        _levelNameControllers[keyToRemove]?.dispose();
        _levelDescriptionControllers[keyToRemove]?.dispose();
        _levelPriceControllers.remove(keyToRemove);
        _levelNameControllers.remove(keyToRemove);
        _levelDescriptionControllers.remove(keyToRemove);
      });
    }
  }

  void _initializeFormData() {
    if (_isInitialized) return;
    _isInitialized = true;

    final appState = context.read<AppStateProvider>();
    final categories = appState.appSettings?.productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'];
    final settingsLevels = appState.appSettings?.defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'];

    if (_isEditing && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _basePriceController.text = p.unitPrice.toStringAsFixed(2);
      _selectedCategory = categories.contains(p.category) ? p.category : categories.first;
      _selectedUnit = p.unit;
      _isActive = p.isActive;
      _isDiscountable = p.isDiscountable;
      _pricingType = p.pricingType;
      _isMainDifferentiator = p.isMainDifferentiator;

      _currentLevelKeys = p.enhancedLevelPrices.map((level) => level.levelId).toList();
      if (_currentLevelKeys.isEmpty && _pricingType != ProductPricingType.simple) {
        if (_pricingType == ProductPricingType.mainDifferentiator) {
          _currentLevelKeys = settingsLevels.map((name) => name.toLowerCase().replaceAll(' ', '_')).toList();
        } else {
          _currentLevelKeys = ['option_1', 'option_2'];
        }
      }

      _initializeLevelControllers();

      for (final levelPrice in p.enhancedLevelPrices) {
        final key = levelPrice.levelId;
        if (_levelPriceControllers.containsKey(key)) {
          _levelPriceControllers[key]!.text = levelPrice.price.toStringAsFixed(2);
          _levelNameControllers[key]!.text = levelPrice.levelName;
          _levelDescriptionControllers[key]!.text = levelPrice.description ?? '';
        }
      }
    } else {
      _selectedCategory = categories.first;
      _pricingType = ProductPricingType.simple;
    }
  }

  void _initializeLevelControllers() {
    _levelPriceControllers.forEach((_, controller) => controller.dispose());
    _levelNameControllers.forEach((_, controller) => controller.dispose());
    _levelDescriptionControllers.forEach((_, controller) => controller.dispose());
    _levelPriceControllers.clear();
    _levelNameControllers.clear();
    _levelDescriptionControllers.clear();

    for (int i = 0; i < _currentLevelKeys.length; i++) {
      final key = _currentLevelKeys[i];
      _levelPriceControllers[key] = TextEditingController();
      _levelNameControllers[key] = TextEditingController();
      _levelDescriptionControllers[key] = TextEditingController();

      if (_pricingType == ProductPricingType.mainDifferentiator) {
        final appState = context.read<AppStateProvider>();
        final settingsLevels = appState.appSettings?.defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'];
        if (i < settingsLevels.length) {
          _levelNameControllers[key]!.text = settingsLevels[i];
        }
      } else if (_pricingType == ProductPricingType.subLeveled) {
        _levelNameControllers[key]!.text = 'Option ${i + 1}';
      }
    }
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      if (_nameController.text.isEmpty || _basePriceController.text.isEmpty) {
        _tabController.animateTo(0);
      } else if (_pricingType != ProductPricingType.simple && _currentLevelKeys.any((key) => _levelNameControllers[key]?.text.isEmpty ?? true)) {
        _tabController.animateTo(2);
      }
      return;
    }

    final appState = context.read<AppStateProvider>();
    final basePriceText = _basePriceController.text.trim();
    final basePrice = double.tryParse(basePriceText) ?? 0.0;

    List<ProductLevelPrice> enhancedLevelPrices = [];
    if (_pricingType != ProductPricingType.simple) {
      for (final key in _currentLevelKeys) {
        final name = _levelNameControllers[key]?.text.trim() ?? 'Level';
        final description = _levelDescriptionControllers[key]?.text.trim();
        final priceText = _levelPriceControllers[key]?.text.trim() ?? '';
        final price = double.tryParse(priceText) ?? basePrice;

        if (name.isNotEmpty) {
          enhancedLevelPrices.add(ProductLevelPrice(
            levelId: key,
            levelName: name,
            price: price,
            description: description?.isEmpty ?? true ? null : description,
            isActive: true,
          ));
        }
      }
    }

    if (_isEditing && widget.product != null) {
      widget.product!.updateInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: basePrice,
        unit: _selectedUnit,
        category: _selectedCategory,
        isActive: _isActive,
        isDiscountable: _isDiscountable,
        isMainDifferentiator: _isMainDifferentiator,
        enableLevelPricing: _pricingType != ProductPricingType.simple,
      );

      widget.product!.enhancedLevelPrices.clear();
      widget.product!.enhancedLevelPrices.addAll(enhancedLevelPrices);
      widget.product!.pricingType = _pricingType;

      appState.updateProduct(widget.product!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
      );
    } else {
      final newProduct = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: basePrice,
        unit: _selectedUnit,
        category: _selectedCategory,
        isActive: _isActive,
        isDiscountable: _isDiscountable,
        isMainDifferentiator: _isMainDifferentiator,
        enableLevelPricing: _pricingType != ProductPricingType.simple,
        pricingType: _pricingType,
        enhancedLevelPrices: enhancedLevelPrices,
      );

      appState.addProduct(newProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully!'), backgroundColor: Colors.green),
      );
    }

    Navigator.pop(context);
  }

}

