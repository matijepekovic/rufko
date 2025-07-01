import 'package:flutter/material.dart';
import '../../../../data/models/business/job.dart';
import '../../../../core/services/job_service.dart';

/// Controller for job detail operations
/// Handles job viewing, editing, and status updates
class JobDetailController extends ChangeNotifier {
  final JobService _jobService = JobService();
  
  Job? _job;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  Job? get job => _job;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Initialize controller with a job
  void initialize(Job job) {
    _job = job;
    _clearMessages();
    notifyListeners();
  }

  /// Refresh job data from database
  Future<void> refreshJob() async {
    if (_job == null) return;
    
    _setLoading(true);
    try {
      final jobs = await _jobService.getAllJobs();
      final updatedJob = jobs.firstWhere(
        (j) => j.id == _job!.id,
        orElse: () => _job!,
      );
      _job = updatedJob;
      _setSuccessMessage('Job data refreshed');
    } catch (e) {
      _setErrorMessage('Failed to refresh job data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update job status
  Future<void> updateJobStatus(JobStatus newStatus) async {
    if (_job == null) return;
    
    _setLoading(true);
    try {
      final success = await _jobService.updateJobStatus(_job!.id, newStatus);
      if (success) {
        _job = _job!.copyWith(status: newStatus, updatedAt: DateTime.now());
        _setSuccessMessage('Job status updated to ${newStatus.displayName}');
      } else {
        _setErrorMessage('Failed to update job status');
      }
    } catch (e) {
      _setErrorMessage('Error updating job status: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update job progress
  Future<void> updateJobProgress(int progressPercentage) async {
    if (_job == null) return;
    
    _setLoading(true);
    try {
      final success = await _jobService.updateJobProgress(_job!.id, progressPercentage);
      if (success) {
        _job = _job!.copyWith(
          progressPercentage: progressPercentage,
          updatedAt: DateTime.now(),
        );
        _setSuccessMessage('Job progress updated to $progressPercentage%');
      } else {
        _setErrorMessage('Failed to update job progress');
      }
    } catch (e) {
      _setErrorMessage('Error updating job progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update job schedule
  Future<void> updateJobSchedule(DateTime? startDate, DateTime? endDate) async {
    if (_job == null) return;
    
    _setLoading(true);
    try {
      final updatedJob = _job!.copyWith(
        scheduledStartDate: startDate,
        scheduledEndDate: endDate,
        updatedAt: DateTime.now(),
      );
      
      final success = await _jobService.updateJob(updatedJob);
      if (success) {
        _job = updatedJob;
        _setSuccessMessage('Job schedule updated');
      } else {
        _setErrorMessage('Failed to update job schedule');
      }
    } catch (e) {
      _setErrorMessage('Error updating job schedule: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update job details
  Future<void> updateJob(Job updatedJob) async {
    _setLoading(true);
    try {
      final success = await _jobService.updateJob(updatedJob);
      if (success) {
        _job = updatedJob;
        _setSuccessMessage('Job updated successfully');
      } else {
        _setErrorMessage('Failed to update job');
      }
    } catch (e) {
      _setErrorMessage('Error updating job: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete job
  Future<bool> deleteJob() async {
    if (_job == null) return false;
    
    _setLoading(true);
    try {
      final success = await _jobService.deleteJob(_job!.id);
      if (success) {
        _setSuccessMessage('Job deleted successfully');
        return true;
      } else {
        _setErrorMessage('Failed to delete job');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Error deleting job: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start/stop editing mode
  void setEditingMode(bool editing) {
    _isEditing = editing;
    if (editing) {
      _clearMessages();
    }
    notifyListeners();
  }

  /// Get next logical status for quick updates
  JobStatus? getNextLogicalStatus() {
    if (_job == null) return null;
    
    switch (_job!.status) {
      case JobStatus.draft:
        return JobStatus.scheduled;
      case JobStatus.scheduled:
        return JobStatus.active;
      case JobStatus.active:
        return JobStatus.complete;
      case JobStatus.onHold:
        return JobStatus.active;
      default:
        return null;
    }
  }

  /// Get available status transitions
  List<JobStatus> getAvailableStatuses() {
    if (_job == null) return [];
    
    switch (_job!.status) {
      case JobStatus.draft:
        return [JobStatus.scheduled, JobStatus.cancelled];
      case JobStatus.scheduled:
        return [JobStatus.active, JobStatus.onHold, JobStatus.cancelled];
      case JobStatus.active:
        return [JobStatus.complete, JobStatus.onHold, JobStatus.cancelled];
      case JobStatus.onHold:
        return [JobStatus.active, JobStatus.cancelled];
      case JobStatus.complete:
        return []; // Completed jobs cannot change status
      case JobStatus.cancelled:
        return [JobStatus.draft]; // Can restart cancelled jobs
    }
  }

  /// Check if job can be edited
  bool canEditJob() {
    return _job != null && 
           _job!.status != JobStatus.complete && 
           _job!.status != JobStatus.cancelled;
  }

  /// Check if job can be deleted
  bool canDeleteJob() {
    return _job != null && 
           (_job!.status == JobStatus.draft || 
            _job!.status == JobStatus.cancelled);
  }

  /// Get status color for UI
  Color getStatusColor() {
    if (_job == null) return Colors.grey;
    
    switch (_job!.status) {
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

  /// Clear all messages
  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
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

}