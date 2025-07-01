import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/models/business/customer.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_dimensions_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../core/mixins/ui/responsive_widget_mixin.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

/// Material Design 3 compliant customer form dialog
/// Implements responsive design patterns from CLAUDE.md
class CustomerFormDialogM3 extends StatefulWidget {
  final Customer? customer;
  
  const CustomerFormDialogM3({super.key, this.customer});

  @override
  State<CustomerFormDialogM3> createState() => _CustomerFormDialogM3State();
}

class _CustomerFormDialogM3State extends State<CustomerFormDialogM3> 
    with ResponsiveBreakpointsMixin, ResponsiveDimensionsMixin, ResponsiveSpacingMixin, ResponsiveWidgetMixin {
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSubmitting = false;
  
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
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: _buildResponsiveLayout(),
    );
  }
  
  Widget _buildResponsiveLayout() {
    return windowClassBuilder(
      context: context,
      compact: _buildCompactLayout(),
      medium: _buildMediumLayout(),
      expanded: _buildExpandedLayout(),
    );
  }
  
  Widget _buildCompactLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildFormContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }
  
  Widget _buildMediumLayout() {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card.outlined(
                  margin: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Expanded(child: _buildFormContent()),
                      _buildInlineActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandedLayout() {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card.outlined(
                  margin: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFormContent(),
                      ),
                      Container(
                        width: 300,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSidePanel(),
                            const Spacer(),
                            _buildInlineActions(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isEditing ? 'Edit Lead' : 'Add Lead'),
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }
  
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: responsivePadding(context, all: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerInfoSection(),
            SizedBox(height: spacingXL(context)),
            _buildContactInfoSection(),
            SizedBox(height: spacingXL(context)),
            _buildAddressSection(),
            SizedBox(height: spacingXL(context)),
            _buildNotesSection(),
            if (isCompact(context)) SizedBox(height: spacingXXL(context)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingLG(context)),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter customer full name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Customer name is required';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }
  
  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingLG(context)),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '(555) 123-4567',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: spacingLG(context)),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'customer@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingLG(context)),
        TextFormField(
          controller: _streetAddressController,
          decoration: InputDecoration(
            labelText: 'Street Address',
            hintText: '123 Main Street',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: spacingLG(context)),
        responsiveValue(
          context,
          mobile: Column(
            children: [
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter city',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: spacingLG(context)),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        hintText: 'CA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _zipController,
                      decoration: InputDecoration(
                        labelText: 'ZIP Code',
                        hintText: '12345',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          tablet: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'Enter city',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    hintText: 'CA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _zipController,
                  decoration: InputDecoration(
                    labelText: 'ZIP Code',
                    hintText: '12345',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingLG(context)),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Additional Notes',
            hintText: 'Add any additional information about this customer...',
            prefixIcon: const Icon(Icons.note_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
  
  Widget _buildSidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacingLG(context)),
        if (_isEditing) ...[
          _buildSummaryRow('Customer ID', widget.customer!.id),
          _buildSummaryRow('Created', 'Jan 15, 2024'), // TODO: Use actual date
          SizedBox(height: spacingLG(context)),
        ],
        _buildSummaryRow('Status', _isEditing ? 'Active' : 'New Lead'),
        _buildSummaryRow('Type', 'Residential'), // TODO: Add customer type field
      ],
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: RufkoSecondaryButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              isFullWidth: true,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: RufkoPrimaryButton(
              onPressed: _isSubmitting ? null : _submitForm,
              isFullWidth: true,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Customer' : 'Add Customer'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInlineActions() {
    return Row(
      children: [
        Expanded(
          child: RufkoSecondaryButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            isFullWidth: true,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: RufkoPrimaryButton(
            onPressed: _isSubmitting ? null : _submitForm,
            isFullWidth: true,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Update Customer' : 'Add Customer'),
          ),
        ),
      ],
    );
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final appState = context.read<AppStateProvider>();
      
      if (_isEditing) {
        // Update existing customer
        widget.customer!.updateInfo(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          streetAddress: _streetAddressController.text.trim().isEmpty ? null : _streetAddressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          stateAbbreviation: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        
        // Use proper update method instead of manual notifyListeners
        await appState.updateCustomer(widget.customer!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully!')),
          );
        }
      } else {
        // Add new customer
        final newCustomer = Customer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          streetAddress: _streetAddressController.text.trim().isEmpty ? null : _streetAddressController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          stateAbbreviation: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        
        await appState.addCustomer(newCustomer);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer added successfully!')),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}