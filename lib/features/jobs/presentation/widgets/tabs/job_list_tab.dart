import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../data/models/business/job.dart';
import '../../../../../data/repositories/job_repository.dart';
import '../../screens/job_detail_screen.dart';

/// Job List Tab with sorting and filtering functionality
/// Allows sorting by: active, scheduled, type, complete
class JobListTab extends StatefulWidget {
  const JobListTab({super.key});

  @override
  State<JobListTab> createState() => _JobListTabState();
}

class _JobListTabState extends State<JobListTab> {
  final JobRepository _jobRepository = JobRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Job> _allJobs = [];
  List<Job> _filteredJobs = [];
  String _selectedSort = 'all';
  bool _isLoading = true;
  String _searchQuery = '';

  final _dateFormat = DateFormat('MMM d, h:mm a');
  final _dateOnlyFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    
    try {
      final jobs = await _jobRepository.getAllJobs();
      setState(() {
        _allJobs = jobs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Job> filtered = List.from(_allJobs);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((job) =>
        job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        job.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        job.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        job.address.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply sort/status filter
    switch (_selectedSort) {
      case 'active':
        filtered = filtered.where((job) => job.status == JobStatus.active).toList();
        filtered.sort((a, b) => (a.scheduledStartDate ?? DateTime.now())
            .compareTo(b.scheduledStartDate ?? DateTime.now()));
        break;
      case 'scheduled':
        filtered = filtered.where((job) => job.status == JobStatus.scheduled).toList();
        filtered.sort((a, b) => (a.scheduledStartDate ?? DateTime.now())
            .compareTo(b.scheduledStartDate ?? DateTime.now()));
        break;
      case 'complete':
        filtered = filtered.where((job) => job.status == JobStatus.complete).toList();
        filtered.sort((a, b) => (b.actualEndDate ?? b.updatedAt)
            .compareTo(a.actualEndDate ?? a.updatedAt));
        break;
      case 'type':
        filtered.sort((a, b) {
          final typeComparison = a.type.compareTo(b.type);
          if (typeComparison != 0) return typeComparison;
          return (a.scheduledStartDate ?? DateTime.now())
              .compareTo(b.scheduledStartDate ?? DateTime.now());
        });
        break;
      case 'overdue':
        filtered = filtered.where((job) => job.isOverdue).toList();
        filtered.sort((a, b) => (a.scheduledEndDate ?? DateTime.now())
            .compareTo(b.scheduledEndDate ?? DateTime.now()));
        break;
      case 'all':
      default:
        filtered.sort((a, b) {
          // Sort by status priority first, then by date
          final statusPriority = {
            JobStatus.active: 1,
            JobStatus.scheduled: 2,
            JobStatus.draft: 3,
            JobStatus.onHold: 4,
            JobStatus.complete: 5,
            JobStatus.cancelled: 6,
          };
          
          final statusComparison = (statusPriority[a.status] ?? 99)
              .compareTo(statusPriority[b.status] ?? 99);
          
          if (statusComparison != 0) return statusComparison;
          
          return (a.scheduledStartDate ?? a.createdAt)
              .compareTo(b.scheduledStartDate ?? b.createdAt);
        });
        break;
    }

    _filteredJobs = filtered;
  }

  void _onSortChanged(String sortType) {
    setState(() {
      _selectedSort = sortType;
      _applyFilters();
    });
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

  void _viewJobDetails(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        _buildStatusFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredJobs.isEmpty
                  ? _buildEmptyState()
                  : _buildJobsList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: _onSortChanged,
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Jobs')),
              const PopupMenuItem(value: 'active', child: Text('Active Only')),
              const PopupMenuItem(value: 'scheduled', child: Text('Scheduled Only')),
              const PopupMenuItem(value: 'complete', child: Text('Complete Only')),
              const PopupMenuItem(value: 'type', child: Text('Sort by Type')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue Only')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    final filters = [
      {'key': 'all', 'label': 'All', 'count': _allJobs.length},
      {'key': 'active', 'label': 'Active', 'count': _allJobs.where((j) => j.status == JobStatus.active).length},
      {'key': 'scheduled', 'label': 'Scheduled', 'count': _allJobs.where((j) => j.status == JobStatus.scheduled).length},
      {'key': 'complete', 'label': 'Complete', 'count': _allJobs.where((j) => j.status == JobStatus.complete).length},
      {'key': 'overdue', 'label': 'Overdue', 'count': _allJobs.where((j) => j.isOverdue).length},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedSort == filter['key'];
          
          return FilterChip(
            label: Text('${filter['label']} (${filter['count']})'),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                _onSortChanged(filter['key'] as String);
              }
            },
            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No jobs found for "$_searchQuery"'
                : 'No jobs found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search criteria'
                : 'Jobs will appear here once created',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadJobs,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredJobs.length,
        itemBuilder: (context, index) {
          final job = _filteredJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobHeader(job),
            const SizedBox(height: 8),
            _buildJobDetails(job),
            const SizedBox(height: 12),
            _buildJobProgress(job),
            const SizedBox(height: 12),
            _buildJobActions(job),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader(Job job) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.customerName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusChip(job.status),
        if (job.priority == JobPriority.high || job.priority == JobPriority.urgent) ...[
          const SizedBox(width: 8),
          _buildPriorityChip(job.priority),
        ],
      ],
    );
  }

  Widget _buildStatusChip(JobStatus status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case JobStatus.active:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case JobStatus.scheduled:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case JobStatus.complete:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      case JobStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case JobStatus.onHold:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(JobPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priority == JobPriority.urgent ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJobDetails(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.work_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              job.type,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                job.fullAddress,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (job.scheduledStartDate != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Start: ${_dateFormat.format(job.scheduledStartDate!)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
        if (job.crewMembers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Crew: ${job.crewMembers.map((c) => c.name).join(', ')}',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildJobProgress(Job job) {
    if (job.status == JobStatus.complete) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          const Text('Completed', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (job.actualEndDate != null)
            Text(
              _dateOnlyFormat.format(job.actualEndDate!),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${job.progressPercentage}%', 
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
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
    );
  }

  Widget _buildJobActions(Job job) {
    return Row(
      children: [
        if (job.scheduledStartDate != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openMaps(job.fullAddress),
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text('Navigate'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewJobDetails(job),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}