import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import '../models/business/job.dart';

/// SQLite database manager for job-related data
/// Handles database creation, migrations, and provides connection management for jobs and crew assignments
class JobDatabase {
  static const String _databaseName = 'rufko_jobs.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String jobsTable = 'jobs';

  // Singleton pattern
  static final JobDatabase _instance = JobDatabase._internal();
  factory JobDatabase() => _instance;
  JobDatabase._internal();

  static Database? _database;

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Initialize database factory for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      databaseFactory = databaseFactoryFfi;
    }
    
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create jobs table
    await db.execute('''
      CREATE TABLE $jobsTable (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        priority TEXT NOT NULL DEFAULT 'medium',
        scheduled_start_date TEXT,
        scheduled_end_date TEXT,
        actual_start_date TEXT,
        actual_end_date TEXT,
        estimated_duration_hours INTEGER DEFAULT 8,
        address TEXT NOT NULL,
        city TEXT,
        state TEXT,
        zip_code TEXT,
        latitude REAL,
        longitude REAL,
        crew_members TEXT, -- JSON array as text
        lead_technician TEXT,
        estimated_cost REAL,
        actual_cost REAL,
        quote_id TEXT,
        progress_percentage INTEGER DEFAULT 0,
        notes TEXT,
        materials_list TEXT, -- JSON array as text
        additional_data TEXT, -- JSON object as text
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'system'
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_jobs_customer_id ON $jobsTable (customer_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_status ON $jobsTable (status)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_type ON $jobsTable (type)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_priority ON $jobsTable (priority)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_scheduled_start_date ON $jobsTable (scheduled_start_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_scheduled_end_date ON $jobsTable (scheduled_end_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_created_at ON $jobsTable (created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_address ON $jobsTable (address)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_quote_id ON $jobsTable (quote_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_jobs_progress_percentage ON $jobsTable (progress_percentage)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE $jobsTable ADD COLUMN new_field TEXT');
    }
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Clear all data (for testing or data reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(jobsTable);
  }

  // CRUD Operations

  /// Insert a new job
  Future<int> insertJob(Job job) async {
    final db = await database;
    final jobMap = job.toMap();
    
    // Convert lists and maps to JSON strings for storage
    jobMap['crew_members'] = jsonEncode(jobMap['crew_members']);
    jobMap['materials_list'] = jsonEncode(jobMap['materials_list']);
    jobMap['additional_data'] = jsonEncode(jobMap['additional_data']);
    
    return await db.insert(jobsTable, jobMap);
  }

  /// Get all jobs
  Future<List<Job>> getAllJobs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get jobs by status
  Future<List<Job>> getJobsByStatus(JobStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'scheduled_start_date ASC, created_at DESC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get jobs by type string
  Future<List<Job>> getJobsByTypeString(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'scheduled_start_date ASC, created_at DESC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get jobs by customer ID
  Future<List<Job>> getJobsByCustomerId(String customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get jobs scheduled for a specific date range
  Future<List<Job>> getJobsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'scheduled_start_date >= ? AND scheduled_start_date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'scheduled_start_date ASC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get active jobs (currently in progress)
  Future<List<Job>> getActiveJobs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'status = ?',
      whereArgs: [JobStatus.active.value],
      orderBy: 'scheduled_start_date ASC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get scheduled jobs (future jobs)
  Future<List<Job>> getScheduledJobs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'status = ?',
      whereArgs: [JobStatus.scheduled.value],
      orderBy: 'scheduled_start_date ASC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get completed jobs
  Future<List<Job>> getCompletedJobs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'status = ?',
      whereArgs: [JobStatus.complete.value],
      orderBy: 'actual_end_date DESC, updated_at DESC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get overdue jobs
  Future<List<Job>> getOverdueJobs() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'scheduled_end_date < ? AND status != ? AND status != ?',
      whereArgs: [now, JobStatus.complete.value, JobStatus.cancelled.value],
      orderBy: 'scheduled_end_date ASC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get job by ID
  Future<Job?> getJobById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return _jobFromDatabaseMap(maps.first);
    }
    return null;
  }

  /// Update job
  Future<int> updateJob(Job job) async {
    final db = await database;
    final jobMap = job.toMap();
    
    // Convert lists and maps to JSON strings for storage
    jobMap['crew_members'] = jsonEncode(jobMap['crew_members']);
    jobMap['materials_list'] = jsonEncode(jobMap['materials_list']);
    jobMap['additional_data'] = jsonEncode(jobMap['additional_data']);
    
    return await db.update(
      jobsTable,
      jobMap,
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  /// Delete job
  Future<int> deleteJob(String id) async {
    final db = await database;
    return await db.delete(
      jobsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search jobs by text (title, description, customer name, address)
  Future<List<Job>> searchJobs(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      jobsTable,
      where: '''
        title LIKE ? OR 
        description LIKE ? OR 
        customer_name LIKE ? OR 
        address LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => _jobFromDatabaseMap(map)).toList();
  }

  /// Get job statistics
  Future<Map<String, int>> getJobStatistics() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM $jobsTable
      GROUP BY status
    ''');
    
    final Map<String, int> stats = {};
    for (var row in result) {
      stats[row['status'] as String] = row['count'] as int;
    }
    
    return stats;
  }

  /// Convert database map to Job object
  Job _jobFromDatabaseMap(Map<String, dynamic> map) {
    // Parse JSON fields back to their original types
    final crewMembersJson = map['crew_members'] as String? ?? '[]';
    final materialsListJson = map['materials_list'] as String? ?? '[]';
    final additionalDataJson = map['additional_data'] as String? ?? '{}';
    
    // Create a new map with parsed JSON data
    final parsedMap = Map<String, dynamic>.from(map);
    parsedMap['crew_members'] = jsonDecode(crewMembersJson);
    parsedMap['materials_list'] = jsonDecode(materialsListJson);
    parsedMap['additional_data'] = jsonDecode(additionalDataJson);
    
    return Job.fromMap(parsedMap);
  }
}