import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/roof_scope_data.dart';
import '../models/multi_level_quote.dart';
import '../models/product.dart';
import '../providers/app_state_provider.dart';

class CreateMultiLevelQuoteScreen extends StatefulWidget {
  final Customer customer;
  final RoofScopeData roofScopeData;

  const CreateMultiLevelQuoteScreen({
    Key? key,
    required this.customer,
    required this.roofScopeData,
  }) : super(key: key);

  @override
  State<CreateMultiLevelQuoteScreen> createState() => _CreateMultiLevelQuoteScreenState();
}

class _CreateMultiLevelQuoteScreenState extends State<CreateMultiLevelQuoteScreen> {
  final List<String> _selectedLevelIds = [];
  final Map<String, bool> _selectedProducts = {};
  bool _isLoading = false;

  // Products categorized by level
  late List<Product> _levelDefiningProducts;
  late List<Product> _commonProducts;
  late List<Product> _addOnProducts;
  late List<Product> _upgradeProducts;

  // Available levels based on products with definesLevel=true
  final Map<String, String> _availableLevels = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final products = Provider.of<AppStateProvider>(context, listen: false).products;

    // Filter products by type
    _levelDefiningProducts = products.where((p) => p.definesLevel && p.levelName != null).toList();
    _commonProducts = products.where((p) => !p.definesLevel && !p.isUpgrade && !p.isAddon).toList();
    _addOnProducts = products.where((p) => p.isAddon).toList();
    _upgradeProducts = products.where((p) => p.isUpgrade).toList();

    // Generate available levels map
    for (final product in _levelDefiningProducts) {
      if (product.levelName != null) {
        final levelId = product.levelName!.toLowerCase();
        _availableLevels[levelId] = product.levelName!;
      }
    }

    // Pre-select levels
    final appSettings = Provider.of<AppStateProvider>(context, listen: false).appSettings;
    if (appSettings != null && appSettings.defaultQuoteLevels.isNotEmpty) {
      for (final level in appSettings.defaultQuoteLevels) {
        final levelId = level.toLowerCase();
        if (_availableLevels.containsKey(levelId)) {
          _selectedLevelIds.add(levelId);
        }
      }
    } else if (_availableLevels.isNotEmpty) {
      // Default to selecting all available levels if no defaults
      _selectedLevelIds.addAll(_availableLevels.keys);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Multi-Level Quote'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerInfo(),
                const SizedBox(height: 24),
                _buildLevelSelection(),
                const SizedBox(height: 24),
                _buildProductsSection(),
                const Spacer(),
                _buildCreateButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.customer.address != null)
              Text(widget.customer.address!),
            const SizedBox(height: 8),
            Text('Roof Area: ${widget.roofScopeData.roofArea.toStringAsFixed(0)} sq ft'),
            Text('Squares: ${widget.roofScopeData.numberOfSquares.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Quote Levels',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Choose which levels to include in this quote:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableLevels.entries.map((entry) {
            final levelId = entry.key;
            final levelName = entry.value;
            final isSelected = _selectedLevelIds.contains(levelId);

            return FilterChip(
              selected: isSelected,
              label: Text(levelName),
              onSelected: (_) {
                setState(() {
                  if (isSelected) {
                    _selectedLevelIds.remove(levelId);
                  } else {
                    _selectedLevelIds.add(levelId);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Products will be automatically added based on roof measurements and selected levels.'),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedLevelIds.isEmpty ? null : _createMultiLevelQuote,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Generate Multi-Level Quote'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _createMultiLevelQuote() async {
    if (_selectedLevelIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one level')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final quote = await appState.createMultiLevelQuoteFromScope(
        widget.customer.id,
        widget.roofScopeData,
        _selectedLevelIds,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Navigate to the quote detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiLevelQuoteDetailScreen(
            quote: quote,
            customer: widget.customer,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating quote: $e')),
      );
    }
  }
}

class MultiLevelQuoteDetailScreen extends StatefulWidget {
  final MultiLevelQuote quote;
  final Customer customer;

  const MultiLevelQuoteDetailScreen({
    Key? key,
    required this.quote,
    required this.customer,
  }) : super(key: key);

  @override
  State<MultiLevelQuoteDetailScreen> createState() => _MultiLevelQuoteDetailScreenState();
}

class _MultiLevelQuoteDetailScreenState extends State<MultiLevelQuoteDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Sort levels by their level number
    final sortedLevels = widget.quote.levels.values.toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text('Quote ${widget.quote.quoteNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfo(),
                  const SizedBox(height: 24),
                  _buildLevelComparison(sortedLevels),
                  const SizedBox(height: 24),
                  if (widget.quote.commonItems.isNotEmpty)
                    _buildCommonItems(),
                  if (widget.quote.addons.isNotEmpty)
                    _buildAddOns(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.customer.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _buildStatusBadge(widget.quote.status),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.customer.address != null)
              Text(widget.customer.address!),
            const SizedBox(height: 8),
            Text('Quote #: ${widget.quote.quoteNumber}'),
            Text('Valid Until: ${_formatDate(widget.quote.validUntil)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'sent':
        color = Colors.blue;
        break;
      case 'accepted':
        color = Colors.green;
        break;
      case 'declined':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLevelComparison(List<LevelQuote> levels) {
    if (levels.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No levels defined in this quote.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compare Levels',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 70,
            columnSpacing: 24,
            columns: [
              const DataColumn(label: Text('Feature')),
              ...levels.map((level) {
                return DataColumn(
                  label: Container(
                    width: 130,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getLevelColor(level.levelNumber).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getLevelColor(level.levelNumber)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          level.levelName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${widget.quote.getLevelTotal(level.levelId).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            color: _getLevelColor(level.levelNumber),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            rows: _buildComparisonRows(levels),
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildComparisonRows(List<LevelQuote> levels) {
    final rows = <DataRow>[];

    // Get union of all product categories used in any level
    final allProducts = <String, Map<String, String>>{};
    for (final level in levels) {
      for (final item in level.items) {
        if (!allProducts.containsKey(item.productId)) {
          allProducts[item.productId] = {};
        }
        allProducts[item.productId]![level.levelId] = '${item.quantity} ${item.unit}';
      }
    }

    // Add rows for each product
    allProducts.forEach((productId, quantities) {
      // Use the first level's item for this product to get details
      LevelQuote? firstLevelWithProduct;
      String? firstLevelId;

      for (final level in levels) {
        final item = level.items.firstWhere(
          (item) => item.productId == productId,
          orElse: () => null!,
        );
        if (item != null) {
          firstLevelWithProduct = level;
          firstLevelId = level.levelId;
          break;
        }
      }

      if (firstLevelWithProduct == null || firstLevelId == null) return;

      final productItem = firstLevelWithProduct.items.firstWhere(
        (item) => item.productId == productId,
      );

      rows.add(
        DataRow(
          cells: [
            DataCell(Text(productItem.productName)),
            ...levels.map((level) {
              final hasProduct = quantities.containsKey(level.levelId);
              return DataCell(
                hasProduct
                    ? Text(quantities[level.levelId]!)
                    : const Text('—', textAlign: TextAlign.center),
              );
            }).toList(),
          ],
        ),
      );
    });

    // Add total row
    rows.add(
      DataRow(
        cells: [
          const DataCell(Text(
            'TOTAL',
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          ...levels.map((level) {
            return DataCell(
              Text(
                '\$${widget.quote.getLevelTotal(level.levelId).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ],
      ),
    );

    return rows;
  }

  Widget _buildCommonItems() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Common Items (Included in All Levels)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.quote.commonItems.length,
              itemBuilder: (context, index) {
                final item = widget.quote.commonItems[index];
                return ListTile(
                  dense: true,
                  title: Text(item.productName),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                );
              },
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: \$${widget.quote.commonSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOns() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optional Add-ons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.quote.addons.length,
              itemBuilder: (context, index) {
                final item = widget.quote.addons[index];
                return ListTile(
                  dense: true,
                  title: Text(item.productName),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int levelNumber) {
    switch (levelNumber % 3) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.orange.shade800;
      default:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final pdfPath = await appState.generateMultiLevelPdfQuote(
        widget.quote,
        widget.customer,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to: $pdfPath')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }
}
