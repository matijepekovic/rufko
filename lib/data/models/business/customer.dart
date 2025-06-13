// lib/models/customer.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part '../../generated/customer.g.dart'; // This will need to be regenerated

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

  // OLD @HiveField(4) String? address; // INTENTIONALLY REMOVED for a clean break

  @HiveField(5) // Original index for notes
  String? notes;

  @HiveField(6) // Original index for communicationHistory
  List<String> communicationHistory;

  @HiveField(7) // Original index for createdAt
  DateTime createdAt;

  @HiveField(8) // Original index for updatedAt
  DateTime updatedAt;

  // --- NEW STRUCTURED ADDRESS FIELDS ---
  // Start new fields with the next available indices after the original highest index (8)
  @HiveField(9)
  String? streetAddress;

  @HiveField(10)
  String? city;

  @HiveField(11)
  String? stateAbbreviation; // e.g., "WA", "CA"

  @HiveField(12)
  String? zipCode;

  @HiveField(13) // Next available field number
  Map<String, dynamic> inspectionData;
  // --- END NEW STRUCTURED ADDRESS FIELDS ---

  Customer({
    String? id,
    required this.name,
    this.phone,
    this.email,
    // No 'address' parameter here anymore as the field is removed
    this.notes,
    List<String>? communicationHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    // New address fields
    this.streetAddress,
    this.city,
    this.stateAbbreviation,
    this.zipCode,
    Map<String, dynamic>? inspectionData,
  })  : communicationHistory = communicationHistory ?? [],
        inspectionData = inspectionData ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  String get fullDisplayAddress {
    final parts = [
      streetAddress,
      city,
      (stateAbbreviation != null && stateAbbreviation!.isNotEmpty && zipCode != null && zipCode!.isNotEmpty)
          ? '$stateAbbreviation $zipCode'
          : (stateAbbreviation?.isNotEmpty == true ? stateAbbreviation : (zipCode?.isNotEmpty == true ? zipCode : null)),
    ].where((part) => part != null && part.isNotEmpty).toList();
    if (parts.isEmpty) return 'No address provided';
    return parts.join(', ');
  }

  void addCommunication(String entry, {String type = 'note'}) {
    final timestamp = DateTime.now().toIso8601String();
    final typePrefix = _getTypePrefix(type);
    communicationHistory.add('$timestamp: $typePrefix$entry');
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

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

  void addFollowUp({
    required String content,
    required DateTime followUpDate,
    String priority = 'normal',
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final followUpFormatted = followUpDate.toIso8601String().split('T')[0];
    final priorityFlag = priority == 'high' ? '[HIGH PRIORITY] ' : '';
    communicationHistory.add('$timestamp: 📅 FOLLOW-UP ($followUpFormatted): $priorityFlag$content');
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

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
      case 'call': return '📞 ';
      case 'email': return '📧 ';
      case 'meeting': return '🤝 ';
      case 'site_visit': return '🏠 ';
      case 'text': return '💬 ';
      case 'note': default: return '📝 ';
    }
  }

  List<String> getCommunicationsByType(String type) {
    final prefix = _getTypePrefix(type);
    return communicationHistory.where((comm) => comm.contains(prefix)).toList();
  }

  List<String> getRecentCommunications([int days = 30]) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return communicationHistory.where((comm) {
      try {
        final dateStr = comm.split(': ')[0];
        final commDate = DateTime.parse(dateStr);
        return commDate.isAfter(cutoffDate);
      } catch (e) { return false; }
    }).toList();
  }

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
              (followUpDate.year == today.year &&
                  followUpDate.month == today.month &&
                  followUpDate.day == today.day);
        }
      } catch (e) { /* Silent catch */ }
      return false;
    }).toList();
  }

  Map<String, int> getCommunicationStats() {
    final stats = <String, int>{
      'total': communicationHistory.length,
      'calls': 0, 'emails': 0, 'meetings': 0, 'site_visits': 0, 'notes': 0, 'follow_ups': 0,
    };
    for (final comm in communicationHistory) {
      if (comm.contains('📞')) {
        stats['calls'] = stats['calls']! + 1;
      } else if (comm.contains('📧')) {
        stats['emails'] = stats['emails']! + 1;
      }
// ... (other stats increments)
      else if (comm.contains('📝')) {
        stats['notes'] = stats['notes']! + 1;
      }
      if (comm.contains('📅 FOLLOW-UP')) stats['follow_ups'] = stats['follow_ups']! + 1;
    }
    return stats;
  }

  void updateInfo({
    String? name,
    String? phone,
    String? email,
    String? notes,
    String? streetAddress,
    String? city,
    String? stateAbbreviation,
    String? zipCode,
  }) {
    if (name != null) this.name = name;
    if (phone != null) this.phone = phone;
    if (email != null) this.email = email;
    if (notes != null) this.notes = notes;

    if (streetAddress != null) this.streetAddress = streetAddress.trim().isEmpty ? null : streetAddress.trim();
    if (city != null) this.city = city.trim().isEmpty ? null : city.trim();
    if (stateAbbreviation != null) this.stateAbbreviation = stateAbbreviation.trim().isEmpty ? null : stateAbbreviation.trim();
    if (zipCode != null) this.zipCode = zipCode.trim().isEmpty ? null : zipCode.trim();

    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'communicationHistory': communicationHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'streetAddress': streetAddress,
      'city': city,
      'stateAbbreviation': stateAbbreviation,
      'zipCode': zipCode,
      'inspectionData': inspectionData,
    };

  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? 'Unknown Customer',
      phone: map['phone'],
      email: map['email'],
      notes: map['notes'],
      communicationHistory: List<String>.from(map['communicationHistory'] ?? []),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      streetAddress: map['streetAddress'],
      city: map['city'],
      stateAbbreviation: map['stateAbbreviation'],
      zipCode: map['zipCode'],
      inspectionData: Map<String, dynamic>.from(map['inspectionData'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, address: $fullDisplayAddress)';
  }
  // Methods to get/set inspection values
  void setInspectionValue(String fieldName, dynamic value) {
    inspectionData[fieldName] = value;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  dynamic getInspectionValue(String fieldName) {
    return inspectionData[fieldName];
  }
}