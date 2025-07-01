import 'package:flutter/material.dart';

import '../../../../data/models/business/product.dart';
import '../controllers/product_form_controller.dart';
import '../widgets/tabs/basic_info_tab.dart';
import '../widgets/tabs/product_type_tab.dart';
import '../widgets/tabs/pricing_levels_tab.dart';

/// ProductFormDialog widget for creating and editing products
/// Refactored from original 1,337-line monolithic file to use extracted components
/// All original functionality preserved with improved maintainability and testability
class ProductFormDialog extends StatefulWidget {
  final Product? product;
  
  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ProductFormController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = ProductFormController(
      context: context,
      initialProduct: widget.product,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;

        return Dialog(
          insetPadding: EdgeInsets.all(isPhone ? 4 : 16),
          child: SizedBox(
            width: isPhone ? constraints.maxWidth * 0.98 : 600,
            height: isPhone ? constraints.maxHeight * 0.95 : constraints.maxHeight * 0.85,
            child: Column(
              children: [
                _buildHeader(isPhone),
                _buildTabBar(isPhone),
                Expanded(
                  child: Form(
                    key: _controller.formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Basic Info Tab - extracted to BasicInfoTab widget
                        BasicInfoTab(
                          controller: _controller,
                          isPhone: isPhone,
                        ),
                        // Product Type Tab - extracted to ProductTypeTab widget
                        ProductTypeTab(
                          controller: _controller,
                          isPhone: isPhone,
                        ),
                        // Pricing Levels Tab - extracted to PricingLevelsTab widget
                        PricingLevelsTab(
                          controller: _controller,
                          isPhone: isPhone,
                        ),
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

  /// Build dialog header with title and close button
  Widget _buildHeader(bool isPhone) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 8 : 16,
        vertical: isPhone ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _controller.isEditing ? Icons.edit_note : Icons.add_box,
            color: Theme.of(context).primaryColor,
            size: isPhone ? 18 : 24,
          ),
          SizedBox(width: isPhone ? 6 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.isEditing ? 'Edit Product' : 'Create New Product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 14 : 18,
                  ),
                ),
                if (!isPhone)
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      return Text(
                        _controller.getPricingTypeDescription(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            iconSize: isPhone ? 18 : 24,
            padding: EdgeInsets.all(isPhone ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isPhone ? 32 : 40,
              minHeight: isPhone ? 32 : 40,
            ),
          ),
        ],
      ),
    );
  }

  /// Build tab bar for navigation between form sections
  Widget _buildTabBar(bool isPhone) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(fontSize: isPhone ? 16 : 20, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: isPhone ? 18 : 22),
        tabs: [
          Tab(
            icon: Icon(Icons.info_outline, size: isPhone ? 16 : 20),
            text: isPhone ? 'Info' : 'Basic Info',
          ),
          Tab(
            icon: Icon(Icons.tune, size: isPhone ? 16 : 20),
            text: isPhone ? 'Type' : 'Product Type',
          ),
          Tab(
            icon: Icon(Icons.layers_outlined, size: isPhone ? 16 : 20),
            text: isPhone ? 'Levels' : 'Pricing Levels',
          ),
        ],
      ),
    );
  }

  /// Build footer with cancel and save buttons
  Widget _buildFooter(bool isPhone) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 20,
        vertical: isPhone ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16 : 24,
                vertical: isPhone ? 8 : 12,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isPhone ? 14 : 16),
            ),
          ),
          ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16 : 24,
                vertical: isPhone ? 8 : 12,
              ),
            ),
            child: Text(
              _controller.isEditing ? 'Update Product' : 'Create Product',
              style: TextStyle(fontSize: isPhone ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle save button press with validation and error handling
  Future<void> _handleSave() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _controller.saveProduct();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (success) {
          Navigator.pop(context, true); // Close form dialog with success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _controller.isEditing 
                  ? 'Product updated successfully!' 
                  : 'Product created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check the form for errors'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}