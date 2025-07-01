import 'package:flutter/material.dart';
import '../controllers/job_type_operations_controller.dart';

/// Dialog for managing job types in app settings
/// Follows the same pattern as CategoryManagerDialog
class JobTypeManagerDialog extends StatefulWidget {
  final List<String> jobTypes;
  final Function(List<String>) onSave;

  const JobTypeManagerDialog({
    super.key,
    required this.jobTypes,
    required this.onSave,
  });

  @override
  State<JobTypeManagerDialog> createState() => _JobTypeManagerDialogState();
}

class _JobTypeManagerDialogState extends State<JobTypeManagerDialog> {
  late JobTypeOperationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JobTypeOperationsController(widget.jobTypes);
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.work_outline,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Job Types',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 450,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildAddSection(),
                const SizedBox(height: 16),
                _buildJobTypesList(),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.jobTypes);
            Navigator.of(context).pop();
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildAddSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Job Type',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller.addController,
                  decoration: const InputDecoration(
                    hintText: 'Enter job type name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _controller.addJobType(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _controller.addJobType,
                icon: const Icon(Icons.add),
                tooltip: 'Add job type',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypesList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Current Job Types',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_controller.jobTypes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a job type to edit it. Job types are used for categorizing and filtering jobs.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _controller.jobTypes.isEmpty
                ? const Center(
                    child: Text(
                      'No job types defined.\nAdd some job types to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _controller.jobTypes.length,
                    itemBuilder: (context, index) {
                      final jobType = _controller.jobTypes[index];
                      return _buildJobTypeCard(jobType, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypeCard(String jobType, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          jobType,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _controller.editJobType(context, index, jobType),
              tooltip: 'Edit job type',
            ),
            if (_controller.jobTypes.length > 1)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _controller.deleteJobType(context, index, jobType),
                tooltip: 'Delete job type',
              ),
          ],
        ),
        onTap: () => _controller.editJobType(context, index, jobType),
      ),
    );
  }
}