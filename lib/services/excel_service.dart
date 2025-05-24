import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';

class ExcelService {
  // Load products from Excel file with automatic column detection
  Future<List<Product>> loadProductsFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final products = <Product>[];

      // Assume the first sheet contains product data
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        throw Exception('No data found in Excel file');
      }

      // Find header row (usually row 0 or 1)
      Map<String, int> columnMap = {};
      int headerRow = -1;

      for (int row = 0; row < sheet.maxRows && headerRow == -1; row++) {
        final rowData = sheet.row(row);

        // Check if this row contains headers
        for (int col = 0; col < rowData.length; col++) {
          final cell = rowData[col];
          final cellValue = cell == null ? '' :
                           (cell.value == null ? '' : cell.value.toString().toLowerCase());

          if (cellValue.contains('name') || cellValue.contains('product')) {
            headerRow = row;
            break;
          }
        }
      }

      if (headerRow == -1) {
        throw Exception('Could not find header row in Excel file');
      }

      // Map column headers to indices
      final headerRowData = sheet.row(headerRow);
      for (int col = 0; col < headerRowData.length; col++) {
        final cell = headerRowData[col];
        final header = cell == null ? '' :
                      (cell.value == null ? '' : cell.value.toString().toLowerCase());

        if (header.contains('name') || header.contains('product')) {
          columnMap['name'] = col;
        } else if (header.contains('description')) {
          columnMap['description'] = col;
        } else if (header.contains('price') || header.contains('cost')) {
          columnMap['price'] = col;
        } else if (header.contains('unit')) {
          columnMap['unit'] = col;
        } else if (header.contains('category') || header.contains('type')) {
          columnMap['category'] = col;
        } else if (header.contains('sku') || header.contains('code')) {
          columnMap['sku'] = col;
        } else if (header.contains('level')) {
          // Extract level information from headers like "Level 1 Price", "Level Good Price"
          final levelMatch = RegExp(r'level\s+(\w+)').firstMatch(header);
          if (levelMatch != null && levelMatch.groupCount >= 1) {
            final levelName = levelMatch.group(1)!.toLowerCase();
            columnMap['level_$levelName'] = col;
          }
        }
      }

      // Validate required columns
      if (!columnMap.containsKey('name') || !columnMap.containsKey('price')) {
        throw Exception('Excel file must contain Name and Price columns');
      }

      // Process data rows
      for (int row = headerRow + 1; row < sheet.maxRows; row++) {
        final rowData = sheet.row(row);

        // Skip empty rows
        if (rowData.isEmpty || rowData.every((cell) => cell?.value == null)) {
          continue;
        }

        try {
          final name = _getCellValue(rowData, columnMap['name']!);
          final priceStr = _getCellValue(rowData, columnMap['price']!);

          if (name.isEmpty || priceStr.isEmpty) continue;

          // Parse price (handle currency symbols and formatting)
          final price = _parsePrice(priceStr);
          if (price <= 0) continue;

          // Create base product
          final product = Product(
            name: name,
            description: columnMap.containsKey('description')
                ? _getCellValue(rowData, columnMap['description']!)
                : null,
            unitPrice: price,
            unit: columnMap.containsKey('unit')
                ? _getCellValue(rowData, columnMap['unit']!, defaultValue: 'sq ft')
                : 'sq ft',
            category: columnMap.containsKey('category')
                ? _getCellValue(rowData, columnMap['category']!, defaultValue: 'materials')
                : 'materials',
            sku: columnMap.containsKey('sku')
                ? _getCellValue(rowData, columnMap['sku']!)
                : null,
          );

          // Add level-specific prices
          final levelPrices = <String, double>{};
          columnMap.forEach((key, col) {
            if (key.startsWith('level_')) {
              final levelName = key.substring(6); // Remove 'level_' prefix
              final levelPriceStr = _getCellValue(rowData, col);
              if (levelPriceStr.isNotEmpty) {
                final levelPrice = _parsePrice(levelPriceStr);
                if (levelPrice > 0) {
                  levelPrices[levelName] = levelPrice;
                }
              }
            }
          });

          if (levelPrices.isNotEmpty) {
            product.levelPrices = levelPrices;
          }

          products.add(product);
        } catch (e) {
          // Skip invalid rows but continue processing
          print('Skipping row $row: $e');
          continue;
        }
      }

      if (products.isEmpty) {
        throw Exception('No valid products found in Excel file');
      }

      return products;
    } catch (e) {
      print('Error loading products from Excel: $e');
      rethrow;
    }
  }

  // Load products from Excel with custom column mapping
  Future<List<Product>> loadProductsFromExcelWithMapping(
    String filePath, {
    required Map<String, String> columnMapping,
    required Map<String, String> levelMapping,
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final products = <Product>[];

      // Assume the first sheet contains product data
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        throw Exception('No data found in Excel file');
      }

      // Get header row (always assume row 0 for mapping)
      final headerRow = 0;
      final headerRowData = sheet.row(headerRow);

      // Create mapping from Excel headers to column indices
      final Map<String, int> headerIndices = {};
      for (int col = 0; col < headerRowData.length; col++) {
        final cell = headerRowData[col];
        final header = cell == null ? '' :
                     (cell.value == null ? '' : cell.value.toString());

        if (header.isNotEmpty) {
          headerIndices[header] = col;
        }
      }

      // Reverse the mapping for easier access: field type -> column index
      final Map<String, int> fieldColumnMap = {};
      columnMapping.forEach((excelHeader, fieldType) {
        if (headerIndices.containsKey(excelHeader) && fieldType != 'ignore') {
          fieldColumnMap[fieldType] = headerIndices[excelHeader]!;
        }
      });

      // Validate required columns
      if (!fieldColumnMap.containsKey('name') || !fieldColumnMap.containsKey('price')) {
        throw Exception('Mapping must include Name and Price columns');
      }

      // Process data rows
      for (int row = headerRow + 1; row < sheet.maxRows; row++) {
        final rowData = sheet.row(row);

        // Skip empty rows
        if (rowData.isEmpty || rowData.every((cell) => cell?.value == null)) {
          continue;
        }

        try {
          final name = _getCellValue(rowData, fieldColumnMap['name']!);
          final priceStr = _getCellValue(rowData, fieldColumnMap['price']!);

          if (name.isEmpty || priceStr.isEmpty) continue;

          // Parse base price
          final price = _parsePrice(priceStr);
          if (price <= 0) continue;

          // Determine if this is a level-defining product
          bool definesLevel = false;
          String? levelName;
          int? levelNumber;

          // Extract level-specific price information
          final levelPrices = <String, double>{};

          // Add base price as default
          levelPrices['base'] = price;

          // Process level-specific prices
          fieldColumnMap.forEach((field, colIndex) {
            if (field.startsWith('level_price_')) {
              final level = field.substring('level_price_'.length);
              final levelPriceStr = _getCellValue(rowData, colIndex);

              if (levelPriceStr.isNotEmpty) {
                final levelPrice = _parsePrice(levelPriceStr);
                if (levelPrice > 0) {
                  levelPrices[level] = levelPrice;

                  // Check if this defines a level
                  if (levelMapping.containsKey(level)) {
                    try {
                      final levelNum = int.parse(level);
                      definesLevel = true;
                      levelName = levelMapping[level];
                      levelNumber = levelNum;
                    } catch (e) {
                      // Level might not be a number, that's ok
                      definesLevel = true;
                      levelName = levelMapping[level];
                    }
                  }
                }
              }
            }
          });

          // Create product with mapped fields
          final product = Product(
            name: name,
            description: fieldColumnMap.containsKey('description')
                ? _getCellValue(rowData, fieldColumnMap['description']!)
                : null,
            unitPrice: price,
            unit: fieldColumnMap.containsKey('unit')
                ? _getCellValue(rowData, fieldColumnMap['unit']!, defaultValue: 'sq ft')
                : 'sq ft',
            category: fieldColumnMap.containsKey('category')
                ? _getCellValue(rowData, fieldColumnMap['category']!, defaultValue: 'materials')
                : 'materials',
            sku: fieldColumnMap.containsKey('sku')
                ? _getCellValue(rowData, fieldColumnMap['sku']!)
                : null,
            levelPrices: levelPrices,
            definesLevel: definesLevel,
            levelName: levelName,
            levelNumber: levelNumber,
          );

          products.add(product);

        } catch (e) {
          // Skip invalid rows but continue processing
          print('Skipping row $row: $e');
          continue;
        }
      }

      if (products.isEmpty) {
        throw Exception('No valid products found in Excel file after mapping');
      }

      return products;
    } catch (e) {
      print('Error loading products with mapping from Excel: $e');
      rethrow;
    }
  }

  // Get Excel structure information for mapping
  Future<Map<String, dynamic>> getExcelStructureForMapping(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in Excel file');
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      // Extract headers (assume first row)
      final headerRow = sheet.row(0);
      final headers = <String>[];
      final potentialLevels = <String>[];

      for (final cell in headerRow) {
        if (cell?.value != null) {
          final header = cell!.value.toString();
          headers.add(header);

          // Check if this might be a level header
          final lowerHeader = header.toLowerCase();
          if (lowerHeader.contains('level') && lowerHeader.contains('price')) {
            // Try to extract level name/number
            final levelMatch = RegExp(r'level\s+(\w+)').firstMatch(lowerHeader);
            if (levelMatch != null && levelMatch.groupCount >= 1) {
              final levelId = levelMatch.group(1)!;
              if (!potentialLevels.contains(levelId)) {
                potentialLevels.add(levelId);
              }
            }
          }
        }
      }

      return {
        'fileName': file.uri.pathSegments.last,
        'fileSize': bytes.length,
        'sheetCount': excel.tables.length,
        'sheetNames': excel.tables.keys.toList(),
        'rowCount': sheet.maxRows,
        'columnCount': sheet.maxColumns,
        'headers': headers,
        'potentialLevels': potentialLevels,
      };
    } catch (e) {
      print('Error analyzing Excel structure: $e');
      rethrow;
    }
  }

  // Helper method to get cell value
  String _getCellValue(List<Data?> row, int columnIndex, {String defaultValue = ''}) {
    if (columnIndex >= row.length) return defaultValue;

    final cell = row[columnIndex];
    if (cell?.value == null) return defaultValue;

    return cell!.value.toString().trim();
  }

  // Helper method to parse price from string
  double _parsePrice(String priceStr) {
    // Remove currency symbols and whitespace
    String cleaned = priceStr
        .replaceAll(RegExp(r'[\$,\s]'), '')
        .replaceAll(',', '');

    return double.tryParse(cleaned) ?? 0.0;
  }

  // Create Excel template for product import with levels
  Future<String> createMultiLevelProductTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Product Template'];

      // Add headers with examples for multi-level products
      final headers = [
        'Name',
        'Description',
        'Base Price',
        'Unit',
        'Category',
        'SKU',
        'Level 1 Price (Good)',
        'Level 2 Price (Better)',
        'Level 3 Price (Best)',
        'Is Level Definer',
        'Level Name',
      ];

      final examples = [
        'Asphalt Shingles - Premium',
        '30-year architectural shingles',
        '120.00',
        'sq',
        'roofing',
        'ASH-PREM-001',
        '100.00',
        '120.00',
        '140.00',
        'TRUE',
        'Premium',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
            TextCellValue(headers[i]);
      }

      // Add example row
      for (int i = 0; i < examples.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
            TextCellValue(examples[i]);
      }

      // Save template
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'multi_level_product_template.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(excel.encode()!);

      return file.path;
    } catch (e) {
      print('Error creating multi-level product template: $e');
      rethrow;
    }
  }

  // Save products to Excel template
  Future<String> saveProductsToExcel(List<Product> products, {String? filePath}) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Products'];

      // Collect all level names
      final levelNames = <String>{};
      for (final product in products) {
        levelNames.addAll(product.levelPrices.keys);
      }
      levelNames.remove('base'); // Base price has its own column

      // Create list of level names sorted numerically if possible
      final sortedLevelNames = levelNames.toList()
        ..sort((a, b) {
          final aNum = int.tryParse(a);
          final bNum = int.tryParse(b);
          if (aNum != null && bNum != null) {
            return aNum.compareTo(bNum);
          }
          return a.compareTo(b);
        });

      // Add headers
      final headers = ['Name', 'Description', 'Base Price', 'Unit', 'Category', 'SKU', 'Defines Level', 'Level Name'];

      // Add level price headers
      for (final level in sortedLevelNames) {
        headers.add('Level $level Price');
      }

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
            TextCellValue(headers[i]);
      }

      // Add product data
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final row = i + 1;

        // Basic product info
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue(product.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(product.description ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
            DoubleCellValue(product.unitPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
            TextCellValue(product.unit);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
            TextCellValue(product.category);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
            TextCellValue(product.sku ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
            TextCellValue(product.definesLevel ? 'TRUE' : 'FALSE');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
            TextCellValue(product.levelName ?? '');

        // Add level-specific prices
        for (int l = 0; l < sortedLevelNames.length; l++) {
          final level = sortedLevelNames[l];
          final price = product.levelPrices[level];
          if (price != null) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8 + l, rowIndex: row)).value =
                DoubleCellValue(price);
          }
        }
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = filePath ?? 'products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(excel.encode()!);

      return file.path;
    } catch (e) {
      print('Error saving products to Excel: $e');
      rethrow;
    }
  }

  // Validate Excel file structure
  Future<bool> validateExcelStructure(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return false;
      }

      final sheet = excel.tables.values.first;
      if (sheet.maxRows < 2) {
        return false; // Need at least header + 1 data row
      }

      // Check for required columns
      final headerRow = sheet.row(0);
      final headers = headerRow.map((cell) {
        if (cell == null) {
          return '';
        } else if (cell.value == null) {
          return '';
        } else {
          return cell.value.toString().toLowerCase();
        }
      }).toList();

      final hasName = headers.any((h) => h.contains('name') || h.contains('product'));
      final hasPrice = headers.any((h) => h.contains('price') || h.contains('cost'));

      return hasName && hasPrice;
    } catch (e) {
      print('Error validating Excel structure: $e');
      return false;
    }
  }

  // Get Excel file info
  Future<Map<String, dynamic>> getExcelInfo(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheetNames = excel.tables.keys.toList();
      final firstSheet = excel.tables.values.first;

      return {
        'fileName': file.uri.pathSegments.last,
        'fileSize': bytes.length,
        'sheetCount': sheetNames.length,
        'sheetNames': sheetNames,
        'rowCount': firstSheet.maxRows,
        'columnCount': firstSheet.maxColumns,
      };
    } catch (e) {
      print('Error getting Excel info: $e');
      rethrow;
    }
  }
}
