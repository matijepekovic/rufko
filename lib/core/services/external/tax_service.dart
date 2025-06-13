// lib/services/tax_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TaxService {
  static Map<String, dynamic>? _taxDatabase;
  static DateTime? _lastUpdated;

  /// Initialize tax database - load from local storage only
  static Future<void> initializeTaxDatabase() async {
    try {
      await _loadTaxDatabase();
      if (kDebugMode) {
        debugPrint('✅ Tax database loaded with ${_getTotalRecords()} records');
        debugPrint('📅 Last updated: ${_lastUpdated ?? 'Never'}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Tax database not found - user must set up manually');
      _taxDatabase = null;
      _lastUpdated = null;
    }
  }

  /// Load tax database from local storage
  static Future<void> _loadTaxDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tax_database.json');

    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);
      _taxDatabase = data['database'];
      _lastUpdated = DateTime.parse(data['lastUpdated']);
    } else {
      throw Exception('Tax database file not found');
    }
  }

  /// Save tax database to local storage
  static Future<void> _saveTaxDatabase() async {
    if (_taxDatabase == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tax_database.json');

    final data = {
      'database': _taxDatabase,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await file.writeAsString(json.encode(data));
    _lastUpdated = DateTime.now();

    if (kDebugMode) debugPrint('💾 Tax database saved');
  }

  /// Get tax rate by ZIP code (most accurate)
  static double? getTaxRateByZipCode(String? zipCode) {
    if (_taxDatabase == null || zipCode == null || zipCode.isEmpty) {
      return null; // No database or invalid ZIP
    }

    final zipRates = _taxDatabase!['zipCodes'] as Map<String, dynamic>?;
    if (zipRates == null) return null;

    // Try exact ZIP match first
    final rate = zipRates[zipCode];
    if (rate != null) return (rate as num).toDouble();

    return null; // No rate found for this ZIP
  }

  /// Get tax rate by state (less accurate fallback)
  static double? getTaxRateByState(String? stateAbbreviation) {
    if (_taxDatabase == null || stateAbbreviation == null || stateAbbreviation.isEmpty) {
      return null; // No database or invalid state
    }

    final stateRates = _taxDatabase!['states'] as Map<String, dynamic>?;
    if (stateRates == null) return null;

    final upperState = stateAbbreviation.toUpperCase();
    final rate = stateRates[upperState];
    if (rate != null) return (rate as num).toDouble();

    return null; // No rate found for this state
  }

  /// Get tax rate by address - tries ZIP first, then state, then returns null
  static double? getTaxRateByAddress({
    String? city,
    String? stateAbbreviation,
    String? zipCode,
  }) {
    // Try ZIP code first (most accurate)
    if (zipCode != null && zipCode.isNotEmpty) {
      final zipRate = getTaxRateByZipCode(zipCode);
      if (zipRate != null) return zipRate;
    }

    // Fall back to state rate
    if (stateAbbreviation != null && stateAbbreviation.isNotEmpty) {
      final stateRate = getTaxRateByState(stateAbbreviation);
      if (stateRate != null) return stateRate;
    }

    return null; // No rate found - user must enter manually
  }

  /// Check if tax database is available
  static bool get isDatabaseAvailable => _taxDatabase != null;

  /// Get database status description
  static String getDatabaseStatus() {
    if (_taxDatabase == null) {
      return 'No tax database found - rates must be entered manually';
    }

    final totalRecords = _getTotalRecords();
    final lastUpdate = _lastUpdated != null
        ? 'Updated: ${_lastUpdated!.toLocal().toString().split(' ')[0]}'
        : 'Never updated';

    return '$totalRecords tax rates available - $lastUpdate';
  }

  /// Get total number of records in database
  static int _getTotalRecords() {
    if (_taxDatabase == null) return 0;

    int total = 0;
    final zipRates = _taxDatabase!['zipCodes'] as Map<String, dynamic>?;
    final stateRates = _taxDatabase!['states'] as Map<String, dynamic>?;

    if (zipRates != null) total += zipRates.length;
    if (stateRates != null) total += stateRates.length;

    return total;
  }

  /// Manually set tax rate for a ZIP code
  static Future<void> setZipCodeRate(String zipCode, double taxRate) async {
    _taxDatabase ??= {
        'zipCodes': <String, dynamic>{},
        'states': <String, dynamic>{},
      };

    // Ensure zipCodes is the right type
    if (_taxDatabase!['zipCodes'] == null) {
      _taxDatabase!['zipCodes'] = <String, dynamic>{};
    }

    final zipRates = _taxDatabase!['zipCodes'] as Map<String, dynamic>;
    zipRates[zipCode] = taxRate;

    await _saveTaxDatabase();
    if (kDebugMode) debugPrint('✏️ Set tax rate for ZIP $zipCode: ${taxRate.toStringAsFixed(2)}%');
  }

  /// Manually set tax rate for a state
  static Future<void> setStateRate(String stateAbbreviation, double taxRate) async {
    _taxDatabase ??= {
        'zipCodes': <String, dynamic>{},
        'states': <String, dynamic>{},
      };

    // Ensure states is the right type
    if (_taxDatabase!['states'] == null) {
      _taxDatabase!['states'] = <String, dynamic>{};
    }

    final stateRates = _taxDatabase!['states'] as Map<String, dynamic>;
    stateRates[stateAbbreviation.toUpperCase()] = taxRate;

    await _saveTaxDatabase();
    if (kDebugMode) debugPrint('✏️ Set tax rate for state $stateAbbreviation: ${taxRate.toStringAsFixed(2)}%');
  }

  /// Get all ZIP code rates (for settings display)
  static Map<String, double> getAllZipCodeRates() {
    if (_taxDatabase == null) return {};

    final zipRates = _taxDatabase!['zipCodes'] as Map<String, dynamic>?;
    if (zipRates == null) return {};

    return zipRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Get all state rates (for settings display)
  static Map<String, double> getAllStateRates() {
    if (_taxDatabase == null) return {};

    final stateRates = _taxDatabase!['states'] as Map<String, dynamic>?;
    if (stateRates == null) return {};

    return stateRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Clear all tax data
  static Future<void> clearAllRates() async {
    _taxDatabase = {
      'zipCodes': {},
      'states': {},
    };
    await _saveTaxDatabase();
    if (kDebugMode) debugPrint('🗑️ Cleared all tax rates');
  }
}