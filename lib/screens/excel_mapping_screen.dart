// lib/screens/excel_mapping_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/excel_service.dart';
// Product model is not directly used here anymore if we simplify the import
// import '../models/product.dart';

class ExcelMappingScreen extends StatefulWidget {
  final String filePath;
  final Map<String, dynamic> excelInfo;
  final List<String> headers;
  // The 'levels' parameter from widget is no longer directly used in the simplified import.
  // It was for the old system's product level definition.
  final List<String> levels; // Keep for constructor for now, but won't be used in _importProducts

  const ExcelMappingScreen({
    Key? key,
    required this.filePath,
    required this.excelInfo,
    required this.headers,
    required this.levels,
  }) : super(key: key);

  @override
  State<ExcelMappingScreen> createState() => _ExcelMappingScreenState();
}

class _ExcelMappingScreenState extends State<ExcelMappingScreen> {
  // The mapping UI state variables are no longer strictly necessary for the simplified import,
  // but we'll keep them for now as the UI build methods still use them.
  // For a true simplification, the UI related to _columnMapping and _levelMapping would be removed.
  final Map<String, String> _columnMapping = {};
  // final Map<String, bool> _isLevelDefiner = {}; // No longer used with new Product model
  // final Map<String, String> _levelMapping = {}; // No longer directly used by ExcelService in simplified version

  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setDefaultMappings(); // This can still try to pre-populate _columnMapping for display
  }

  void _setDefaultMappings() {
    // This logic can remain to provide *suggestions* if you were to rebuild a mapping UI later
    // For the simplified import, it's not strictly used by the ExcelService's auto-detection.
    for (final header in widget.headers) {
      final lowerHeader = header.toLowerCase();
      if (lowerHeader.contains('name') || lowerHeader.contains('product')) _columnMapping[header] = 'name';
      else if (lowerHeader.contains('description')) _columnMapping[header] = 'description';
      else if (lowerHeader.contains('price') && !lowerHeader.contains('level')) _columnMapping[header] = 'unitPrice'; // Changed to unitPrice
      else if (lowerHeader.contains('unit')) _columnMapping[header] = 'unit';
      else if (lowerHeader.contains('category')) _columnMapping[header] = 'category';
      else if (lowerHeader.contains('sku')) _columnMapping[header] = 'sku';
      else if (lowerHeader.contains('addon')) _columnMapping[header] = 'isAddon'; // Added for isAddon
      else if (lowerHeader.contains('level') && lowerHeader.contains('price')) {
        final levelMatch = RegExp(r'level\s*([\w-]+)\s*price', caseSensitive: false).firstMatch(lowerHeader);
        if (levelMatch != null) {
          final levelKey = (levelMatch.group(1) ?? "unknown").trim().toLowerCase();
          _columnMapping[header] = 'levelprice_$levelKey'; // For product.levelPrices
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The UI for column mapping and level definitions can be simplified or removed
    // if we are fully relying on the automatic ExcelService.loadProductsFromExcel.
    // For now, to minimize changes, we keep the UI but the _importProducts action is simplified.
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Excel')), // Simplified title
      body: _processing
          ? _buildProcessingIndicator()
          : SingleChildScrollView( /* ... your existing UI structure ... */
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileInfo(),
            const SizedBox(height: 16),
            const Text(
              'Review Excel Data (Automatic Import)', // Updated Text
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The system will attempt to automatically detect columns for product import. Ensure your Excel file has clear headers like "Name", "Price", "Unit", "Category", "Description", "SKU", "Is Addon", and "Level <level_id> Price".', // Updated help text
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container( /* ... error display ... */ ),

            // The mapping UI is now mostly for display/confirmation if kept,
            // as the simplified import uses auto-detection.
            // You might choose to remove _buildColumnMappings and _buildLevelMappings
            // for a truly simplified screen.
            // For now, keeping them to reduce further changes.
            if (widget.headers.isNotEmpty) ...[
              const Text("Detected Headers (for reference):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.headers.map((header) => Chip(label: Text(header))).toList(),
              ),
              const SizedBox(height: 24),
            ]

            // ..._buildColumnMappings(), // Can be removed if going fully automatic
            // const SizedBox(height: 16),
            // Text('Level Definitions', ... ), // This section is less relevant now
            // ..._buildLevelMappings(), // Can be removed
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar( /* ... your existing bottom bar ... */
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('Cancel')),
            ElevatedButton.icon(onPressed: _importProducts, icon: const Icon(Icons.cloud_upload), label: const Text('Start Import')),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() { /* ... your existing _buildFileInfo ... */ return Card();}
  // List<Widget> _buildColumnMappings() { /* ... your existing _buildColumnMappings ... */ return [];} // Can be simplified/removed
  // Widget _buildLevelMappings() { /* ... your existing _buildLevelMappings ... */ return Card();} // Can be simplified/removed
  Widget _buildProcessingIndicator() { /* ... your existing _buildProcessingIndicator ... */ return Center();}
  // void _showLevelConfigDialog(String level) { /* ... (less relevant for simplified import) ... */ }
  // void _showAddLevelDialog() { /* ... (less relevant for simplified import) ... */ }


  // --- SIMPLIFIED IMPORT METHOD ---
  Future<void> _importProducts() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final excelService = ExcelService();
      // Use the simpler auto-detection method from ExcelService
      final products = await excelService.loadProductsFromExcel(widget.filePath);

      if (products.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'No products found in the Excel file. Please check headers and data.';
        });
        return;
      }

      await context.read<AppStateProvider>().importProducts(products);

      if (mounted) {
        Navigator.pop(context, products.length); // Return count of imported products
      }
    } catch (e) {
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          _processing = false;
          _error = 'Error importing products: ${e.toString()}';
        });
      }
    }
  }
}