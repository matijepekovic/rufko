import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../core/mixins/ui/responsive_text_mixin.dart';
import '../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../core/mixins/ui/responsive_widget_mixin.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../customers/presentation/controllers/customer_dialog_manager.dart';
import '../../../customers/presentation/controllers/customer_import_controller.dart';
import '../../../products/presentation/controllers/product_dialog_manager.dart';
import '../../../quotes/presentation/controllers/quote_navigation_controller.dart';

class QuickActionsController
    with
        ResponsiveBreakpointsMixin,
        ResponsiveDimensionsMixin,
        ResponsiveSpacingMixin,
        ResponsiveTextMixin,
        ResponsiveWidgetMixin {
  QuickActionsController(this.context, {required this.navigateToTab});

  final BuildContext context;
  final void Function(int) navigateToTab;

  // Initialize dialog managers
  CustomerDialogManager? _customerDialogManager;
  ProductDialogManager? _productDialogManager;
  QuoteNavigationController? _quoteNavigationController;

  void _initializeControllers() {
    if (_customerDialogManager != null) return; // Already initialized
    
    final appState = context.read<AppStateProvider>();
    final importController = CustomerImportController(context, appState);
    _customerDialogManager = CustomerDialogManager(context, importController);
    _productDialogManager = ProductDialogManager(context);
    _quoteNavigationController = QuoteNavigationController(context);
  }

  void showQuickCreateDialog() {
    _initializeControllers(); // Initialize controllers when needed
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.all(spacingMD(context)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(spacingLG(context)),
        ),
        child: _buildQuickCreateContent(context),
      ),
    );
  }

  Widget _buildQuickCreateContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: responsivePadding(context, all: 2.5),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacingSM(context)),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(spacingSM(context)),
                  ),
                  child: Icon(Icons.add, color: Colors.blue.shade600),
                ),
                SizedBox(width: spacingSM(context)),
                Text(
                  'Quick Create',
                  style: titleLarge(context).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _buildQuickActionTile(
            'New Customer',
            'Add a new customer to your database',
            Icons.person_add,
            Colors.blue.shade600,
            () {
              Navigator.pop(context);
              _customerDialogManager!.showAddCustomerDialog();
            },
          ),
          _buildQuickActionTile(
            'New Quote',
            'Create a professional roofing estimate',
            Icons.note_add,
            Colors.green.shade600,
            () {
              Navigator.pop(context);
              _quoteNavigationController!.navigateToCreateQuote();
            },
          ),
          _buildQuickActionTile(
            'New Product',
            'Add products to your inventory',
            Icons.add_box,
            Colors.orange.shade600,
            () {
              Navigator.pop(context);
              _productDialogManager!.showAddProductDialog();
            },
          ),
          SizedBox(height: spacingLG(context)),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
      String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: responsivePadding(context, horizontal: 2.5, vertical: 1),
      leading: Container(
        padding: EdgeInsets.all(spacingSM(context)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(spacingSM(context)),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: titleSmall(context).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: bodySmall(context)),
      onTap: onTap,
    );
  }
}
