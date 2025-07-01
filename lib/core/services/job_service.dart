import 'package:flutter/foundation.dart';
import '../../data/models/business/job.dart';
import '../../data/repositories/job_repository.dart';

/// Service class for job management operations
/// Provides business logic layer between UI and data layer
class JobService {
  final JobRepository _repository = JobRepository();

  /// Get all jobs
  Future<List<Job>> getAllJobs() async {
    return await _repository.getAllJobs();
  }

  /// Get jobs by status
  Future<List<Job>> getJobsByStatus(JobStatus status) async {
    return await _repository.getJobsByStatus(status);
  }

  /// Get jobs by type string
  Future<List<Job>> getJobsByTypeString(String type) async {
    return await _repository.getJobsByTypeString(type);
  }

  /// Get jobs for customer
  Future<List<Job>> getJobsForCustomer(String customerId) async {
    return await _repository.getJobsByCustomerId(customerId);
  }

  /// Create a new job
  Future<bool> createJob(Job job) async {
    try {
      return await _repository.createJob(job);
    } catch (e) {
      debugPrint('Error creating job: $e');
      return false;
    }
  }

  /// Update job
  Future<bool> updateJob(Job job) async {
    try {
      return await _repository.updateJob(job);
    } catch (e) {
      debugPrint('Error updating job: $e');
      return false;
    }
  }

  /// Delete job
  Future<bool> deleteJob(String jobId) async {
    try {
      return await _repository.deleteJob(jobId);
    } catch (e) {
      debugPrint('Error deleting job: $e');
      return false;
    }
  }

  /// Update job status
  Future<bool> updateJobStatus(String jobId, JobStatus newStatus) async {
    try {
      return await _repository.updateJobStatus(jobId, newStatus);
    } catch (e) {
      debugPrint('Error updating job status: $e');
      return false;
    }
  }

  /// Update job progress
  Future<bool> updateJobProgress(String jobId, int progressPercentage) async {
    try {
      return await _repository.updateJobProgress(jobId, progressPercentage);
    } catch (e) {
      debugPrint('Error updating job progress: $e');
      return false;
    }
  }

  /// Search jobs
  Future<List<Job>> searchJobs(String query) async {
    return await _repository.searchJobs(query);
  }

  /// Get job statistics
  Future<Map<String, int>> getJobStatistics() async {
    return await _repository.getJobStatistics();
  }

  /// Get jobs for calendar view
  Future<Map<DateTime, List<Job>>> getJobsForCalendar(DateTime month) async {
    return await _repository.getJobsForCalendar(month);
  }

  /// Get overdue jobs
  Future<List<Job>> getOverdueJobs() async {
    return await _repository.getOverdueJobs();
  }

  /// Get active jobs
  Future<List<Job>> getActiveJobs() async {
    return await _repository.getActiveJobs();
  }

  /// Get scheduled jobs
  Future<List<Job>> getScheduledJobs() async {
    return await _repository.getScheduledJobs();
  }

  /// Get completed jobs
  Future<List<Job>> getCompletedJobs() async {
    return await _repository.getCompletedJobs();
  }


  /// Close connections
  Future<void> close() async {
    await _repository.close();
  }
}