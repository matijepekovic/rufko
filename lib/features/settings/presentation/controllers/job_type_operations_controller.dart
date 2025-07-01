import 'package:flutter/material.dart';

/// Controller for managing job type operations in the settings dialog
/// Handles add, edit, delete operations with validation
class JobTypeOperationsController extends ChangeNotifier {
  final TextEditingController addController = TextEditingController();
  final List<String> _jobTypes;

  JobTypeOperationsController(List<String> initialJobTypes)
      : _jobTypes = List.from(initialJobTypes);

  List<String> get jobTypes => _jobTypes;

  /// Add a new job type
  void addJobType() {
    final newJobType = addController.text.trim();
    
    if (newJobType.isEmpty) {
      return;
    }
    
    // Check for duplicates (case-insensitive)
    if (_jobTypes.any((type) => type.toLowerCase() == newJobType.toLowerCase())) {
      return;
    }
    
    _jobTypes.add(newJobType);
    addController.clear();
    notifyListeners();
  }

  /// Edit an existing job type
  void editJobType(BuildContext context, int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Job Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Job Type Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                _updateJobType(context, index, value, controller);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Updating this job type will affect all existing jobs using this type.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateJobType(context, index, controller.text, controller);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Delete a job type with confirmation
  void deleteJobType(BuildContext context, int index, String jobType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$jobType"?'),
            const SizedBox(height: 12),
            const Text(
              'Warning: Existing jobs using this type will need to be reassigned to a different type.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _jobTypes.removeAt(index);
              notifyListeners();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job type "$jobType" deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Update job type name
  void _updateJobType(BuildContext context, int index, String newName, TextEditingController controller) {
    final trimmedName = newName.trim();
    
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job type name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check for duplicates (case-insensitive), excluding current item
    final lowerNewName = trimmedName.toLowerCase();
    final hasDuplicate = _jobTypes.asMap().entries.any((entry) {
      return entry.key != index && entry.value.toLowerCase() == lowerNewName;
    });
    
    if (hasDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A job type with this name already exists'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    _jobTypes[index] = trimmedName;
    notifyListeners();
    controller.dispose();
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Job type updated to "$trimmedName"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    addController.dispose();
    super.dispose();
  }
}