import 'package:flutter/foundation.dart';
import '../database/job_database.dart';
import '../models/business/job.dart';

/// Repository pattern implementation for Job data operations
/// Provides a clean interface between the business logic and data layer
/// Handles error management and data transformation
class JobRepository {
  final JobDatabase _database = JobDatabase();

  /// Get all jobs
  Future<List<Job>> getAllJobs() async {
    try {
      return await _database.getAllJobs();
    } catch (e) {
      debugPrint('Error getting all jobs: $e');
      return [];
    }
  }

  /// Get jobs by status
  Future<List<Job>> getJobsByStatus(JobStatus status) async {
    try {
      return await _database.getJobsByStatus(status);
    } catch (e) {
      debugPrint('Error getting jobs by status $status: $e');
      return [];
    }
  }

  /// Get jobs by type string
  Future<List<Job>> getJobsByTypeString(String type) async {
    try {
      return await _database.getJobsByTypeString(type);
    } catch (e) {
      debugPrint('Error getting jobs by type $type: $e');
      return [];
    }
  }

  /// Get jobs by customer ID
  Future<List<Job>> getJobsByCustomerId(String customerId) async {
    try {
      return await _database.getJobsByCustomerId(customerId);
    } catch (e) {
      debugPrint('Error getting jobs for customer $customerId: $e');
      return [];
    }
  }

  /// Get jobs scheduled for a specific date range
  Future<List<Job>> getJobsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _database.getJobsByDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error getting jobs by date range: $e');
      return [];
    }
  }

  /// Get active jobs (currently in progress)
  Future<List<Job>> getActiveJobs() async {
    try {
      return await _database.getActiveJobs();
    } catch (e) {
      debugPrint('Error getting active jobs: $e');
      return [];
    }
  }

  /// Get scheduled jobs (future jobs)
  Future<List<Job>> getScheduledJobs() async {
    try {
      return await _database.getScheduledJobs();
    } catch (e) {
      debugPrint('Error getting scheduled jobs: $e');
      return [];
    }
  }

  /// Get completed jobs
  Future<List<Job>> getCompletedJobs() async {
    try {
      return await _database.getCompletedJobs();
    } catch (e) {
      debugPrint('Error getting completed jobs: $e');
      return [];
    }
  }

  /// Get overdue jobs
  Future<List<Job>> getOverdueJobs() async {
    try {
      return await _database.getOverdueJobs();
    } catch (e) {
      debugPrint('Error getting overdue jobs: $e');
      return [];
    }
  }

  /// Get job by ID
  Future<Job?> getJobById(String id) async {
    try {
      return await _database.getJobById(id);
    } catch (e) {
      debugPrint('Error getting job by ID $id: $e');
      return null;
    }
  }

  /// Create a new job
  Future<bool> createJob(Job job) async {
    try {
      final result = await _database.insertJob(job);
      return result > 0;
    } catch (e) {
      debugPrint('Error creating job: $e');
      return false;
    }
  }

  /// Update an existing job
  Future<bool> updateJob(Job job) async {
    try {
      final result = await _database.updateJob(job);
      return result > 0;
    } catch (e) {
      debugPrint('Error updating job: $e');
      return false;
    }
  }

  /// Delete a job
  Future<bool> deleteJob(String id) async {
    try {
      final result = await _database.deleteJob(id);
      return result > 0;
    } catch (e) {
      debugPrint('Error deleting job: $e');
      return false;
    }
  }

  /// Search jobs by text query
  Future<List<Job>> searchJobs(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllJobs();
      }
      return await _database.searchJobs(query);
    } catch (e) {
      debugPrint('Error searching jobs: $e');
      return [];
    }
  }

  /// Get job statistics
  Future<Map<String, int>> getJobStatistics() async {
    try {
      return await _database.getJobStatistics();
    } catch (e) {
      debugPrint('Error getting job statistics: $e');
      return {};
    }
  }

  /// Update job status
  Future<bool> updateJobStatus(String jobId, JobStatus newStatus) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      final updatedJob = job.copyWith(
        status: newStatus,
        actualStartDate: newStatus == JobStatus.active ? DateTime.now() : job.actualStartDate,
        actualEndDate: newStatus == JobStatus.complete ? DateTime.now() : job.actualEndDate,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error updating job status: $e');
      return false;
    }
  }

  /// Update job progress
  Future<bool> updateJobProgress(String jobId, int progressPercentage) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      // Auto-complete if progress reaches 100%
      JobStatus newStatus = job.status;
      DateTime? endDate = job.actualEndDate;
      
      if (progressPercentage >= 100 && job.status == JobStatus.active) {
        newStatus = JobStatus.complete;
        endDate = DateTime.now();
      }

      final updatedJob = job.copyWith(
        progressPercentage: progressPercentage.clamp(0, 100),
        status: newStatus,
        actualEndDate: endDate,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error updating job progress: $e');
      return false;
    }
  }

  /// Assign crew member to job
  Future<bool> assignCrewMember(String jobId, CrewMember crewMember) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      final updatedCrewMembers = List<CrewMember>.from(job.crewMembers);
      
      // Remove existing member with same ID if exists
      updatedCrewMembers.removeWhere((member) => member.id == crewMember.id);
      
      // Add the new/updated crew member
      updatedCrewMembers.add(crewMember);

      final updatedJob = job.copyWith(
        crewMembers: updatedCrewMembers,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error assigning crew member: $e');
      return false;
    }
  }

  /// Remove crew member from job
  Future<bool> removeCrewMember(String jobId, String crewMemberId) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      final updatedCrewMembers = job.crewMembers
          .where((member) => member.id != crewMemberId)
          .toList();

      final updatedJob = job.copyWith(
        crewMembers: updatedCrewMembers,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error removing crew member: $e');
      return false;
    }
  }

  /// Update job scheduling
  Future<bool> updateJobSchedule(String jobId, DateTime? startDate, DateTime? endDate) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      final updatedJob = job.copyWith(
        scheduledStartDate: startDate,
        scheduledEndDate: endDate,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error updating job schedule: $e');
      return false;
    }
  }

  /// Add material to job
  Future<bool> addMaterial(String jobId, String material) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      final updatedMaterials = List<String>.from(job.materialsList);
      if (!updatedMaterials.contains(material)) {
        updatedMaterials.add(material);
      }

      final updatedJob = job.copyWith(
        materialsList: updatedMaterials,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error adding material: $e');
      return false;
    }
  }

  /// Remove material from job
  Future<bool> removeMaterial(String jobId, String material) async {
    try {
      final job = await getJobById(jobId);
      if (job == null) return false;

      final updatedMaterials = job.materialsList
          .where((m) => m != material)
          .toList();

      final updatedJob = job.copyWith(
        materialsList: updatedMaterials,
        updatedAt: DateTime.now(),
      );

      return await updateJob(updatedJob);
    } catch (e) {
      debugPrint('Error removing material: $e');
      return false;
    }
  }

  /// Get jobs for calendar view (grouped by date)
  Future<Map<DateTime, List<Job>>> getJobsForCalendar(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      
      final jobs = await getJobsByDateRange(startOfMonth, endOfMonth);
      
      final Map<DateTime, List<Job>> jobsByDate = {};
      
      for (final job in jobs) {
        if (job.scheduledStartDate != null) {
          final date = DateTime(
            job.scheduledStartDate!.year,
            job.scheduledStartDate!.month,
            job.scheduledStartDate!.day,
          );
          
          if (jobsByDate[date] == null) {
            jobsByDate[date] = [];
          }
          jobsByDate[date]!.add(job);
        }
      }
      
      return jobsByDate;
    } catch (e) {
      debugPrint('Error getting jobs for calendar: $e');
      return {};
    }
  }

  /// Get jobs with location data for route optimization
  Future<List<Job>> getJobsWithLocations() async {
    try {
      final jobs = await getAllJobs();
      return jobs.where((job) => 
        job.latitude != null && 
        job.longitude != null &&
        (job.status == JobStatus.scheduled || job.status == JobStatus.active)
      ).toList();
    } catch (e) {
      debugPrint('Error getting jobs with locations: $e');
      return [];
    }
  }

  /// Clear all job data (for testing or data reset)
  Future<void> clearAllData() async {
    try {
      await _database.clearAllData();
    } catch (e) {
      debugPrint('Error clearing all job data: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    try {
      await _database.close();
    } catch (e) {
      debugPrint('Error closing job database: $e');
    }
  }
}