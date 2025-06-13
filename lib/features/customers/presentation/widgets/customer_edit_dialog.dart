import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../../data/models/business/customer.dart";
import "../../../../data/providers/state/app_state_provider.dart";

class CustomerEditDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onCustomerUpdated;
  const CustomerEditDialog({
    super.key,
    required this.customer,
    this.onCustomerUpdated,
  });

  @override
  State<CustomerEditDialog> createState() => CustomerEditDialogState();
}

class CustomerEditDialogState extends State<CustomerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.customer.name;
    _phoneController.text = widget.customer.phone ?? '';
    _emailController.text = widget.customer.email ?? '';
    _streetAddressController.text = widget.customer.streetAddress ?? '';
    _cityController.text = widget.customer.city ?? '';
    _stateController.text = widget.customer.stateAbbreviation ?? '';
    _zipController.text = widget.customer.zipCode ?? '';
    _notesController.text = widget.customer.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text('Edit Customer', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name*',
                        icon: Icons.person,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 20),
                      Text("Address Details:", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[700])),
                      const Divider(height: 10),
                      const SizedBox(height: 10),
                      _buildTextField(controller: _streetAddressController, label: 'Street Address', icon: Icons.home_outlined, hint: "e.g., 123 Main St"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _cityController, label: 'City', icon: Icons.location_city)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _stateController, label: 'State', icon: Icons.map_outlined, hint: "e.g., WA")),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _zipController, label: 'Zip Code', icon: Icons.markunread_mailbox_outlined, keyboardType: TextInputType.number, hint: "e.g., 98001"),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                        hint: 'Additional information...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _saveCustomer, child: const Text('Update Customer')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }



  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppStateProvider>();

    widget.customer.updateInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      streetAddress: _streetAddressController.text.trim().isEmpty ? null : _streetAddressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      stateAbbreviation: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    appState.updateCustomer(widget.customer);

    Navigator.pop(context);
    widget.onCustomerUpdated?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer updated successfully!'), backgroundColor: Colors.green),
    );
  }


}
