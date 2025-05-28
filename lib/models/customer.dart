// lib/models/customer.dart - ENHANCED VERSION (Compatible with existing)

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? address;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  List<String> communicationHistory;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  Customer({
    String? id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    List<String>? communicationHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : communicationHistory = communicationHistory ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  // ENHANCED: Add communication with type
  void addCommunication(String entry, {String type = 'note'}) {
    final timestamp = DateTime.now().toIso8601String();
    final typePrefix = _getTypePrefix(type);
    communicationHistory.add('$timestamp: $typePrefix$entry');
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  // NEW: Add structured communication with more context
  void addStructuredCommunication({
    required String content,
    String type = 'note',
    String? subject,
    bool urgent = false,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final typePrefix = _getTypePrefix(type);
    final urgentFlag = urgent ? '[URGENT] ' : '';
    final subjectPart = subject != null ? '[$subject] ' : '';

    communicationHistory.add('$timestamp: $typePrefix$urgentFlag$subjectPart$content');
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  // NEW: Add follow-up reminder
  void addFollowUp({
    required String content,
    required DateTime followUpDate,
    String priority = 'normal',
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final followUpFormatted = followUpDate.toIso8601String().split('T')[0]; // Just date
    final priorityFlag = priority == 'high' ? '[HIGH PRIORITY] ' : '';

    communicationHistory.add('$timestamp: 📅 FOLLOW-UP ($followUpFormatted): $priorityFlag$content');
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  // NEW: Quick communication templates for roofing
  void addQuickNote(String templateType, {Map<String, String>? params}) {
    String content;
    String type = 'note';

    switch (templateType) {
      case 'initial_contact':
        content = 'Initial contact - Customer interested in ${params?['service'] ?? 'roofing services'}';
        type = 'call';
        break;
      case 'quote_sent':
        content = 'Quote #${params?['quote_number'] ?? 'XXX'} sent via ${params?['method'] ?? 'email'}';
        type = 'email';
        break;
      case 'site_visit_scheduled':
        content = 'Site visit scheduled for ${params?['date'] ?? 'TBD'} at ${params?['time'] ?? 'TBD'}';
        type = 'meeting';
        break;
      case 'materials_ordered':
        content = 'Materials ordered - ${params?['details'] ?? 'Standard roofing materials'}';
        type = 'note';
        break;
      case 'job_started':
        content = 'Job started - ${params?['crew_size'] ?? '3'} crew members on site';
        type = 'site_visit';
        break;
      case 'job_completed':
        content = 'Job completed - Final inspection ${params?['passed'] ?? 'passed'}';
        type = 'site_visit';
        break;
      case 'payment_received':
        content = 'Payment received - \$${params?['amount'] ?? '0'} via ${params?['method'] ?? 'check'}';
        type = 'note';
        break;
      case 'warranty_call':
        content = 'Warranty service call - ${params?['issue'] ?? 'General maintenance'}';
        type = 'call';
        break;
      default:
        content = params?['content'] ?? 'General communication';
    }

    addCommunication(content, type: type);
  }

  String _getTypePrefix(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return '📞 ';
      case 'email':
        return '📧 ';
      case 'meeting':
        return '🤝 ';
      case 'site_visit':
        return '🏠 ';
      case 'text':
        return '💬 ';
      case 'note':
      default:
        return '📝 ';
    }
  }

  // ENHANCED: Get communications by type
  List<String> getCommunicationsByType(String type) {
    final prefix = _getTypePrefix(type);
    return communicationHistory.where((comm) => comm.contains(prefix)).toList();
  }

  // NEW: Get recent communications (last N days)
  List<String> getRecentCommunications([int days = 30]) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return communicationHistory.where((comm) {
      try {
        final dateStr = comm.split(': ')[0];
        final commDate = DateTime.parse(dateStr);
        return commDate.isAfter(cutoffDate);
      } catch (e) {
        return false; // Invalid date format, exclude
      }
    }).toList();
  }

  // NEW: Get follow-ups that are due
  List<String> getDueFollowUps() {
    final today = DateTime.now();
    return communicationHistory.where((comm) {
      if (!comm.contains('📅 FOLLOW-UP')) return false;
      try {
        final regex = RegExp(r'FOLLOW-UP \(([0-9-]+)\)');
        final match = regex.firstMatch(comm);
        if (match != null) {
          final followUpDate = DateTime.parse(match.group(1)!);
          return followUpDate.isBefore(today) ||
              followUpDate.day == today.day &&
                  followUpDate.month == today.month &&
                  followUpDate.year == today.year;
        }
      } catch (e) {
        // Invalid date format
      }
      return false;
    }).toList();
  }

  // NEW: Communication statistics
  Map<String, int> getCommunicationStats() {
    final stats = <String, int>{
      'total': communicationHistory.length,
      'calls': 0,
      'emails': 0,
      'meetings': 0,
      'site_visits': 0,
      'notes': 0,
      'follow_ups': 0,
    };

    for (final comm in communicationHistory) {
      if (comm.contains('📞')) stats['calls'] = stats['calls']! + 1;
      else if (comm.contains('📧')) stats['emails'] = stats['emails']! + 1;
      else if (comm.contains('🤝')) stats['meetings'] = stats['meetings']! + 1;
      else if (comm.contains('🏠')) stats['site_visits'] = stats['site_visits']! + 1;
      else if (comm.contains('📝')) stats['notes'] = stats['notes']! + 1;

      if (comm.contains('📅 FOLLOW-UP')) stats['follow_ups'] = stats['follow_ups']! + 1;
    }

    return stats;
  }

  // Existing methods remain unchanged
  void updateInfo({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    if (name != null) this.name = name;
    if (phone != null) this.phone = phone;
    if (email != null) this.email = email;
    if (address != null) this.address = address;
    if (notes != null) this.notes = notes;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'communicationHistory': communicationHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? 'Unknown Customer',
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      communicationHistory: List<String>.from(map['communicationHistory'] ?? []),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name)';
  }
}