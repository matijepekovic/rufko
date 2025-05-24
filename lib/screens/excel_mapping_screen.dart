import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/excel_service.dart';

class ExcelMappingScreen extends StatefulWidget {
  final String filePath;
  final Map<String, dynamic> excelInfo;
  final List<String> headers;
  final List<String> levels;

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
  final Map<String, String> _columnMapping = {};
  final Map<String, bool> _isLevelDefiner = {};
  final Map<String, String> _levelMapping = {};
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Set default mappings based on header names
    _setDefaultMappings();
  }

  void _setDefaultMappings() {
    for (final header in widget.headers) {
      final lowerHeader = header.toLowerCase();

      if (lowerHeader.contains('name') || lowerHeader.contains('product')) {
        _columnMapping[header] = 'name';
      } else if (lowerHeader.contains('description') || lowerHeader.contains('desc')) {
        _columnMapping[header] = 'description';
      } else if (lowerHeader.contains('price') && !lowerHeader.contains('level')) {
        _columnMapping[header] = 'price';
      } else if (lowerHeader.contains('unit')) {
        _columnMapping[header] = 'unit';
      } else if (lowerHeader.contains('category') || lowerHeader.contains('type')) {
        _columnMapping[header] = 'category';
      } else if (lowerHeader.contains('sku') || lowerHeader.contains('code')) {
        _columnMapping[header] = 'sku';
      } else if (lowerHeader.contains('level') && lowerHeader.contains('price')) {
        // Try to extract level name from the header (e.g., "Level 1 Price" -> "1")
        final levelMatch = RegExp(r'level\s+(\w+)').firstMatch(lowerHeader);
        if (levelMatch != null) {
          final levelName = levelMatch.group(1);
          if (levelName != null) {
            _columnMapping[header] = 'level_price_$levelName';

            // Check if this might be a level-defining product
            if (lowerHeader.contains('primary') || lowerHeader.contains('define')) {
              _isLevelDefiner[header] = true;
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Excel Columns'),
      ),
      body: _processing
        ? _buildProcessingIndicator()
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFileInfo(),
              const SizedBox(height: 16),
              const Text(
                'Map Excel Columns to Product Fields',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select which product field each Excel column should be mapped to.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              ..._buildColumnMappings(),

              const SizedBox(height: 16),
              const Text(
                'Level Definitions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure which columns define product levels (e.g., Good, Better, Best).',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              _buildLevelMappings(),
            ],
          ),
        ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _importProducts,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Import Products'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${widget.excelInfo['fileName'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Sheets: ${(widget.excelInfo['sheetNames'] as List?)?.join(', ') ?? 'Unknown'}'),
            Text('Rows: ${widget.excelInfo['rowCount'] ?? 'Unknown'}'),
            Text('Columns: ${widget.excelInfo['columnCount'] ?? 'Unknown'}'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildColumnMappings() {
    return widget.headers.map((header) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excel Column:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      header,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Maps to',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  value: _columnMapping[header],
                  items: [
                    const DropdownMenuItem(value: 'ignore', child: Text('Ignore Column')),
                    const DropdownMenuItem(value: 'name', child: Text('Product Name')),
                    const DropdownMenuItem(value: 'description', child: Text('Description')),
                    const DropdownMenuItem(value: 'price', child: Text('Base Price')),
                    const DropdownMenuItem(value: 'unit', child: Text('Unit (sq ft, etc)')),
                    const DropdownMenuItem(value: 'category', child: Text('Category')),
                    const DropdownMenuItem(value: 'sku', child: Text('SKU/Code')),
                    ...widget.levels.map((level) => DropdownMenuItem(
                      value: 'level_price_$level',
                      child: Text('Price for Level: $level'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _columnMapping[header] = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLevelMappings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Define Product Levels',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Potential level columns
            ...widget.levels.map((level) {
              return ListTile(
                title: Text('Level $level'),
                subtitle: const Text('Configure level name and defining products'),
                trailing: ElevatedButton(
                  onPressed: () => _showLevelConfigDialog(level),
                  child: const Text('Configure'),
                ),
              );
            }).toList(),

            // Add new level button
            if (widget.levels.isNotEmpty)
              const Divider(),

            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add New Level'),
              onTap: _showAddLevelDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing Excel File...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we import your products',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelConfigDialog(String level) {
    final nameController = TextEditingController(text: _levelMapping[level] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Configure Level $level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Level Name (e.g., Good, Better, Best)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _levelMapping[level] = nameController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLevelDialog() {
    final levelController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: levelController,
                decoration: const InputDecoration(
                  labelText: 'Level Number/ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Level Name (e.g., Good, Better, Best)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (levelController.text.isNotEmpty && nameController.text.isNotEmpty) {
                  setState(() {
                    final level = levelController.text;
                    _levelMapping[level] = nameController.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importProducts() async {
    // Validate that name and price are mapped
    if (!_columnMapping.values.contains('name') || !_columnMapping.values.contains('price')) {
      setState(() {
        _error = 'Error: You must map columns for "Product Name" and "Base Price" at minimum.';
      });
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final excelService = ExcelService();
      final products = await excelService.loadProductsFromExcelWithMapping(
        widget.filePath,
        columnMapping: _columnMapping,
        levelMapping: _levelMapping,
      );

      if (products.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'No products found in the Excel file after mapping.';
        });
        return;
      }

      await context.read<AppStateProvider>().importProducts(products);

      if (mounted) {
        Navigator.pop(context, products.length);
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Error importing products: $e';
      });
    }
  }
}
