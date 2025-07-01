import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/inventory_item.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../../products/presentation/widgets/form_components/compact_switch.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../controllers/inventory_controller.dart';

/// Dialog for adding inventory to a product
/// Allows selecting product, setting initial quantity, location, and minimum stock
class InventoryFormDialog extends StatefulWidget {
  final Product? initialProduct;
  final InventoryItem? existingInventory;

  const InventoryFormDialog({
    super.key,
    this.initialProduct,
    this.existingInventory,
  });

  @override
  State<InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _minimumStockController = TextEditingController();

  Product? _selectedProduct;
  bool _trackMinimumStock = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.initialProduct;
    
    if (widget.existingInventory != null) {
      final inventory = widget.existingInventory!;
      _quantityController.text = inventory.quantity.toString();
      _locationController.text = inventory.location ?? '';
      _notesController.text = inventory.notes ?? '';
      if (inventory.minimumStock != null) {
        _trackMinimumStock = true;
        _minimumStockController.text = inventory.minimumStock.toString();
      }
      _reasonController.text = 'Inventory adjustment';
    } else {
      _reasonController.text = 'Initial inventory';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final isEditing = widget.existingInventory != null;

    return Dialog(
      insetPadding: EdgeInsets.all(isPhone ? 16 : 24),
      child: Container(
        width: isPhone ? double.infinity : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: RufkoTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Inventory' : 'Add Inventory',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product selection (only for new inventory)
                      if (!isEditing) ...[
                        _buildProductSelection(),
                        const SizedBox(height: 20),
                      ],

                      // Quantity
                      _buildQuantityField(),
                      const SizedBox(height: 16),

                      // Reason
                      _buildReasonField(),
                      const SizedBox(height: 16),

                      // Location
                      _buildLocationField(),
                      const SizedBox(height: 16),

                      // Notes
                      _buildNotesField(),
                      const SizedBox(height: 20),

                      // Minimum stock tracking
                      CompactSwitch(
                        label: 'Track Minimum Stock',
                        subtitle: 'Get alerts when inventory runs low',
                        value: _trackMinimumStock,
                        onChanged: (value) {
                          setState(() {
                            _trackMinimumStock = value;
                            if (!value) {
                              _minimumStockController.clear();
                            }
                          });
                        },
                        isPhone: isPhone,
                      ),

                      if (_trackMinimumStock) ...[
                        const SizedBox(height: 16),
                        _buildMinimumStockField(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: RufkoTheme.strokeColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RufkoSecondaryButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RufkoPrimaryButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Update' : 'Add'),
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

  Widget _buildProductSelection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final products = appState.products.where((p) => p.hasInventory).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: InputDecoration(
                hintText: 'Select a product',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: RufkoTheme.strokeColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: RufkoTheme.strokeColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: products.map((product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text(
                    '${product.name} (${product.category})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a product';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            suffixText: _selectedProduct?.unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a quantity';
            }
            final quantity = int.tryParse(value);
            if (quantity == null || quantity < 0) {
              return 'Please enter a valid quantity';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: 'Reason for inventory change',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Storage location (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Additional notes (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimumStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Minimum Stock Level',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _minimumStockController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Alert when stock falls below this level',
            suffixText: _selectedProduct?.unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RufkoTheme.strokeColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (_trackMinimumStock && (value == null || value.isEmpty)) {
              return 'Please enter minimum stock level';
            }
            if (value != null && value.isNotEmpty) {
              final minStock = int.tryParse(value);
              if (minStock == null || minStock < 0) {
                return 'Please enter a valid minimum stock level';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = InventoryController();
      final quantity = int.parse(_quantityController.text);
      final reason = _reasonController.text.trim();
      final location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      final minimumStock = _trackMinimumStock && _minimumStockController.text.isNotEmpty
          ? int.parse(_minimumStockController.text)
          : null;

      bool success;
      if (widget.existingInventory != null) {
        // Update existing inventory
        success = await controller.adjustInventory(
          inventoryItemId: widget.existingInventory!.id,
          newQuantity: quantity,
          reason: reason,
        );
      } else {
        // Add new inventory
        success = await controller.addInventory(
          productId: _selectedProduct!.id,
          quantity: quantity,
          reason: reason,
          location: location,
          notes: notes,
          minimumStock: minimumStock,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingInventory != null
                  ? 'Inventory updated successfully'
                  : 'Inventory added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}