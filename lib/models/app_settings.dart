// lib/models/app_settings.dart - ENHANCED VERSION

import 'kanban_board.dart';
import 'kanban_stage.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 6)
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

  @HiveField(5)
  late List<String> defaultQuoteLevelNames;

  @HiveField(6)
  double taxRate;

  @HiveField(7)
  String? companyName;

  @HiveField(8)
  String? companyAddress;

  @HiveField(9)
  String? companyPhone;

  @HiveField(10)
  String? companyEmail;

  @HiveField(11)
  String? companyLogoPath;

  // NEW FIELDS for enhanced settings
  @HiveField(12)
  late List<String> discountTypes; // 'percentage', 'fixed_amount', 'voucher'

  @HiveField(13)
  bool allowProductDiscountToggle; // Whether products can be marked as non-discountable

  @HiveField(14)
  double defaultDiscountLimit; // Maximum discount percentage allowed

  // Kanban settings
  @HiveField(15)
  bool useKanbanCustomerView;

  @HiveField(16)
  List<KanbanStage> kanbanStages;

  // Multiple Kanban boards
  @HiveField(17)
  List<KanbanBoard> kanbanBoards;

  // Urgency colouring thresholds in days
  @HiveField(18)
  int yellowThresholdDays;

  @HiveField(19)
  int orangeThresholdDays;

  @HiveField(20)
  int redThresholdDays;

  // Categories required to complete a customer's documentation
  @HiveField(21)
  List<String> requiredMediaCategories;

  // Track last successful automatic backup
  @HiveField(22)
  DateTime? lastBackupDate;

  AppSettings({
    String? id,
    List<String>? productCategories,
    List<String>? productUnits,
    String? defaultUnit,
    List<String>? defaultQuoteLevelNames,
    this.taxRate = 0.0,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companyLogoPath,
    List<String>? discountTypes,
    this.allowProductDiscountToggle = true,
    this.defaultDiscountLimit = 25.0,
    this.useKanbanCustomerView = false,
    List<KanbanStage>? kanbanStages,
    List<KanbanBoard>? kanbanBoards,
    DateTime? updatedAt,
    this.yellowThresholdDays = 3,
    this.orangeThresholdDays = 7,
    this.redThresholdDays = 14,
    List<String>? requiredMediaCategories,
    this.lastBackupDate,
  })  : productCategories = productCategories ?? ['Materials', 'Roofing', 'Gutters', 'Labor', 'Other'],
        productUnits = productUnits ?? ['sq ft', 'lin ft', 'each', 'hour', 'day', 'bundle', 'roll', 'sheet'],
        defaultUnit = defaultUnit ?? 'sq ft',
        defaultQuoteLevelNames = defaultQuoteLevelNames ?? ['Basic', 'Standard', 'Premium'],
        discountTypes = discountTypes ?? ['percentage', 'fixed_amount', 'voucher'],
        kanbanStages = kanbanStages ?? [
          KanbanStage(id: 'lead', name: 'lead', color: Colors.blue.value),
          KanbanStage(id: 'contacted', name: 'contacted', color: Colors.indigo.value),
          KanbanStage(id: 'quoted', name: 'quoted', color: Colors.purple.value),
          KanbanStage(id: 'negotiation', name: 'negotiation', color: Colors.orange.value),
          KanbanStage(id: 'closed', name: 'closed', color: Colors.green.value),
          KanbanStage(id: 'lost', name: 'lost', color: Colors.red.value),
        ],
        kanbanBoards = kanbanBoards ?? [
          KanbanBoard(
            id: 'sales-pipeline',
            name: 'Sales Pipeline',
            stages: kanbanStages ?? const [],
          ),
          KanbanBoard(
            id: 'warranty-service',
            name: 'Warranty/Service',
            stages: const [
              KanbanStage(id: 'requested', name: 'requested', color: Colors.blueAccent),
              KanbanStage(id: 'scheduled', name: 'scheduled', color: Colors.indigo),
              KanbanStage(id: 'in-progress', name: 'in progress', color: Colors.orange),
              KanbanStage(id: 'done', name: 'done', color: Colors.green),
            ],
          ),
          KanbanBoard(
            id: 'post-sale-projects',
            name: 'Post-Sale Projects',
            stages: const [
              KanbanStage(id: 'scheduled', name: 'scheduled', color: Colors.indigo),
              KanbanStage(id: 'in-progress', name: 'in progress', color: Colors.blue),
              KanbanStage(id: 'getting-materials', name: 'getting materials', color: Colors.orange),
              KanbanStage(id: 'work-done', name: 'work done', color: Colors.green),
            ],
          ),
        ],
        requiredMediaCategories = requiredMediaCategories ?? [
          'roofscope_reports',
          'contracts',
          'permits',
          'insurance_docs',
        ],
        updatedAt = updatedAt ?? DateTime.now(),
        lastBackupDate = lastBackupDate {
    this.id = id ?? 'singleton_app_settings';
  }

  // Enhanced methods for managing categories
  void addProductCategory(String category) {
    if (!productCategories.contains(category)) {
      productCategories.add(category);
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateCompanyLogo(String? logoPath) {
    companyLogoPath = logoPath;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void removeProductCategory(String category) {
    if (productCategories.remove(category)) {
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateProductCategories(List<String> categories) {
    productCategories = categories;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Enhanced methods for managing units
  void addProductUnit(String unit) {
    if (!productUnits.contains(unit)) {
      productUnits.add(unit);
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void removeProductUnit(String unit) {
    if (productUnits.remove(unit)) {
      // Don't remove if it's the default unit
      if (defaultUnit == unit && productUnits.isNotEmpty) {
        defaultUnit = productUnits.first;
      }
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateProductUnits(List<String> units) {
    productUnits = units;
    // Ensure default unit is still valid
    if (!units.contains(defaultUnit) && units.isNotEmpty) {
      defaultUnit = units.first;
    }
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void updateDefaultUnit(String unit) {
    if (productUnits.contains(unit)) {
      defaultUnit = unit;
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void updateDefaultQuoteLevelNames(List<String> levels) {
    defaultQuoteLevelNames = levels;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void updateTaxRate(double newTaxRate) {
    taxRate = newTaxRate;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void updateCompanyInfo({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
  }) {
    if (name != null) companyName = name;
    if (address != null) companyAddress = address;
    if (phone != null) companyPhone = phone;
    if (email != null) companyEmail = email;
    if (logoPath != null) companyLogoPath = logoPath;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // NEW: Discount settings
  void updateDiscountSettings({
    List<String>? types,
    bool? allowToggle,
    double? discountLimit,
  }) {
    if (types != null) discountTypes = types;
    if (allowToggle != null) allowProductDiscountToggle = allowToggle;
    if (discountLimit != null) defaultDiscountLimit = discountLimit;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Update urgency colour thresholds
  void updateUrgencyThresholds({int? yellowDays, int? orangeDays, int? redDays}) {
    if (yellowDays != null) yellowThresholdDays = yellowDays;
    if (orangeDays != null) orangeThresholdDays = orangeDays;
    if (redDays != null) redThresholdDays = redDays;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Update backup timestamp
  void updateLastBackupDate(DateTime date) {
    lastBackupDate = date;
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  // Kanban board management
  void addKanbanBoard(KanbanBoard board) {
    kanbanBoards.add(board);
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void renameKanbanBoard(String id, String newName) {
    final board = kanbanBoards.firstWhere(
      (b) => b.id == id,
      orElse: () => KanbanBoard(name: '', stages: const []),
    );
    if (board.name.isNotEmpty) {
      board.name = newName;
      updatedAt = DateTime.now();
      if (isInBox) save();
    }
  }

  void deleteKanbanBoard(String id) {
    kanbanBoards.removeWhere((b) => b.id == id);
    updatedAt = DateTime.now();
    if (isInBox) save();
  }

  void cloneKanbanBoard(String id) {
    final board = kanbanBoards.firstWhere(
      (b) => b.id == id,
      orElse: () => KanbanBoard(name: '', stages: const []),
    );
    if (board.name.isNotEmpty) {
      addKanbanBoard(board.clone());
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productCategories': productCategories,
      'productUnits': productUnits,
      'defaultUnit': defaultUnit,
      'defaultQuoteLevelNames': defaultQuoteLevelNames,
      'taxRate': taxRate,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'companyLogoPath': companyLogoPath,
      'discountTypes': discountTypes,
      'allowProductDiscountToggle': allowProductDiscountToggle,
      'defaultDiscountLimit': defaultDiscountLimit,
      'useKanbanCustomerView': useKanbanCustomerView,
      'kanbanStages': kanbanStages.map((s) => s.toMap()).toList(),
      'kanbanBoards': kanbanBoards.map((b) => b.toMap()).toList(),
      'yellowThresholdDays': yellowThresholdDays,
      'orangeThresholdDays': orangeThresholdDays,
      'redThresholdDays': redThresholdDays,
      'requiredMediaCategories': requiredMediaCategories,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] ?? 'singleton_app_settings',
      productCategories: List<String>.from(map['productCategories'] ?? []),
      productUnits: List<String>.from(map['productUnits'] ?? []),
      defaultUnit: map['defaultUnit'] ?? 'sq ft',
      defaultQuoteLevelNames: List<String>.from(map['defaultQuoteLevelNames'] ?? ['Basic', 'Standard', 'Premium']),
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      companyName: map['companyName'],
      companyAddress: map['companyAddress'],
      companyPhone: map['companyPhone'],
      companyEmail: map['companyEmail'],
      companyLogoPath: map['companyLogoPath'],
      discountTypes: List<String>.from(map['discountTypes'] ?? ['percentage', 'fixed_amount', 'voucher']),
      allowProductDiscountToggle: map['allowProductDiscountToggle'] ?? true,
      defaultDiscountLimit: map['defaultDiscountLimit']?.toDouble() ?? 25.0,
      useKanbanCustomerView: map['useKanbanCustomerView'] ?? false,
      kanbanStages: map['kanbanStages'] != null
          ? (map['kanbanStages'] as List)
              .map((e) => KanbanStage.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [
              KanbanStage(id: 'lead', name: 'lead', color: Colors.blue.value),
              KanbanStage(id: 'contacted', name: 'contacted', color: Colors.indigo.value),
              KanbanStage(id: 'quoted', name: 'quoted', color: Colors.purple.value),
              KanbanStage(id: 'negotiation', name: 'negotiation', color: Colors.orange.value),
              KanbanStage(id: 'closed', name: 'closed', color: Colors.green.value),
              KanbanStage(id: 'lost', name: 'lost', color: Colors.red.value),
            ],
      kanbanBoards: map['kanbanBoards'] != null
          ? (map['kanbanBoards'] as List)
              .map((e) => KanbanBoard.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [
              KanbanBoard(
                id: 'sales-pipeline',
                name: 'Sales Pipeline',
                stages: kanbanStages,
              ),
              KanbanBoard(
                id: 'warranty-service',
                name: 'Warranty/Service',
                stages: const [
                  KanbanStage(id: 'requested', name: 'requested', color: Colors.blueAccent),
                  KanbanStage(id: 'scheduled', name: 'scheduled', color: Colors.indigo),
                  KanbanStage(id: 'in-progress', name: 'in progress', color: Colors.orange),
                  KanbanStage(id: 'done', name: 'done', color: Colors.green),
                ],
              ),
              KanbanBoard(
                id: 'post-sale-projects',
                name: 'Post-Sale Projects',
                stages: const [
                  KanbanStage(id: 'scheduled', name: 'scheduled', color: Colors.indigo),
                  KanbanStage(id: 'in-progress', name: 'in progress', color: Colors.blue),
                  KanbanStage(id: 'getting-materials', name: 'getting materials', color: Colors.orange),
                  KanbanStage(id: 'work-done', name: 'work done', color: Colors.green),
                ],
              ),
          ],
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      yellowThresholdDays: map['yellowThresholdDays'] ?? 3,
      orangeThresholdDays: map['orangeThresholdDays'] ?? 7,
      redThresholdDays: map['redThresholdDays'] ?? 14,
      requiredMediaCategories:
          List<String>.from(map['requiredMediaCategories'] ?? [
        'roofscope_reports',
        'contracts',
        'permits',
        'insurance_docs',
      ]),
      lastBackupDate: map['lastBackupDate'] != null
          ? DateTime.parse(map['lastBackupDate'])
          : null,
    );
  }

  @override
  String toString() {
    return 'AppSettings(id: $id, company: $companyName, categories: ${productCategories.length}, units: ${productUnits.length})';
  }
}