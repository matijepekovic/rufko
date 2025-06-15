import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../../../../data/models/business/customer.dart";
import "../../../../../data/providers/state/app_state_provider.dart";

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  const CustomerFormDialog({this.customer, super.key});

  @override
  State<CustomerFormDialog> createState() => CustomerFormDialogState();
}

class CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  // NEW Controllers for structured address
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(); // For state abbreviation
  final _zipController = TextEditingController();

  bool get _isEditing => widget.customer != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    // Dispose new controllers
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9, // Responsive width
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // Max height
          maxWidth: 500, // Max width for larger screens
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // Header
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(_isEditing ? Icons.edit_note : Icons.person_add_alt_1,
                      color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(_isEditing ? 'Edit Customer' : 'Add New Customer',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .stretch, // Make children take full width
                    children: [
                      _buildTextField(
                          controller: _nameController,
                          label: 'Full Name*',
                          icon: Icons.person,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Name is required'
                                  : null),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          }),
                      const SizedBox(height: 20),
                      Text("Address Details:",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.grey[700])),
                      const Divider(height: 10),
                      const SizedBox(height: 10),
                      _buildTextField(
                          controller: _streetAddressController,
                          label: 'Street Address',
                          icon: Icons.home_outlined,
                          hint: "e.g., 123 Main St"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(
                                  controller: _cityController,
                                  label: 'City',
                                  icon: Icons.location_city)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildTextField(
                                  controller: _stateController,
                                  label: 'State',
                                  icon: Icons.map_outlined,
                                  hint: "e.g., WA")),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _zipController,
                          label: 'Zip Code',
                          icon: Icons.markunread_mailbox_outlined,
                          keyboardType: TextInputType.number,
                          hint: "e.g., 98001"),
                      const SizedBox(height: 20),
                      Text("Other Information:",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.grey[700])),
                      const Divider(height: 10),
                      const SizedBox(height: 10),
                      _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          icon: Icons.note_alt_outlined,
                          maxLines: 3,
                          hint: 'Additional information...'),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              // Actions Footer
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                      onPressed: _saveCustomer,
                      child: Text(
                          _isEditing ? 'Update Customer' : 'Add Customer')),
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
        prefixIcon: Icon(icon,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppStateProvider>();

    final String name = _nameController.text.trim();
    final String? phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
    final String? email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    final String? notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final String? street = _streetAddressController.text.trim().isEmpty
        ? null
        : _streetAddressController.text.trim();
    final String? city = _cityController.text.trim().isEmpty
        ? null
        : _cityController.text.trim();
    final String? stateAbbr = _stateController.text.trim().isEmpty
        ? null
        : _stateController.text.trim();
    final String? zip =
        _zipController.text.trim().isEmpty ? null : _zipController.text.trim();

    if (_isEditing && widget.customer != null) {
      widget.customer!.updateInfo(
        // This calls save() internally if in box
        name: name,
        phone: phone,
        email: email,
        notes: notes,
        streetAddress: street,
        city: city,
        stateAbbreviation: stateAbbr,
        zipCode: zip,
      );
      // appState.updateCustomer(widget.customer!); // updateInfo already saves if in box
    } else {
      final customer = Customer(
        name: name,
        phone: phone,
        email: email,
        notes: notes,
        streetAddress: street,
        city: city,
        stateAbbreviation: stateAbbr,
        zipCode: zip,
      );
      appState.addCustomer(customer);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_isEditing ? 'Customer updated!' : 'Customer added!'),
          backgroundColor: Colors.green),
    );
  }
}
