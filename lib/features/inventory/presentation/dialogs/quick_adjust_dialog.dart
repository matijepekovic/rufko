import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/inventory_item.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../controllers/inventory_controller.dart';

/// Quick adjustment dialog for adding or removing inventory
/// Simple dialog for quick inventory changes with predefined amounts
class QuickAdjustDialog extends StatefulWidget {
  final InventoryItem inventoryItem;
  final Product product;
  final bool isAdd;

  const QuickAdjustDialog({
    super.key,
    required this.inventoryItem,
    required this.product,
    required this.isAdd,
  });

  @override
  State<QuickAdjustDialog> createState() => _QuickAdjustDialogState();
}

class _QuickAdjustDialogState extends State<QuickAdjustDialog> {
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  int? _selectedPresetAmount;

  // Preset amounts for quick selection
  final List<int> _presetAmounts = [1, 5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _reasonController.text = widget.isAdd ? 'Quick add' : 'Quick remove';
    _selectedPresetAmount = 1;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isPhone ? 16 : 24),
      child: SizedBox(
        width: isPhone ? double.infinity : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isAdd ? Colors.green : Colors.orange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isAdd ? Icons.add : Icons.remove,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAdd ? 'Add Inventory' : 'Remove Inventory',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current stock info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RufkoTheme.strokeColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Stock: ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${widget.inventoryItem.quantity} ${widget.product.unit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preset amount buttons
                  const Text(
                    'Quick Select',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetAmounts.map((amount) {
                      final isSelected = _selectedPresetAmount == amount;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPresetAmount = amount;
                            _quantityController.text = amount.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (widget.isAdd ? Colors.green : Colors.orange)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected 
                                  ? (widget.isAdd ? Colors.green : Colors.orange)
                                  : RufkoTheme.strokeColor,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$amount',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Custom amount input
                  const Text(
                    'Custom Amount',
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
                      hintText: 'Enter amount',
                      suffixText: widget.product.unit,
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
                    onChanged: (value) {
                      final amount = int.tryParse(value);
                      setState(() {
                        _selectedPresetAmount = _presetAmounts.contains(amount) ? amount : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Reason field
                  const Text(
                    'Reason',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Reason for adjustment',
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

                  // Warning for remove when quantity would go negative
                  if (!widget.isAdd) ...[
                    const SizedBox(height: 16),
                    _buildRemoveWarning(),
                  ],

                  // Preview of new quantity
                  const SizedBox(height: 16),
                  _buildQuantityPreview(),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
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
                          : Text(widget.isAdd ? 'Add' : 'Remove'),
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

  Widget _buildRemoveWarning() {
    final quantityText = _quantityController.text;
    final requestedAmount = int.tryParse(quantityText) ?? 0;
    final currentStock = widget.inventoryItem.quantity;
    
    if (requestedAmount > currentStock) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cannot remove $requestedAmount ${widget.product.unit}. Only $currentStock available.',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildQuantityPreview() {
    final quantityText = _quantityController.text;
    final amount = int.tryParse(quantityText) ?? 0;
    final currentStock = widget.inventoryItem.quantity;
    final newQuantity = widget.isAdd ? currentStock + amount : currentStock - amount;
    
    Color previewColor = Colors.grey[600]!;
    IconData previewIcon = Icons.inventory;
    
    if (newQuantity <= 0) {
      previewColor = Colors.red;
      previewIcon = Icons.warning;
    } else if (widget.inventoryItem.minimumStock != null && newQuantity <= widget.inventoryItem.minimumStock!) {
      previewColor = Colors.orange;
      previewIcon = Icons.warning_amber;
    } else {
      previewColor = Colors.green;
      previewIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: previewColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: previewColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            previewIcon,
            color: previewColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'New Stock: ',
            style: TextStyle(
              color: previewColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$newQuantity ${widget.product.unit}',
            style: TextStyle(
              color: previewColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final quantityText = _quantityController.text.trim();
    final reason = _reasonController.text.trim();

    if (quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = int.tryParse(quantityText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if removing more than available
    if (!widget.isAdd && amount > widget.inventoryItem.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove $amount ${widget.product.unit}. Only ${widget.inventoryItem.quantity} available.'),
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
      bool success;

      if (widget.isAdd) {
        success = await controller.quickAddInventory(
          inventoryItemId: widget.inventoryItem.id,
          quantityToAdd: amount,
          reason: reason,
        );
      } else {
        success = await controller.quickRemoveInventory(
          inventoryItemId: widget.inventoryItem.id,
          quantityToRemove: amount,
          reason: reason,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isAdd 
                  ? 'Added $amount ${widget.product.unit} to inventory'
                  : 'Removed $amount ${widget.product.unit} from inventory'),
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