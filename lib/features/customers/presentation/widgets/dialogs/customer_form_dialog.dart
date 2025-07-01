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

  // Controllers for structured address
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    if (widget.customer != null) {
      final customer = widget.customer!;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _streetAddressController.text = customer.streetAddress ?? '';
      _cityController.text = customer.city ?? '';
      _stateController.text = customer.stateAbbreviation ?? '';
      _zipController.text = customer.zipCode ?? '';
      _notesController.text = customer.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Lead' : 'Add Lead'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton(
            onPressed: _saveCustomer,
            child: Text(_isEditing ? 'Update' : 'Add'),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 32),
              Text(
                'Address Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _streetAddressController,
                label: 'Street Address',
                icon: Icons.home_outlined,
                hint: 'e.g., 123 Main St'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map_outlined,
                      hint: 'WA'),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 150,
                    child: _buildTextField(
                      controller: _zipController,
                      label: 'ZIP Code',
                      icon: Icons.markunread_mailbox_outlined,
                      keyboardType: TextInputType.number,
                      hint: '12345'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                icon: Icons.note_alt_outlined,
                maxLines: 3,
                hint: 'Additional information...'),
              const SizedBox(height: 24), // Extra space for keyboard
            ],
          ),
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
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: label.contains('Name') || label.contains('City') || label.contains('Address')
          ? TextCapitalization.words
          : label.contains('State')
              ? TextCapitalization.characters
              : TextCapitalization.none,
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
        name: name,
        phone: phone,
        email: email,
        notes: notes,
        streetAddress: street,
        city: city,
        stateAbbreviation: stateAbbr,
        zipCode: zip,
      );
      appState.updateCustomer(widget.customer!);
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