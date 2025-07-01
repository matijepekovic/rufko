import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/business/job.dart';
import '../../../../data/models/business/customer.dart';
import '../controllers/job_detail_controller.dart';
import 'job_form_screen.dart';

/// Job Detail Screen for viewing and editing individual jobs
class JobDetailScreen extends StatefulWidget {
  final Job job;
  final Customer? customer;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.customer,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobDetailController _controller;
  final _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    _controller = JobDetailController();
    _controller.initialize(widget.job);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        _controller.clearMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _controller.job ?? widget.job;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(job.title),
        backgroundColor: _controller.getStatusColor(),
        foregroundColor: Colors.white,
        actions: [
          if (_controller.canEditJob())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editJob(),
              tooltip: 'Edit Job',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              if (_controller.canDeleteJob())
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(job),
                  const SizedBox(height: 16),
                  _buildJobInfoCard(job),
                  const SizedBox(height: 16),
                  _buildScheduleCard(job),
                  const SizedBox(height: 16),
                  _buildLocationCard(job),
                  if (job.crewMembers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCrewCard(job),
                  ],
                  if (job.materialsList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMaterialsCard(job),
                  ],
                  if (job.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(job),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(job),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(job.status),
                  color: _controller.getStatusColor(),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${job.status.displayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (job.priority == JobPriority.high || job.priority == JobPriority.urgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: job.priority == JobPriority.urgent ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.priority.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (job.status != JobStatus.complete) ...[
              const SizedBox(height: 12),
              Text(
                'Progress: ${job.progressPercentage}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: job.progressPercentage / 100.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  job.progressPercentage >= 80 
                      ? Colors.green 
                      : job.progressPercentage >= 50 
                          ? Colors.orange 
                          : Colors.blue,
                ),
              ),
            ],
            if (job.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade800, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Customer', job.customerName),
            _buildInfoRow('Type', job.type),
            _buildInfoRow('Priority', job.priority.displayName),
            if (job.description.isNotEmpty)
              _buildInfoRow('Description', job.description),
            if (job.estimatedCost != null)
              _buildInfoRow('Estimated Cost', '\$${job.estimatedCost!.toStringAsFixed(2)}'),
            if (job.actualCost != null)
              _buildInfoRow('Actual Cost', '\$${job.actualCost!.toStringAsFixed(2)}'),
            _buildInfoRow('Duration', '${job.estimatedDurationHours} hours'),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_controller.canEditJob())
                  TextButton.icon(
                    onPressed: _editSchedule,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (job.scheduledStartDate != null)
              _buildInfoRow('Start Date', _dateFormat.format(job.scheduledStartDate!))
            else
              _buildInfoRow('Start Date', 'Not scheduled'),
            if (job.scheduledEndDate != null)
              _buildInfoRow('End Date', _dateFormat.format(job.scheduledEndDate!))
            else
              _buildInfoRow('End Date', 'Not set'),
            if (job.actualStartDate != null)
              _buildInfoRow('Actual Start', _dateFormat.format(job.actualStartDate!)),
            if (job.actualEndDate != null)
              _buildInfoRow('Actual End', _dateFormat.format(job.actualEndDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _openMaps(job.fullAddress),
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Navigate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Address', job.fullAddress),
            if (job.latitude != null && job.longitude != null)
              _buildInfoRow('Coordinates', '${job.latitude!.toStringAsFixed(6)}, ${job.longitude!.toStringAsFixed(6)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crew Assignment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (job.leadTechnician != null)
              _buildInfoRow('Lead Technician', job.leadTechnician!),
            const SizedBox(height: 8),
            ...job.crewMembers.map((member) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    member.role.toLowerCase().contains('lead') ? Icons.star : Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${member.name} - ${member.role}'),
                  ),
                  if (member.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 16),
                      onPressed: () => _makePhoneCall(member.phone!),
                      tooltip: 'Call ${member.name}',
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Materials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...job.materialsList.map((material) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(material),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(Job job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(job.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Job job) {
    final nextStatus = _controller.getNextLogicalStatus();
    final availableStatuses = _controller.getAvailableStatuses();

    return Column(
      children: [
        if (nextStatus != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _controller.updateJobStatus(nextStatus),
              icon: Icon(_getStatusIcon(nextStatus)),
              label: Text('Mark as ${nextStatus.displayName}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(nextStatus),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (availableStatuses.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showStatusDialog,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change Status'),
            ),
          ),
        ],
        if (job.status == JobStatus.active) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showProgressDialog,
              icon: const Icon(Icons.trending_up),
              label: const Text('Update Progress'),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.draft:
        return Icons.drafts;
      case JobStatus.scheduled:
        return Icons.schedule;
      case JobStatus.active:
        return Icons.play_circle_filled;
      case JobStatus.complete:
        return Icons.check_circle;
      case JobStatus.cancelled:
        return Icons.cancel;
      case JobStatus.onHold:
        return Icons.pause_circle_filled;
    }
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.draft:
        return Colors.grey;
      case JobStatus.scheduled:
        return Colors.blue;
      case JobStatus.active:
        return Colors.green;
      case JobStatus.complete:
        return Colors.teal;
      case JobStatus.cancelled:
        return Colors.red;
      case JobStatus.onHold:
        return Colors.orange;
    }
  }

  Future<void> _editJob() async {
    final job = _controller.job ?? widget.job;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JobFormScreen(initialJob: job),
        fullscreenDialog: true,
      ),
    );
    
    if (result == true) {
      // Job was updated, refresh the data
      _controller.refreshJob();
    }
  }

  void _editSchedule() {
    // TODO: Open schedule edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule editing - Coming soon')),
    );
  }

  void _showStatusDialog() {
    final availableStatuses = _controller.getAvailableStatuses();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Job Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) => ListTile(
            leading: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
            title: Text(status.displayName),
            onTap: () {
              Navigator.of(context).pop();
              _controller.updateJobStatus(status);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showProgressDialog() {
    final job = _controller.job ?? widget.job;
    int currentProgress = job.progressPercentage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Progress: $currentProgress%'),
              const SizedBox(height: 16),
              Slider(
                value: currentProgress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$currentProgress%',
                onChanged: (value) {
                  setState(() {
                    currentProgress = value.round();
                  });
                },
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
                Navigator.of(context).pop();
                _controller.updateJobProgress(currentProgress);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _controller.refreshJob();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _controller.deleteJob();
              if (success) {
                if (mounted) {
                  Navigator.of(context).pop(true); // Return to previous screen
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/?q=$encodedAddress');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final phoneNumber = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$phoneNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }
}