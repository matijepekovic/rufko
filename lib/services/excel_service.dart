// lib/services/excel_service.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kDebugMode; // For kDebugMode
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';

class ExcelService {
  // Load products from Excel file with automatic column detection
  // This version is simplified and might need more robust header detection
  // or a fixed template for reliability.
  Future<List<Product>> loadProductsFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final products = <Product>[];
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) throw Exception('No data found in Excel file');

      Map<String, int> columnMap = {};
      int headerRow = 0; // Assuming header is in the first row for simplicity

      final headerRowData = sheet.row(headerRow);
      for (int col = 0; col < headerRowData.length; col++) {
        final cell = headerRowData[col];
        final header = (cell?.value?.toString() ?? "").toLowerCase();

        if (header.contains('name') || header.contains('product')) columnMap['name'] = col;
        else if (header.contains('description')) columnMap['description'] = col;
        else if (header.contains('price') && !header.contains('level')) columnMap['unitPrice'] = col; // Base price
        else if (header.contains('unit')) columnMap['unit'] = col;
        else if (header.contains('category')) columnMap['category'] = col;
        else if (header.contains('sku')) columnMap['sku'] = col;
        else if (header.contains('addon') || header.contains('add-on')) columnMap['isAddon'] = col;
        else if (header.contains('level') && header.contains('price')) {
          final levelMatch = RegExp(r'(level\s*[\w-]+)\s*price', caseSensitive: false).firstMatch(header);
          if (levelMatch != null) {
            final levelKey = (levelMatch.group(1) ?? "unknown_level").replaceAll('level', '').trim().toLowerCase();
            columnMap['levelprice_$levelKey'] = col;
          }
        }
      }

      if (!columnMap.containsKey('name') || !columnMap.containsKey('unitPrice')) {
        throw Exception('Excel file must contain Name and (Base) Price columns');
      }

      for (int row = headerRow + 1; row < sheet.maxRows; row++) {
        final rowData = sheet.row(row);
        if (rowData.isEmpty || rowData.every((cell) => cell?.value == null)) continue;

        try {
          final name = _getCellValue(rowData, columnMap['name']!);
          final priceStr = _getCellValue(rowData, columnMap['unitPrice']!);
          if (name.isEmpty || priceStr.isEmpty) continue;
          final price = _parsePrice(priceStr);
          if (price <= 0 && !(priceStr.trim() == '0' || priceStr.trim() == '0.0')) continue; // Allow 0 price

          final levelPrices = <String, double>{};
          columnMap.forEach((key, colIndex) {
            if (key.startsWith('levelprice_')) {
              final levelId = key.substring('levelprice_'.length);
              final levelPriceStr = _getCellValue(rowData, colIndex);
              if (levelPriceStr.isNotEmpty) {
                final levelPrice = _parsePrice(levelPriceStr);
                if (levelPrice >= 0) levelPrices[levelId] = levelPrice;
              }
            }
          });

          final product = Product(
            name: name,
            description: columnMap.containsKey('description') ? _getCellValue(rowData, columnMap['description']!) : null,
            unitPrice: price,
            unit: columnMap.containsKey('unit') ? _getCellValue(rowData, columnMap['unit']!, defaultValue: 'each') : 'each',
            category: columnMap.containsKey('category') ? _getCellValue(rowData, columnMap['category']!, defaultValue: 'materials') : 'materials',
            sku: columnMap.containsKey('sku') ? _getCellValue(rowData, columnMap['sku']!) : null,
            isAddon: columnMap.containsKey('isAddon') ? (_getCellValue(rowData, columnMap['isAddon']!).toLowerCase() == 'true' || _getCellValue(rowData, columnMap['isAddon']!) == '1') : false,
            levelPrices: levelPrices.isNotEmpty ? levelPrices : {'base': price}, // Ensure base price is in levelPrices if others are empty
          );
          products.add(product);
        } catch (e) {
          if (kDebugMode) print('Skipping Excel row $row due to error: $e');
          continue;
        }
      }
      if (products.isEmpty) throw Exception('No valid products found in Excel file');
      return products;
    } catch (e) {
      if (kDebugMode) print('Error loading products from Excel: $e');
      rethrow;
    }
  }

  // Load products from Excel with custom column mapping (Advanced)
  Future<List<Product>> loadProductsFromExcelWithMapping({
    required String filePath,
    required Map<String, String> columnMapping, // excelHeader -> productFieldKey (e.g., "Product Name" -> "name")
    // required Map<String, String> levelMapping, // This was for the old system, might not be needed now or needs redesign
    // Level prices are now directly mapped like 'level_price_basic' -> 'basic_level_price_column_header'
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final products = <Product>[];
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) throw Exception('No data found in Excel file');

      final headerRow = 0; // Assume header is always the first row for mapping
      final headerRowData = sheet.row(headerRow);
      final Map<String, int> headerIndices = {}; // Maps Excel column header (as string) to its column index
      for (int col = 0; col < headerRowData.length; col++) {
        final header = headerRowData[col]?.value?.toString() ?? "";
        if (header.isNotEmpty) headerIndices[header] = col;
      }

      // fieldToColumnIndex: Maps our desired product field key to the actual column index in Excel
      // Example: if columnMapping is {"Product Title": "name"}, and "Product Title" is at col 2, then fieldToColumnIndex["name"] = 2
      final Map<String, int> fieldToColumnIndex = {};
      columnMapping.forEach((excelHeader, productFieldKey) {
        if (headerIndices.containsKey(excelHeader) && productFieldKey != 'ignore') {
          fieldToColumnIndex[productFieldKey] = headerIndices[excelHeader]!;
        }
      });

      if (!fieldToColumnIndex.containsKey('name') || !fieldToColumnIndex.containsKey('unitPrice')) {
        throw Exception('Mapping must include "name" and "unitPrice" fields.');
      }

      for (int r = headerRow + 1; r < sheet.maxRows; r++) {
        final rowData = sheet.row(r);
        if (rowData.isEmpty || rowData.every((cell) => cell?.value == null)) continue;

        try {
          final name = _getCellValue(rowData, fieldToColumnIndex['name']!);
          final priceStr = _getCellValue(rowData, fieldToColumnIndex['unitPrice']!);
          if (name.isEmpty || priceStr.isEmpty) continue;
          final price = _parsePrice(priceStr);
          if (price < 0) continue;


          final levelPrices = <String, double>{};
          // Iterate through the columnMapping provided by the user.
          // If a mapping key starts with 'levelprice_', extract the level ID and the Excel column header.
          // Then use headerIndices to find the actual column index for that level price.
          columnMapping.forEach((excelHeader, productFieldKey) {
            if (productFieldKey.startsWith('levelprice_') && headerIndices.containsKey(excelHeader)) {
              final levelId = productFieldKey.substring('levelprice_'.length);
              final colIndex = headerIndices[excelHeader]!;
              final levelPriceStr = _getCellValue(rowData, colIndex);
              if (levelPriceStr.isNotEmpty) {
                final levelPrice = _parsePrice(levelPriceStr);
                if (levelPrice >= 0) levelPrices[levelId] = levelPrice;
              }
            }
          });
          // Ensure base price is part of levelPrices if specific level prices are defined
          if (levelPrices.isNotEmpty && !levelPrices.containsKey('base')) {
            // It's common to want the mapped 'unitPrice' to be the 'base' level price if using levelPrices
            // Or, you might expect a separate column for 'base_level_price' in the mapping.
            // For simplicity now, if levelPrices are used, unitPrice becomes the 'base' if not otherwise specified.
            levelPrices['base'] = price;
          }


          final product = Product(
            name: name,
            description: fieldToColumnIndex.containsKey('description') ? _getCellValue(rowData, fieldToColumnIndex['description']!) : null,
            unitPrice: price,
            unit: fieldToColumnIndex.containsKey('unit') ? _getCellValue(rowData, fieldToColumnIndex['unit']!, defaultValue: 'each') : 'each',
            category: fieldToColumnIndex.containsKey('category') ? _getCellValue(rowData, fieldToColumnIndex['category']!, defaultValue: 'materials') : 'materials',
            sku: fieldToColumnIndex.containsKey('sku') ? _getCellValue(rowData, fieldToColumnIndex['sku']!) : null,
            isAddon: fieldToColumnIndex.containsKey('isAddon') ? (_getCellValue(rowData, fieldToColumnIndex['isAddon']!).toLowerCase() == 'true' || _getCellValue(rowData, fieldToColumnIndex['isAddon']!) == '1') : false,
            levelPrices: levelPrices.isNotEmpty ? levelPrices : {'base': price},
          );
          products.add(product);
        } catch (e) {
          if (kDebugMode) print('Skipping Excel row $r with mapping due to error: $e');
          continue;
        }
      }
      if (products.isEmpty) throw Exception('No valid products found after mapping');
      return products;

    } catch (e) {
      if (kDebugMode) print('Error in loadProductsFromExcelWithMapping: $e');
      rethrow;
    }
  }


  Future<Map<String, dynamic>> getExcelStructureForMapping(String filePath) async {
    // ... (This method seems largely okay, it extracts headers.
    // The 'potentialLevels' logic might be less relevant now as level prices are tied to products directly)
    // You might adjust it to just return headers and other file info.
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('File not found at $filePath');
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) throw Exception('No sheets found in Excel file');
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      final headerRow = sheet.row(0);
      final headers = headerRow.map((cell) => cell?.value?.toString() ?? "").where((h) => h.isNotEmpty).toList();

      // Simpler: just return headers. The mapping UI will let user assign these to product fields.
      return {
        'fileName': file.uri.pathSegments.last,
        'fileSize': bytes.length,
        'sheetCount': excel.tables.length,
        'sheetNames': excel.tables.keys.toList(),
        'rowCount': sheet.maxRows,
        'columnCount': sheet.maxColumns,
        'headers': headers,
      };
    } catch (e) {
      if (kDebugMode) print('Error analyzing Excel structure: $e');
      rethrow;
    }
  }

  String _getCellValue(List<Data?> row, int columnIndex, {String defaultValue = ''}) {
    if (columnIndex < 0 || columnIndex >= row.length) return defaultValue;
    final cell = row[columnIndex];
    return cell?.value?.toString().trim() ?? defaultValue;
  }

  double _parsePrice(String priceStr) {
    String cleaned = priceStr.replaceAll(RegExp(r'[^\d.]'), ''); // Keep only digits and decimal
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<String> createProductTemplate() async { // Renamed for clarity
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Product_Import_Template'];
      final headers = [
        'Name', 'Description', 'Base Price', 'Unit', 'Category', 'SKU', 'Is Addon (TRUE/FALSE)',
        'Level basic Price', 'Level standard Price', 'Level premium Price' // Example level price columns
      ];
      final examples = [
        'Premium Shingles', 'High-quality 30-year architectural shingles', '150.00', 'sq', 'Roofing Materials', 'SH-PREM-30', 'FALSE',
        '140.00', '150.00', '160.00'
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      }
      for (int i = 0; i < examples.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value = TextCellValue(examples[i]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rufko_product_template.xlsx';
      final file = File('${directory.path}/$fileName');
      final encodedBytes = excel.encode();
      if (encodedBytes == null) throw Exception('Failed to encode Excel data');
      await file.writeAsBytes(encodedBytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) print('Error creating product template: $e');
      rethrow;
    }
  }

  Future<String> saveProductsToExcel(List<Product> products, {String? filePath}) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Products'];
      final Set<String> allLevelKeys = {};
      for (final product in products) {
        allLevelKeys.addAll(product.levelPrices.keys);
      }
      // Standardize common level keys if desired, or just use all unique ones found
      final sortedLevelKeys = allLevelKeys.toList()..sort();


      final headers = ['Name', 'Description', 'Base Price', 'Unit', 'Category', 'SKU', 'Is Addon'];
      for (final levelKey in sortedLevelKeys) {
        headers.add('Level $levelKey Price');
      }

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      }

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final row = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(product.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(product.description ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(product.unitPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(product.unit);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(product.category);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(product.sku ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(product.isAddon ? 'TRUE' : 'FALSE');

        for (int k = 0; k < sortedLevelKeys.length; k++) {
          final levelKey = sortedLevelKeys[k];
          final price = product.levelPrices[levelKey];
          if (price != null) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7 + k, rowIndex: row)).value = DoubleCellValue(price);
          } else {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7 + k, rowIndex: row)).value = TextCellValue(''); // Empty if no price for this level
          }
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = filePath ?? 'exported_products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');
      final encodedBytes = excel.encode();
      if (encodedBytes == null) throw Exception('Failed to encode Excel data');
      await file.writeAsBytes(encodedBytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) print('Error saving products to Excel: $e');
      rethrow;
    }
  }
// ValidateExcelStructure and getExcelInfo can remain similar, mostly for file checks.
}