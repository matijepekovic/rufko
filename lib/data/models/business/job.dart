// lib/data/models/business/job.dart

import 'package:uuid/uuid.dart';

/// Job status enumeration
enum JobStatus {
  draft('draft', 'Draft'),
  scheduled('scheduled', 'Scheduled'),
  active('active', 'Active'),
  complete('complete', 'Complete'),
  cancelled('cancelled', 'Cancelled'),
  onHold('on_hold', 'On Hold');

  const JobStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static JobStatus fromString(String value) {
    return JobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => JobStatus.draft,
    );
  }
}

/// Job type validation helper
class JobTypeHelper {
  /// Default job types if none are configured
  static const List<String> defaultJobTypes = [
    'Roof Replacement',
    'Roof Repair',
    'Gutter Installation', 
    'Gutter Repair',
    'Emergency Repair',
    'Inspection',
    'Maintenance',
    'Siding',
    'Windows',
    'Other'
  ];

  /// Validate if a job type is valid (non-empty)
  static bool isValidJobType(String jobType) {
    return jobType.trim().isNotEmpty;
  }

  /// Get normalized job type (trimmed and capitalized)
  static String normalizeJobType(String jobType) {
    return jobType.trim();
  }
}

/// Job priority enumeration
enum JobPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const JobPriority(this.value, this.displayName);
  final String value;
  final String displayName;

  static JobPriority fromString(String value) {
    return JobPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => JobPriority.medium,
    );
  }
}

/// Crew member assignment
class CrewMember {
  final String id;
  final String name;
  final String role;
  final String? phone;
  final String? email;

  CrewMember({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
    };
  }

  factory CrewMember.fromMap(Map<String, dynamic> map) {
    return CrewMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'],
      email: map['email'],
    );
  }
}

/// Main Job model
class Job {
  late String id;
  final String customerId;
  final String customerName;
  final String title;
  final String description;
  final String type; // Changed from JobType enum to String
  final JobStatus status;
  final JobPriority priority;
  
  // Scheduling
  final DateTime? scheduledStartDate;
  final DateTime? scheduledEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final int estimatedDurationHours;
  
  // Location
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  
  // Crew and Resources
  final List<CrewMember> crewMembers;
  final String? leadTechnician;
  
  // Financial
  final double? estimatedCost;
  final double? actualCost;
  final String? quoteId;
  
  // Progress and Notes
  final int progressPercentage;
  final String? notes;
  final List<String> materialsList;
  final Map<String, dynamic> additionalData;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Job({
    String? id,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.description,
    required this.type,
    this.status = JobStatus.draft,
    this.priority = JobPriority.medium,
    this.scheduledStartDate,
    this.scheduledEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.estimatedDurationHours = 8,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    List<CrewMember>? crewMembers,
    this.leadTechnician,
    this.estimatedCost,
    this.actualCost,
    this.quoteId,
    this.progressPercentage = 0,
    this.notes,
    List<String>? materialsList,
    Map<String, dynamic>? additionalData,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy = 'system',
  })  : crewMembers = crewMembers ?? [],
        materialsList = materialsList ?? [],
        additionalData = additionalData ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  /// Get full address string
  String get fullAddress {
    final parts = [address, city, state, zipCode].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Check if job is overdue
  bool get isOverdue {
    if (scheduledEndDate == null || status == JobStatus.complete) return false;
    return DateTime.now().isAfter(scheduledEndDate!);
  }

  /// Check if job is in progress
  bool get isInProgress {
    return status == JobStatus.active && progressPercentage > 0 && progressPercentage < 100;
  }

  /// Get estimated completion date based on progress
  DateTime? get estimatedCompletionDate {
    if (actualStartDate == null || progressPercentage == 0) return scheduledEndDate;
    
    final daysWorked = DateTime.now().difference(actualStartDate!).inDays;
    if (daysWorked == 0) return scheduledEndDate;
    
    final estimatedTotalDays = (daysWorked * 100) / progressPercentage;
    return actualStartDate!.add(Duration(days: estimatedTotalDays.round()));
  }

  /// Create a copy with updated fields
  Job copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? title,
    String? description,
    String? type,
    JobStatus? status,
    JobPriority? priority,
    DateTime? scheduledStartDate,
    DateTime? scheduledEndDate,
    DateTime? actualStartDate,
    DateTime? actualEndDate,
    int? estimatedDurationHours,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    List<CrewMember>? crewMembers,
    String? leadTechnician,
    double? estimatedCost,
    double? actualCost,
    String? quoteId,
    int? progressPercentage,
    String? notes,
    List<String>? materialsList,
    Map<String, dynamic>? additionalData,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Job(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledStartDate: scheduledStartDate ?? this.scheduledStartDate,
      scheduledEndDate: scheduledEndDate ?? this.scheduledEndDate,
      actualStartDate: actualStartDate ?? this.actualStartDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      estimatedDurationHours: estimatedDurationHours ?? this.estimatedDurationHours,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      crewMembers: crewMembers ?? this.crewMembers,
      leadTechnician: leadTechnician ?? this.leadTechnician,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      quoteId: quoteId ?? this.quoteId,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      notes: notes ?? this.notes,
      materialsList: materialsList ?? this.materialsList,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'title': title,
      'description': description,
      'type': type,
      'status': status.value,
      'priority': priority.value,
      'scheduled_start_date': scheduledStartDate?.toIso8601String(),
      'scheduled_end_date': scheduledEndDate?.toIso8601String(),
      'actual_start_date': actualStartDate?.toIso8601String(),
      'actual_end_date': actualEndDate?.toIso8601String(),
      'estimated_duration_hours': estimatedDurationHours,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'crew_members': crewMembers.map((member) => member.toMap()).toList(),
      'lead_technician': leadTechnician,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'quote_id': quoteId,
      'progress_percentage': progressPercentage,
      'notes': notes,
      'materials_list': materialsList,
      'additional_data': additionalData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Create from Map (database)
  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'],
      customerId: map['customer_id'] ?? '',
      customerName: map['customer_name'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'Other',
      status: JobStatus.fromString(map['status'] ?? ''),
      priority: JobPriority.fromString(map['priority'] ?? ''),
      scheduledStartDate: map['scheduled_start_date'] != null ? DateTime.parse(map['scheduled_start_date']) : null,
      scheduledEndDate: map['scheduled_end_date'] != null ? DateTime.parse(map['scheduled_end_date']) : null,
      actualStartDate: map['actual_start_date'] != null ? DateTime.parse(map['actual_start_date']) : null,
      actualEndDate: map['actual_end_date'] != null ? DateTime.parse(map['actual_end_date']) : null,
      estimatedDurationHours: map['estimated_duration_hours'] ?? 8,
      address: map['address'] ?? '',
      city: map['city'],
      state: map['state'],
      zipCode: map['zip_code'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      crewMembers: map['crew_members'] != null 
          ? (map['crew_members'] as List).map((memberMap) => CrewMember.fromMap(memberMap)).toList()
          : [],
      leadTechnician: map['lead_technician'],
      estimatedCost: map['estimated_cost']?.toDouble(),
      actualCost: map['actual_cost']?.toDouble(),
      quoteId: map['quote_id'],
      progressPercentage: map['progress_percentage'] ?? 0,
      notes: map['notes'],
      materialsList: map['materials_list'] != null ? List<String>.from(map['materials_list']) : [],
      additionalData: map['additional_data'] ?? {},
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      createdBy: map['created_by'] ?? 'system',
    );
  }

  @override
  String toString() {
    return 'Job(id: $id, title: $title, status: ${status.displayName}, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}