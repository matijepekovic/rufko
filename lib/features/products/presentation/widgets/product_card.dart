// lib/widgets/product_card.dart - CLEAN & SIMPLE DESIGN

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/business/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;

        return Card(
          margin: EdgeInsets.only(bottom: isPhone ? 8 : 12),
          elevation: product.isActive ? 2 : 1,
          color: product.isActive ? null : Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(isPhone ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row - Name, Price, Toggle
                  Row(
                    children: [
                      // Product Icon
                      Container(
                        width: isPhone ? 32 : 40,
                        height: isPhone ? 32 : 40,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(product.category).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(product.category),
                          color: _getCategoryColor(product.category),
                          size: isPhone ? 16 : 20,
                        ),
                      ),

                      SizedBox(width: isPhone ? 8 : 12),

                      // Product Name & Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isPhone ? 16 : 18,
                                color: product.isActive ? null : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              product.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: isPhone ? 13 : 14,
                                color: _getCategoryColor(product.category),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(product.unitPrice),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isPhone ? 16 : 18,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            'per ${product.unit}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isPhone ? 12 : 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: isPhone ? 12 : 16),

                      // Active Toggle Switch with Label
                      Column(
                        children: [
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: isPhone ? 11 : 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Transform.scale(
                            scale: isPhone ? 0.9 : 1.0,
                            child: Switch(
                              value: product.isActive,
                              onChanged: onToggleActive != null ? (_) => onToggleActive!() : null,
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.grey[400],
                              inactiveTrackColor: Colors.grey[300],
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Description (if exists)
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    SizedBox(height: isPhone ? 10 : 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isPhone ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isPhone ? 13 : 14,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  // Level Pricing Info (if exists)
                  if (product.activeLevels.isNotEmpty) ...[
                    SizedBox(height: isPhone ? 10 : 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isPhone ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.layers_outlined, size: isPhone ? 16 : 18, color: Colors.blue[700]),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${product.activeLevels.length} pricing levels available',
                              style: TextStyle(
                                fontSize: isPhone ? 13 : 14,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${currencyFormat.format(product.activeLevels.first.price)} - ${currencyFormat.format(product.activeLevels.last.price)}',
                            style: TextStyle(
                              fontSize: isPhone ? 12 : 13,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: isPhone ? 10 : 12),

                  // Bottom Row - Status & Actions
                  Row(
                    children: [
                      // Status Indicators
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (!product.isDiscountable)
                              _buildSimpleBadge('No Discount', Colors.orange, isPhone),
                            if (product.isAddon)
                              _buildSimpleBadge('Add-on', Colors.purple, isPhone),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(Icons.edit_outlined, size: isPhone ? 22 : 24),
                            color: Colors.blue[600],
                            padding: EdgeInsets.all(isPhone ? 6 : 8),
                            constraints: BoxConstraints(
                              minWidth: isPhone ? 40 : 44,
                              minHeight: isPhone ? 40 : 44,
                            ),
                            tooltip: 'Edit Product',
                          ),
                          SizedBox(width: isPhone ? 4 : 6),
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(Icons.delete_outline, size: isPhone ? 22 : 24),
                            color: Colors.red[600],
                            padding: EdgeInsets.all(isPhone ? 6 : 8),
                            constraints: BoxConstraints(
                              minWidth: isPhone ? 40 : 44,
                              minHeight: isPhone ? 40 : 44,
                            ),
                            tooltip: 'Delete Product',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleBadge(String text, Color color, bool isPhone) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 8 : 10,
        vertical: isPhone ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isPhone ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'roofing':
      case 'materials':
        return Colors.blue[600]!;
      case 'gutters':
        return Colors.teal[600]!;
      case 'flashing':
        return Colors.orange[600]!;
      case 'labor':
        return Colors.purple[600]!;
      case 'other':
        return Colors.grey[600]!;
      default:
        return Colors.indigo[600]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'roofing':
      case 'materials':
        return Icons.roofing;
      case 'gutters':
        return Icons.water_drop_outlined;
      case 'flashing':
        return Icons.flash_on_outlined;
      case 'labor':
        return Icons.engineering;
      case 'other':
        return Icons.category_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}