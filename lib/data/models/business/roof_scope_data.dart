// lib/models/roof_scope_data.dart (HIVE ANNOTATIONS REMOVED)

import 'package:uuid/uuid.dart';

class RoofScopeData {
  late String id;
  String customerId; // Link to a customer
  String? sourceFileName; // e.g., name of the PDF it was extracted from

  // Roof measurements
  double roofArea; // total square footage
  double numberOfSquares; // roofing squares (1 sq = 100 sq ft)
  double pitch; // roof pitch/slope (e.g., 6 for 6/12)
  double valleyLength; // linear feet
  double hipLength; // linear feet
  double ridgeLength; // linear feet
  double perimeterLength; // linear feet (total edge)

  double eaveLength; // linear feet
  double gutterLength; // linear feet
  int chimneyCount;
  int skylightCount;
  double flashingLength; // linear feet (for step, counter, etc.)
  Map<String, dynamic> additionalMeasurements; // For any other custom fields
  DateTime createdAt;
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
  }

  void addMeasurement(String key, dynamic value) {
    additionalMeasurements[key] = value;
    updatedAt = DateTime.now();
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