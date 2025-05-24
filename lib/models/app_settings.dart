import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 6) // Ensure this typeId is unique across your models
class AppSettings extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late List<String> productCategories;

  @HiveField(2)
  late List<String> productUnits;

  @HiveField(3)
  late String defaultUnit;

  @HiveField(4)
  late DateTime updatedAt;

  // Example: Add a field for default levels if needed
  @HiveField(5)
  late List<String> defaultQuoteLevels;

  AppSettings({
    String? id,
    List<String>? productCategories,
    List<String>? productUnits,
    String? defaultUnit,
    List<String>? defaultQuoteLevels,
    DateTime? updatedAt,
  }) :
      productCategories = productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Flashing', 'Labor', 'Other'],
      productUnits = productUnits ?? ['sq', 'sq ft', 'lin ft', 'each', 'bundle', 'box', 'hour', 'day'],
      defaultUnit = defaultUnit ?? 'sq ft',
      defaultQuoteLevels = defaultQuoteLevels ?? ['Basic', 'Better', 'Best'], // Default levels
      updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }

  void updateProductCategories(List<String> categories) {
    productCategories = categories;
    updatedAt = DateTime.now();
    save();
  }

  void updateProductUnits(List<String> units) {
    productUnits = units;
    updatedAt = DateTime.now();
    save();
  }

  void updateDefaultUnit(String unit) {
    defaultUnit = unit;
    updatedAt = DateTime.now();
    save();
  }

  void updateDefaultQuoteLevels(List<String> levels) {
    defaultQuoteLevels = levels;
    updatedAt = DateTime.now();
    save();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productCategories': productCategories,
      'productUnits': productUnits,
      'defaultUnit': defaultUnit,
      'defaultQuoteLevels': defaultQuoteLevels,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      productCategories: List<String>.from(map['productCategories'] ?? []),
      productUnits: List<String>.from(map['productUnits'] ?? []),
      defaultUnit: map['defaultUnit'] ?? 'sq ft',
      defaultQuoteLevels: List<String>.from(map['defaultQuoteLevels'] ?? ['Basic', 'Better', 'Best']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

