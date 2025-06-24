import 'package:flutter/material.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../products/presentation/controllers/product_dialog_manager.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../inventory/presentation/dialogs/inventory_form_dialog.dart';
import '../../../../core/widgets/custom_header.dart';
import '../../../../core/widgets/custom_tab_bar.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProductDialogManager _productDialogManager;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _productDialogManager = ProductDialogManager(context);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide FAB based on tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Vault',
        leadingIcon: Icons.archive_rounded,
        bottom: CustomTabBar(
          controller: _tabController,
          tabs: const ['Catalog', 'Inventory', 'Crews'],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ProductsScreen(),
          const InventoryScreen(),
          const Center(child: Text('Sub-contractors - TODO: Implement', style: TextStyle(fontSize: 18))),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: // Catalog tab
        return FloatingActionButton(
          onPressed: _productDialogManager.showAddProductDialog,
          child: const Icon(Icons.add),
        );
      case 1: // Inventory tab
        return FloatingActionButton(
          onPressed: _showAddInventoryDialog,
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _showAddInventoryDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const InventoryFormDialog(),
    );
  }
}