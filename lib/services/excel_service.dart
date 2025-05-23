import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';

class ExcelService {
  // Load products from Excel file
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
          final cellValue = rowData[col]?.value?.toString()?.toLowerCase() ?? '';

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
        final header = headerRowData[col]?.value?.toString()?.toLowerCase() ?? '';

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

  // Save products to Excel template
  Future<String> saveProductsToExcel(List<Product> products, {String? filePath}) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Products'];

      // Add headers
      final headers = ['Name', 'Description', 'Unit Price', 'Unit', 'Category', 'SKU'];
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
            TextCellValue(headers[i]);
      }

      // Add product data
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final row = i + 1;

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

  // Create Excel template for product import
  Future<String> createProductTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Product Template'];

      // Add headers with examples
      final headers = [
        'Name',
        'Description',
        'Unit Price',
        'Unit',
        'Category',
        'SKU'
      ];

      final examples = [
        'Asphalt Shingles - Premium',
        '30-year architectural shingles',
        '120.00',
        'sq ft',
        'roofing',
        'ASH-PREM-001'
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
      final fileName = 'product_import_template.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(excel.encode()!);

      return file.path;
    } catch (e) {
      print('Error creating product template: $e');
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
      final headers = headerRow.map((cell) =>
      cell?.value?.toString()?.toLowerCase() ?? '').toList();

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