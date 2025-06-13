import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/product.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/product_form_dialog.dart';

/// Coordinates product-related dialogs and status updates.
class ProductDialogManager {
  ProductDialogManager(this.context);

  final BuildContext context;

  void showAddProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ProductFormDialog(),
    );
  }

  void showEditProductDialog(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(product: product),
    );
  }

  void showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Delete Product'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              dialogContext.read<AppStateProvider>().deleteProduct(product.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} deleted'),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void toggleProductStatus(Product product) {
    product.updateInfo(isActive: !product.isActive);
    context.read<AppStateProvider>().updateProduct(product);
  }
}
