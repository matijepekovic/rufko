import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/product.dart';
import '../../../../data/models/business/inventory_item.dart';
import '../../../../data/models/business/inventory_transaction.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_form_dialog.dart';
import 'quick_adjust_dialog.dart';

/// Detailed view of inventory item with transaction history
/// Shows complete information about an inventory item and allows editing
class InventoryDetailsDialog extends StatefulWidget {
  final InventoryItem inventoryItem;
  final Product product;

  const InventoryDetailsDialog({
    super.key,
    required this.inventoryItem,
    required this.product,
  });

  @override
  State<InventoryDetailsDialog> createState() => _InventoryDetailsDialogState();
}

class _InventoryDetailsDialogState extends State<InventoryDetailsDialog> {
  late InventoryController _controller;
  List<InventoryTransaction> _transactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController();
    _loadTransactions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final transactions = await _controller.getTransactionsForItem(widget.inventoryItem.id);
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isPhone ? 16 : 24),
      child: Container(
        width: isPhone ? double.infinity : 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
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
                  const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inventory Details',
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
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab bar
                    const TabBar(
                      tabs: [
                        Tab(text: 'Details'),
                        Tab(text: 'History'),
                      ],
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildDetailsTab(),
                          _buildHistoryTab(),
                        ],
                      ),
                    ),
                  ],
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
                      onPressed: () => _showQuickAdjustDialog(false),
                      icon: Icons.remove,
                      child: const Text('Remove'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RufkoPrimaryButton(
                      onPressed: () => _showQuickAdjustDialog(true),
                      icon: Icons.add,
                      child: const Text('Add'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _showEditDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: RufkoTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock overview
          _buildStockOverview(),
          const SizedBox(height: 24),

          // Product information
          _buildProductInformation(),
          const SizedBox(height: 24),

          // Storage information
          _buildStorageInformation(),
        ],
      ),
    );
  }

  Widget _buildStockOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RufkoTheme.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Stock',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Quantity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.inventoryItem.quantity} ${widget.product.unit}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          if (widget.inventoryItem.minimumStock != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: widget.inventoryItem.isLowStock 
                      ? Colors.red 
                      : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Minimum Stock: ${widget.inventoryItem.minimumStock} ${widget.product.unit}',
                  style: TextStyle(
                    color: widget.inventoryItem.isLowStock 
                        ? Colors.red 
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          Text(
            'Last updated: ${_formatDate(widget.inventoryItem.lastUpdated)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Category', widget.product.category),
        _buildInfoRow('Unit', widget.product.unit),
        if (widget.product.unitPrice > 0)
          _buildInfoRow('Unit Price', NumberFormat.currency(symbol: '\$').format(widget.product.unitPrice)),
        if (widget.product.description != null && widget.product.description!.isNotEmpty)
          _buildInfoRow('Description', widget.product.description!),
      ],
    );
  }

  Widget _buildStorageInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Storage Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.inventoryItem.location != null && widget.inventoryItem.location!.isNotEmpty)
          _buildInfoRow('Location', widget.inventoryItem.location!)
        else
          _buildInfoRow('Location', 'Not specified'),
        
        if (widget.inventoryItem.notes != null && widget.inventoryItem.notes!.isNotEmpty)
          _buildInfoRow('Notes', widget.inventoryItem.notes!)
        else
          _buildInfoRow('Notes', 'No notes'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inventory changes will appear here',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(InventoryTransaction transaction) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (transaction.type) {
      case InventoryTransactionType.add:
        icon = Icons.add_circle;
        color = Colors.green;
        title = 'Added ${transaction.quantity} ${widget.product.unit}';
        subtitle = '${transaction.previousQuantity} → ${transaction.newQuantity}';
        break;
      case InventoryTransactionType.remove:
        icon = Icons.remove_circle;
        color = Colors.red;
        title = 'Removed ${transaction.quantity.abs()} ${widget.product.unit}';
        subtitle = '${transaction.previousQuantity} → ${transaction.newQuantity}';
        break;
      case InventoryTransactionType.adjust:
        icon = Icons.tune;
        color = Colors.blue;
        title = 'Adjusted to ${transaction.newQuantity} ${widget.product.unit}';
        subtitle = '${transaction.previousQuantity} → ${transaction.newQuantity}';
        break;
      case InventoryTransactionType.initial:
        icon = Icons.inventory_2;
        color = Colors.purple;
        title = 'Initial stock set to ${transaction.newQuantity} ${widget.product.unit}';
        subtitle = 'Starting inventory';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (transaction.reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transaction.reason,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          _formatDateTime(transaction.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.inventoryItem.isOutOfStock) {
      return Colors.red;
    } else if (widget.inventoryItem.isLowStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (widget.inventoryItem.isOutOfStock) {
      return 'OUT OF STOCK';
    } else if (widget.inventoryItem.isLowStock) {
      return 'LOW STOCK';
    } else {
      return 'IN STOCK';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date);
  }

  void _showQuickAdjustDialog(bool isAdd) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickAdjustDialog(
        inventoryItem: widget.inventoryItem,
        product: widget.product,
        isAdd: isAdd,
      ),
    );

    if (result == true) {
      // Refresh the dialog data if needed
      _loadTransactions();
    }
  }

  void _showEditDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InventoryFormDialog(
        initialProduct: widget.product,
        existingInventory: widget.inventoryItem,
      ),
    );

    if (result == true) {
      // Refresh the dialog data if needed
      _loadTransactions();
      // Close this dialog and let the parent refresh
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}