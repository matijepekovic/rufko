import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller for customer form that handles all business logic
/// Separates customer CRUD operations from UI presentation
class CustomerFormUIController extends ChangeNotifier {
  final AppStateProvider _appStateProvider;
  
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController streetAddressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  Customer? _editingCustomer;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  CustomerFormUIController(this._appStateProvider);

  // Read-only getters for UI
  bool get isEditing => _isEditing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Customer? get editingCustomer => _editingCustomer;

  /// Initialize form for editing existing customer
  void initializeForEditing(Customer customer) {
    _editingCustomer = customer;
    _isEditing = true;
    
    // Populate form fields
    nameController.text = customer.name;
    phoneController.text = customer.phone ?? '';
    emailController.text = customer.email ?? '';
    notesController.text = customer.notes ?? '';
    streetAddressController.text = customer.streetAddress ?? '';
    cityController.text = customer.city ?? '';
    stateController.text = customer.stateAbbreviation ?? '';
    zipController.text = customer.zipCode ?? '';
    
    notifyListeners();
  }

  /// Initialize form for creating new customer
  void initializeForCreating() {
    _editingCustomer = null;
    _isEditing = false;
    _clearForm();
    notifyListeners();
  }

  /// Validate email format
  String? validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
    }
    return null;
  }

  /// Validate required name field
  String? validateName(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Name is required' : null;
  }

  /// Save customer (create or update)
  Future<bool> saveCustomer() async {
    if (!formKey.currentState!.validate()) return false;
    
    _setLoading(true);
    _setError(null);
    
    try {
      final customerData = _extractFormData();
      
      if (_isEditing && _editingCustomer != null) {
        _editingCustomer!.updateInfo(
          name: customerData['name']!,
          phone: customerData['phone'],
          email: customerData['email'],
          notes: customerData['notes'],
          streetAddress: customerData['streetAddress'],
          city: customerData['city'],
          stateAbbreviation: customerData['stateAbbreviation'],
          zipCode: customerData['zipCode'],
        );
      } else {
        final customer = Customer(
          name: customerData['name']!,
          phone: customerData['phone'],
          email: customerData['email'],
          notes: customerData['notes'],
          streetAddress: customerData['streetAddress'],
          city: customerData['city'],
          stateAbbreviation: customerData['stateAbbreviation'],
          zipCode: customerData['zipCode'],
        );
        _appStateProvider.addCustomer(customer);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to save customer: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get success message for UI display
  String getSuccessMessage() {
    return _isEditing ? 'Customer updated!' : 'Customer added!';
  }

  /// Extract form data as map
  Map<String, String?> _extractFormData() {
    return {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      'streetAddress': streetAddressController.text.trim().isEmpty ? null : streetAddressController.text.trim(),
      'city': cityController.text.trim().isEmpty ? null : cityController.text.trim(),
      'stateAbbreviation': stateController.text.trim().isEmpty ? null : stateController.text.trim(),
      'zipCode': zipController.text.trim().isEmpty ? null : zipController.text.trim(),
    };
  }

  /// Clear all form fields
  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    notesController.clear();
    streetAddressController.clear();
    cityController.clear();
    stateController.clear();
    zipController.clear();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    streetAddressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipController.dispose();
    super.dispose();
  }
}