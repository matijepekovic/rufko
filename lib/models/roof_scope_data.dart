import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'roof_scope_data.g.dart';

@HiveType(typeId: 2)
class RoofScopeData extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String? sourceFileName;

  // Roof measurements
  @HiveField(3)
  double roofArea; // total square footage

  @HiveField(4)
  double numberOfSquares; // roofing squares (100 sq ft each)

  @HiveField(5)
  double pitch; // roof pitch/slope

  @HiveField(6)
  double valleyLength; // linear feet

  @HiveField(7)
  double hipLength; // linear feet

  @HiveField(8)
  double ridgeLength; // linear feet

  @HiveField(9)
  double perimeterLength; // linear feet

  @HiveField(10)
  double eaveLength; // linear feet

  @HiveField(11)
  double gutterLength; // linear feet

  @HiveField(12)
  int chimneyCount;

  @HiveField(13)
  int skylightCount;

  @HiveField(14)
  double flashingLength; // linear feet

  @HiveField(15)
  Map<String, dynamic> additionalMeasurements;

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
  }) :
        additionalMeasurements = additionalMeasurements ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  // Calculate number of squares from roof area
  void calculateSquares() {
    numberOfSquares = roofArea / 100;
    updatedAt = DateTime.now();
  }

  // Update measurements
  void updateMeasurements({
    double? roofArea,
    double? pitch,
    double? valleyLength,
    double? hipLength,
    double? ridgeLength,
    double? perimeterLength,
    double? eaveLength,
    double? gutterLength,
    int? chimneyCount,
    int? skylightCount,
    double? flashingLength,
  }) {
    if (roofArea != null) {
      this.roofArea = roofArea;
      calculateSquares();
    }
    if (pitch != null) this.pitch = pitch;
    if (valleyLength != null) this.valleyLength = valleyLength;
    if (hipLength != null) this.hipLength = hipLength;
    if (ridgeLength != null) this.ridgeLength = ridgeLength;
    if (perimeterLength != null) this.perimeterLength = perimeterLength;
    if (eaveLength != null) this.eaveLength = eaveLength;
    if (gutterLength != null) this.gutterLength = gutterLength;
    if (chimneyCount != null) this.chimneyCount = chimneyCount;
    if (skylightCount != null) this.skylightCount = skylightCount;
    if (flashingLength != null) this.flashingLength = flashingLength;

    updatedAt = DateTime.now();
    save();
  }

  // Add custom measurement
  void addMeasurement(String key, dynamic value) {
    additionalMeasurements[key] = value;
    updatedAt = DateTime.now();
    save();
  }

  // Get total linear footage for calculations
  double get totalLinearFootage {
    return valleyLength + hipLength + ridgeLength + perimeterLength + eaveLength;
  }

  // Convert to Map for JSON serialization
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

  // Create from Map
  factory RoofScopeData.fromMap(Map<String, dynamic> map) {
    return RoofScopeData(
      id: map['id'],
      customerId: map['customerId'],
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
      chimneyCount: map['chimneyCount'] ?? 0,
      skylightCount: map['skylightCount'] ?? 0,
      flashingLength: map['flashingLength']?.toDouble() ?? 0.0,
      additionalMeasurements: Map<String, dynamic>.from(map['additionalMeasurements'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'RoofScopeData(id: $id, roofArea: ${roofArea}sqft, squares: ${numberOfSquares.toStringAsFixed(1)})';
  }
}