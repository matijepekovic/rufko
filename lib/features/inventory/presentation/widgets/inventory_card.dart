import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/inventory_item.dart';
import '../../../../data/models/business/product.dart';

/// Card widget for displaying inventory item information
/// Shows product details, quantity, and quick action buttons
class InventoryCard extends StatelessWidget {
  final InventoryItem inventoryItem;
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onQuickRemove;

  const InventoryCard({
    super.key,
    required this.inventoryItem,
    required this.product,
    this.onTap,
    this.onQuickAdd,
    this.onQuickRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(context),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildQuantityInfo(context),
              if (inventoryItem.location != null || inventoryItem.notes != null) ...[
                const SizedBox(height: 8),
                _buildAdditionalInfo(context),
              ],
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Product photo or placeholder
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: product.photoPath != null && product.photoPath!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(product.photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPhotoPlaceholder(context);
                    },
                  ),
                )
              : _buildPhotoPlaceholder(context),
        ),
        const SizedBox(width: 12),
        // Product info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    product.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Quantity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getQuantityBadgeColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${inventoryItem.quantity}',
            style: TextStyle(
              color: _getQuantityTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    return Icon(
      Icons.inventory_2,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      size: 24,
    );
  }

  Widget _buildQuantityInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.inventory,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${inventoryItem.quantity} ${product.unit}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (inventoryItem.minimumStock != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.warning_amber,
            size: 16,
            color: inventoryItem.isLowStock 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Min: ${inventoryItem.minimumStock}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: inventoryItem.isLowStock 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        Text(
          'Updated ${_formatDate(inventoryItem.lastUpdated)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inventoryItem.location != null) ...[
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                inventoryItem.location!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
        if (inventoryItem.notes != null) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  inventoryItem.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Quick remove button
        if (inventoryItem.quantity > 0 && onQuickRemove != null)
          _buildActionButton(
            context: context,
            icon: Icons.remove,
            label: 'Remove',
            onPressed: onQuickRemove!,
            isDestructive: true,
          ),
        if (inventoryItem.quantity > 0 && onQuickAdd != null)
          const SizedBox(width: 8),
        // Quick add button
        if (onQuickAdd != null)
          _buildActionButton(
            context: context,
            icon: Icons.add,
            label: 'Add',
            onPressed: onQuickAdd!,
          ),
        const Spacer(),
        // View details button
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('Details'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Color _getBorderColor(BuildContext context) {
    if (inventoryItem.isOutOfStock) {
      return Theme.of(context).colorScheme.error;
    } else if (inventoryItem.isLowStock) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.outline;
    }
  }

  Color _getStatusColor(BuildContext context) {
    if (inventoryItem.isOutOfStock) {
      return Theme.of(context).colorScheme.error;
    } else if (inventoryItem.isLowStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (inventoryItem.isOutOfStock) {
      return 'OUT OF STOCK';
    } else if (inventoryItem.isLowStock) {
      return 'LOW STOCK';
    } else {
      return 'IN STOCK';
    }
  }

  Color _getQuantityBadgeColor(BuildContext context) {
    if (inventoryItem.isOutOfStock) {
      return Theme.of(context).colorScheme.errorContainer;
    } else if (inventoryItem.isLowStock) {
      return Colors.orange.withValues(alpha: 0.1);
    } else {
      return Colors.green.withValues(alpha: 0.1);
    }
  }

  Color _getQuantityTextColor(BuildContext context) {
    if (inventoryItem.isOutOfStock) {
      return Theme.of(context).colorScheme.error;
    } else if (inventoryItem.isLowStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}