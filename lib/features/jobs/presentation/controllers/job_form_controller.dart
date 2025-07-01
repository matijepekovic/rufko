import 'package:flutter/material.dart';
import '../../../../data/models/business/job.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/repositories/customer_repository.dart';
import '../../../../core/services/job_service.dart';
import '../../../../data/models/settings/app_settings.dart';

/// Controller for job form operations
/// Handles all business logic for creating and editing jobs
class JobFormController extends ChangeNotifier {
  final Job? initialJob;
  final DateTime? initialScheduledDate;
  final AppSettings? appSettings;
  
  JobFormController({
    this.initialJob,
    this.initialScheduledDate,
    this.appSettings,
  }) {
    _initializeForm();
  }

  // Services
  final CustomerRepository _customerRepository = CustomerRepository();
  final JobService _jobService = JobService();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final estimatedCostController = TextEditingController();
  final durationController = TextEditingController();
  final notesController = TextEditingController();

  // Form state
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  String _selectedJobType = 'Roof Repair'; // Default job type
  JobPriority _selectedPriority = JobPriority.medium;
  DateTime? _scheduledStartDate;
  DateTime? _scheduledEndDate;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingCustomers = true;
  bool _isSaving = false;
  
  // Messages
  String? _errorMessage;
  String? _successMessage;

  // Getters
  bool get isEditMode => initialJob != null;
  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  String get selectedJobType => _selectedJobType;
  JobPriority get selectedPriority => _selectedPriority;
  DateTime? get scheduledStartDate => _scheduledStartDate;
  DateTime? get scheduledEndDate => _scheduledEndDate;
  bool get isLoading => _isLoading;
  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Get available job types from settings or default list
  List<String> get availableJobTypes {
    return appSettings?.jobTypes ?? JobTypeHelper.defaultJobTypes;
  }

  void _initializeForm() {
    // Set default job type from available options
    final jobTypes = availableJobTypes;
    if (jobTypes.isNotEmpty) {
      _selectedJobType = jobTypes.first;
    }

    if (initialJob != null) {
      // Initialize form with existing job data
      final job = initialJob!;
      titleController.text = job.title;
      descriptionController.text = job.description;
      addressController.text = job.address;
      estimatedCostController.text = job.estimatedCost?.toString() ?? '';
      durationController.text = job.estimatedDurationHours.toString();
      notesController.text = job.notes ?? '';
      _selectedJobType = job.type;
      _selectedPriority = job.priority;
      _scheduledStartDate = job.scheduledStartDate;
      _scheduledEndDate = job.scheduledEndDate;
    } else if (initialScheduledDate != null) {
      // Pre-fill dates for new job creation from calendar
      _scheduledStartDate = DateTime(
        initialScheduledDate!.year,
        initialScheduledDate!.month,
        initialScheduledDate!.day,
        9, // Default to 9 AM
        0,
      );
      _scheduledEndDate = DateTime(
        initialScheduledDate!.year,
        initialScheduledDate!.month,
        initialScheduledDate!.day,
        17, // Default to 5 PM
        0,
      );
      durationController.text = '8'; // Default 8 hours
    }
    
    // Load customers
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    _setLoadingCustomers(true);
    _clearMessages();
    
    try {
      final loadedCustomers = await _customerRepository.getAllCustomers();
      _customers = loadedCustomers;
      
      // Find and set customer if editing
      if (initialJob != null) {
        _selectedCustomer = _customers
            .where((c) => c.id == initialJob!.customerId)
            .firstOrNull;
      }
      
      _setLoadingCustomers(false);
    } catch (e) {
      _setErrorMessage('Error loading customers: $e');
      _setLoadingCustomers(false);
    }
  }

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    
    // Auto-fill address if empty
    if (customer != null && addressController.text.isEmpty) {
      addressController.text = customer.fullDisplayAddress;
    }
    
    notifyListeners();
  }

  void setJobType(String type) {
    _selectedJobType = type;
    notifyListeners();
  }

  void setPriority(JobPriority priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setScheduledStartDate(DateTime? date) {
    _scheduledStartDate = date;
    notifyListeners();
  }

  void setScheduledEndDate(DateTime? date) {
    _scheduledEndDate = date;
    notifyListeners();
  }

  /// Validate form fields
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a job title';
    }
    return null;
  }

  String? validateCustomer() {
    if (_selectedCustomer == null) {
      return 'Please select a customer';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the job address';
    }
    return null;
  }

  String? validateCost(String? value) {
    if (value != null && value.isNotEmpty) {
      final cost = double.tryParse(value);
      if (cost == null || cost < 0) {
        return 'Enter valid cost';
      }
    }
    return null;
  }

  String? validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final duration = int.tryParse(value);
    if (duration == null || duration <= 0) {
      return 'Enter valid duration';
    }
    return null;
  }

  /// Save job (create or update)
  Future<bool> saveJob() async {
    _clearMessages();
    
    // Basic validation
    if (_selectedCustomer == null) {
      _setErrorMessage('Please select a customer');
      return false;
    }
    
    if (titleController.text.trim().isEmpty) {
      _setErrorMessage('Please enter a job title');
      return false;
    }
    
    _setSaving(true);
    
    try {
      final estimatedCost = estimatedCostController.text.isNotEmpty
          ? double.tryParse(estimatedCostController.text)
          : null;

      final duration = int.parse(durationController.text);

      final job = Job(
        id: initialJob?.id,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: _selectedJobType,
        priority: _selectedPriority,
        status: initialJob?.status ?? JobStatus.draft,
        address: addressController.text.trim(),
        scheduledStartDate: _scheduledStartDate,
        scheduledEndDate: _scheduledEndDate,
        estimatedCost: estimatedCost,
        estimatedDurationHours: duration,
        notes: notesController.text.trim().isNotEmpty 
            ? notesController.text.trim() 
            : null,
        progressPercentage: initialJob?.progressPercentage ?? 0,
        createdAt: initialJob?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (isEditMode) {
        success = await _jobService.updateJob(job);
        if (success) {
          _setSuccessMessage('Job updated successfully');
        }
      } else {
        success = await _jobService.createJob(job);
        if (success) {
          _setSuccessMessage('Job created successfully');
        }
      }

      if (!success) {
        throw Exception('Failed to save job');
      }

      _setSaving(false);
      return success;
    } catch (e) {
      _setErrorMessage('Error saving job: $e');
      _setSaving(false);
      return false;
    }
  }

  /// Clear all messages
  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  // Private helper methods

  void _setLoadingCustomers(bool loading) {
    _isLoadingCustomers = loading;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    estimatedCostController.dispose();
    durationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // Helper methods for UI
  IconData getPriorityIcon(JobPriority priority) {
    switch (priority) {
      case JobPriority.low:
        return Icons.keyboard_arrow_down;
      case JobPriority.medium:
        return Icons.remove;
      case JobPriority.high:
        return Icons.keyboard_arrow_up;
      case JobPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color getPriorityColor(JobPriority priority) {
    switch (priority) {
      case JobPriority.low:
        return Colors.green;
      case JobPriority.medium:
        return Colors.orange;
      case JobPriority.high:
        return Colors.red;
      case JobPriority.urgent:
        return Colors.purple;
    }
  }
}