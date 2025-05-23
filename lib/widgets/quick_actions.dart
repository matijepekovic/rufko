import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import '../models/quote.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionCard(
            icon: Icons.person_add,
            title: 'Add Customer',
            color: Colors.blue,
            onTap: () => _showAddCustomerDialog(context),
          ),
          _QuickActionCard(
            icon: Icons.note_add,
            title: 'New Quote',
            color: Colors.green,
            onTap: () => _showNewQuoteDialog(context),
          ),
          _QuickActionCard(
            icon: Icons.file_upload,
            title: 'Import RoofScope',
            color: Colors.orange,
            onTap: () => _importRoofScope(context),
          ),
          _QuickActionCard(
            icon: Icons.photo_camera,
            title: 'Take Photo',
            color: Colors.purple,
            onTap: () => _takePhoto(context),
          ),
          _QuickActionCard(
            icon: Icons.inventory_2,
            title: 'Add Product',
            color: Colors.teal,
            onTap: () => _showAddProductDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _QuickCustomerDialog(),
    );
  }

  void _showNewQuoteDialog(BuildContext context) {
    final appState = context.read<AppStateProvider>();

    if (appState.customers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Customers'),
          content: const Text('You need to add customers before creating quotes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a customer:'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: appState.customers.length,
                itemBuilder: (context, index) {
                  final customer = appState.customers[index];
                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text(customer.phone ?? customer.email ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      _createQuote(context, customer.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _createQuote(BuildContext context, String customerId) {
    final newQuote = Quote(customerId: customerId);
    context.read<AppStateProvider>().addQuote(newQuote);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quote ${newQuote.quoteNumber} created'),
      ),
    );
  }

  void _importRoofScope(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Show customer selection for RoofScope import
        final appState = context.read<AppStateProvider>();

        if (appState.customers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add a customer first to import RoofScope data'),
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import RoofScope'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select customer for this RoofScope data:'),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: appState.customers.length,
                    itemBuilder: (context, index) {
                      final customer = appState.customers[index];
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(customer.phone ?? customer.email ?? ''),
                        onTap: () async {
                          Navigator.pop(context);

                          try {
                            final roofScopeData = await appState.extractRoofScopeFromPdf(
                              filePath,
                              customer.id,
                            );

                            if (roofScopeData != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('RoofScope data imported successfully'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No RoofScope data found in PDF'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error importing RoofScope: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _takePhoto(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo capture feature coming soon'),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Products tab to add products'),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCustomerDialog extends StatefulWidget {
  @override
  State<_QuickCustomerDialog> createState() => _QuickCustomerDialogState();
}

class _QuickCustomerDialogState extends State<_QuickCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Add Customer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _saveCustomer() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final customer = Customer(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    context.read<AppStateProvider>().addCustomer(customer);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${customer.name} added')),
    );
  }
}