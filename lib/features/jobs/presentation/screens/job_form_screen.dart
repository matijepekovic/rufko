import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/job.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../controllers/job_form_controller.dart';

/// Full-screen job creation/editing form
/// Follows established design patterns with proper controller separation
class JobFormScreen extends StatefulWidget {
  final Job? initialJob;
  final DateTime? initialScheduledDate;
  
  const JobFormScreen({
    super.key,
    this.initialJob,
    this.initialScheduledDate,
  });

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  late final JobFormController _controller;
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    final appSettings = context.read<AppStateProvider>().appSettings;
    _controller = JobFormController(
      initialJob: widget.initialJob,
      initialScheduledDate: widget.initialScheduledDate,
      appSettings: appSettings,
    );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      // Show messages
      if (_controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        _controller.clearMessages();
      } else if (_controller.successMessage != null) {
        // Job saved successfully, return to previous screen
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_controller.isEditMode ? 'Edit Job' : 'Create New Job'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _controller.isSaving ? null : _handleSave,
            child: _controller.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _controller.isEditMode ? 'Save' : 'Create',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoadingCustomers) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerSection(),
                  const SizedBox(height: 24),
                  _buildJobDetailsSection(),
                  const SizedBox(height: 24),
                  _buildScheduleSection(),
                  const SizedBox(height: 24),
                  _buildCostAndDurationSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Customer>(
          value: _controller.selectedCustomer,
          decoration: const InputDecoration(
            labelText: 'Customer',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          items: _controller.customers.map((customer) {
            return DropdownMenuItem<Customer>(
              value: customer,
              child: Text(customer.name),
            );
          }).toList(),
          onChanged: _controller.setSelectedCustomer,
          validator: (_) => _controller.validateCustomer(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controller.addressController,
          decoration: const InputDecoration(
            labelText: 'Job Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            helperText: 'This can be different from the customer address',
          ),
          maxLines: 2,
          validator: _controller.validateAddress,
        ),
      ],
    );
  }

  Widget _buildJobDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controller.titleController,
          decoration: const InputDecoration(
            labelText: 'Job Title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
          validator: _controller.validateTitle,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _controller.selectedJobType,
          decoration: const InputDecoration(
            labelText: 'Job Type',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _controller.availableJobTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (type) {
            if (type != null) {
              _controller.setJobType(type);
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<JobPriority>(
          value: _controller.selectedPriority,
          decoration: const InputDecoration(
            labelText: 'Priority',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.priority_high),
          ),
          items: JobPriority.values.map((priority) {
            return DropdownMenuItem<JobPriority>(
              value: priority,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _controller.getPriorityIcon(priority),
                    size: 16,
                    color: _controller.getPriorityColor(priority),
                  ),
                  const SizedBox(width: 8),
                  Text(priority.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (priority) {
            if (priority != null) {
              _controller.setPriority(priority);
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controller.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date & Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _controller.scheduledStartDate != null
                        ? _dateFormat.format(_controller.scheduledStartDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _controller.scheduledStartDate != null
                          ? null
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date & Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _controller.scheduledEndDate != null
                        ? _dateFormat.format(_controller.scheduledEndDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _controller.scheduledEndDate != null
                          ? null
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostAndDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost & Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller.estimatedCostController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Cost',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.00',
                ),
                validator: _controller.validateCost,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _controller.durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (hours)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  hintText: '8',
                ),
                validator: _controller.validateDuration,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controller.notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
            alignLabelWithHint: true,
            hintText: 'Additional notes or special instructions',
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _controller.scheduledStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _controller.scheduledStartDate ?? DateTime.now(),
        ),
      );

      if (time != null) {
        _controller.setScheduledStartDate(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
      }
    }
  }

  Future<void> _selectEndDate() async {
    final minDate = _controller.scheduledStartDate ?? DateTime.now();
    
    final date = await showDatePicker(
      context: context,
      initialDate: _controller.scheduledEndDate ?? minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _controller.scheduledEndDate ?? minDate.add(const Duration(hours: 8)),
        ),
      );

      if (time != null) {
        _controller.setScheduledEndDate(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      await _controller.saveJob();
    }
  }
}