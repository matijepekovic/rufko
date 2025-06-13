// lib/models/roof_scope_data.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part '../../generated/roof_scope_data.g.dart'; // Will be generated

@HiveType(typeId: 2) // Unique Type ID
class RoofScopeData extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId; // Link to a customer

  @HiveField(2)
  String? sourceFileName; // e.g., name of the PDF it was extracted from

  // Roof measurements
  @HiveField(3)
  double roofArea; // total square footage

  @HiveField(4)
  double numberOfSquares; // roofing squares (1 sq = 100 sq ft)

  @HiveField(5)
  double pitch; // roof pitch/slope (e.g., 6 for 6/12)

  @HiveField(6)
  double valleyLength; // linear feet

  @HiveField(7)
  double hipLength; // linear feet

  @HiveField(8)
  double ridgeLength; // linear feet

  @HiveField(9)
  double perimeterLength; // linear feet (total edge)

  @HiveField(10)
  double eaveLength; // linear feet

  @HiveField(11)
  double gutterLength; // linear feet

  @HiveField(12)
  int chimneyCount;

  @HiveField(13)
  int skylightCount;

  @HiveField(14)
  double flashingLength; // linear feet (for step, counter, etc.)

  @HiveField(15)
  Map<String, dynamic> additionalMeasurements; // For any other custom fields

  @HiveField(16)
  DateTime createdAt;

  @HiveField(17)
  DateTime updatedAt;

  RoofScopeData({
    String? id,
    required this.customerId,
    this.sourceFileName,
    this.roofArea = 0.0,
    this.numberOfSquares = 0.0,
    this.pitch = 0.0,
    this.valleyLength = 0.0,
    this.hipLength = 0.0,
    this.ridgeLength = 0.0,
    this.perimeterLength = 0.0,
    this.eaveLength = 0.0,
    this.gutterLength = 0.0,
    this.chimneyCount = 0,
    this.skylightCount = 0,
    this.flashingLength = 0.0,
    Map<String, dynamic>? additionalMeasurements,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : additionalMeasurements = additionalMeasurements ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
    if (roofArea > 0 && numberOfSquares == 0.0) { // Auto-calculate squares if area provided
      calculateSquares();
    }
  }

  void calculateSquares() {
    numberOfSquares = roofArea / 100.0;
  }

  void updateMeasurements({
    double? roofArea,
    double? pitch,
    // ... other fields ...
  }) {
    if (roofArea != null) {
      this.roofArea = roofArea;
      calculateSquares();
    }
    if (pitch != null) this.pitch = pitch;
    // ... update other fields ...
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  void addMeasurement(String key, dynamic value) {
    additionalMeasurements[key] = value;
    updatedAt = DateTime.now();
    if (isInBox) { save(); }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'sourceFileName': sourceFileName,
      'roofArea': roofArea,
      'numberOfSquares': numberOfSquares,
      'pitch': pitch,
      'valleyLength': valleyLength,
      'hipLength': hipLength,
      'ridgeLength': ridgeLength,
      'perimeterLength': perimeterLength,
      'eaveLength': eaveLength,
      'gutterLength': gutterLength,
      'chimneyCount': chimneyCount,
      'skylightCount': skylightCount,
      'flashingLength': flashingLength,
      'additionalMeasurements': additionalMeasurements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RoofScopeData.fromMap(Map<String, dynamic> map) {
    return RoofScopeData(
      id: map['id'],
      customerId: map['customerId'] ?? '',
      sourceFileName: map['sourceFileName'],
      roofArea: map['roofArea']?.toDouble() ?? 0.0,
      numberOfSquares: map['numberOfSquares']?.toDouble() ?? 0.0,
      pitch: map['pitch']?.toDouble() ?? 0.0,
      valleyLength: map['valleyLength']?.toDouble() ?? 0.0,
      hipLength: map['hipLength']?.toDouble() ?? 0.0,
      ridgeLength: map['ridgeLength']?.toDouble() ?? 0.0,
      perimeterLength: map['perimeterLength']?.toDouble() ?? 0.0,
      eaveLength: map['eaveLength']?.toDouble() ?? 0.0,
      gutterLength: map['gutterLength']?.toDouble() ?? 0.0,
      chimneyCount: map['chimneyCount']?.toInt() ?? 0,
      skylightCount: map['skylightCount']?.toInt() ?? 0,
      flashingLength: map['flashingLength']?.toDouble() ?? 0.0,
      additionalMeasurements: Map<String, dynamic>.from(map['additionalMeasurements'] ?? {}),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RoofScopeData(id: $id, roofArea: ${roofArea.toStringAsFixed(1)} sqft, squares: ${numberOfSquares.toStringAsFixed(1)})';
  }
}