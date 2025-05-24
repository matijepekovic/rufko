import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state_provider.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'excel_mapping_screen.dart';
import '../services/excel_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categoryTabs = ['All', 'Roofing', 'Gutters', 'Flashing', 'Labor', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importFromExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppStateProvider>().loadAllData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categoryTabs.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categoryTabs.map((category) => _buildProductsList(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            onPressed: _importFromExcel,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.file_upload),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddProductDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(String category) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        List<Product> products = appState.products;

        // Filter by category
        if (category != 'All') {
          products = products.where((p) =>
          p.category.toLowerCase() == category.toLowerCase() ||
              (category == 'Other' && !['roofing', 'gutters', 'flashing', 'labor']
                  .contains(p.category.toLowerCase()))
          ).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          products = appState.searchProducts(_searchQuery);
          if (category != 'All') {
            products = products.where((p) =>
            p.category.toLowerCase() == category.toLowerCase() ||
                (category == 'Other' && !['roofing', 'gutters', 'flashing', 'labor']
                    .contains(p.category.toLowerCase()))
            ).toList();
          }
        }

        // Sort by name
        products.sort((a, b) => a.name.compareTo(b.name));

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No ${category.toLowerCase()} products'
                      : 'No products found',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Add products or import from Excel'
                      : 'Try adjusting your search terms',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                if (_searchQuery.isEmpty && category == 'All') ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _importFromExcel,
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Import Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => appState.loadAllData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => _showProductDetails(product),
                onEdit: () => _showEditProductDialog(context, product),
                onDelete: () => _showDeleteConfirmation(context, product),
                onToggleActive: () => _toggleProductStatus(product),
              );
            },
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.description != null) ...[
              Text('Description:', style: Theme.of(context).textTheme.titleSmall),
              Text(product.description!),
              const SizedBox(height: 12),
            ],
            Text('Price:', style: Theme.of(context).textTheme.titleSmall),
            Text('\$${product.unitPrice.toStringAsFixed(2)} per ${product.unit}'),
            const SizedBox(height: 12),
            Text('Category:', style: Theme.of(context).textTheme.titleSmall),
            Text(product.category),
            if (product.sku != null) ...[
              const SizedBox(height: 12),
              Text('SKU:', style: Theme.of(context).textTheme.titleSmall),
              Text(product.sku!),
            ],
            const SizedBox(height: 12),
            Text('Status:', style: Theme.of(context).textTheme.titleSmall),
            Text(product.isActive ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditProductDialog(context, product);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ModernProductFormDialog(),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => _ModernProductFormDialog(product: product),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete ${product.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} deleted'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(Product product) {
    product.updateInfo(isActive: !product.isActive);
    context.read<AppStateProvider>().updateProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ${product.isActive ? 'activated' : 'deactivated'}'),
      ),
    );
  }

  void _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final appState = context.read<AppStateProvider>();
        final excelService = ExcelService();

        appState.setLoading(true, 'Analyzing Excel file...');
        try {
          final excelStructure = await excelService.getExcelStructureForMapping(filePath);
          appState.setLoading(false);

          if (!mounted) return;

          final importedProductCount = await Navigator.push<int?>(
            context,
            MaterialPageRoute(
              builder: (context) => ExcelMappingScreen(
                filePath: filePath,
                excelInfo: excelStructure,
                headers: List<String>.from(excelStructure['headers'] ?? []),
                levels: List<String>.from(excelStructure['potentialLevels'] ?? []),
              ),
            ),
          );

          if (importedProductCount != null && importedProductCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$importedProductCount products imported successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (importedProductCount == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No products were imported. Please check the Excel file and mappings.'),
                backgroundColor: Colors.orange,
              ),
            );
          }

        } catch (e) {
          appState.setLoading(false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error analyzing Excel file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ModernProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ModernProductFormDialog({this.product});

  @override
  State<_ModernProductFormDialog> createState() => _ModernProductFormDialogState();
}

class _ModernProductFormDialogState extends State<_ModernProductFormDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Basic product info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _skuController = TextEditingController();

  String _selectedCategory = 'roofing';
  String _selectedUnit = 'sq ft';
  bool _isActive = true;

  // Multi-level settings
  bool _isMultiLevel = false;
  bool _definesLevel = false;
  final Map<String, double> _levelPrices = {};
  final Map<String, TextEditingController> _levelControllers = {};

  // Predefined levels
  final List<Map<String, dynamic>> _availableLevels = [
    {'id': 'good', 'name': 'Good', 'color': Colors.blue, 'icon': Icons.star_border},
    {'id': 'better', 'name': 'Better', 'color': Colors.orange, 'icon': Icons.star_half},
    {'id': 'best', 'name': 'Best', 'color': Colors.green, 'icon': Icons.star},
    {'id': 'premium', 'name': 'Premium', 'color': Colors.purple, 'icon': Icons.diamond},
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize level controllers
    for (final level in _availableLevels) {
      _levelControllers[level['id']] = TextEditingController();
    }

    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _basePriceController.text = widget.product!.unitPrice.toString();
      _skuController.text = widget.product!.sku ?? '';
      _selectedCategory = widget.product!.category;
      _selectedUnit = widget.product!.unit;
      _isActive = widget.product!.isActive;
      _definesLevel = widget.product!.definesLevel;

      // Check if this is a multi-level product
      if (widget.product!.levelPrices.length > 1) {
        _isMultiLevel = true;
        _levelPrices.addAll(widget.product!.levelPrices);

        // Populate level controllers
        _levelPrices.forEach((levelId, price) {
          if (_levelControllers.containsKey(levelId)) {
            _levelControllers[levelId]!.text = price.toStringAsFixed(2);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _skuController.dispose();

    for (final controller in _levelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Edit Product' : 'Create Product',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'Basic'),
                  Tab(icon: Icon(Icons.layers), text: 'Multi-Level'),
                  Tab(icon: Icon(Icons.preview), text: 'Preview'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildMultiLevelTab(),
                    _buildPreviewTab(),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(_isEditing ? 'Update Product' : 'Create Product'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernTextField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'e.g., Premium Asphalt Shingles',
            icon: Icons.business_center,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Product name is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          _buildModernTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Brief description of the product...',
            icon: Icons.description,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          _buildModernTextField(
            controller: _basePriceController,
            label: 'Base Price',
            hint: '0.00',
            icon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Base price is required';
              }
              final price = double.tryParse(value);
              if (price == null || price < 0) {
                return 'Enter a valid price';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildModernDropdown<String>(
                  value: _selectedCategory,
                  label: 'Category',
                  icon: Icons.category,
                  items: const [
                    'roofing',
                    'materials',
                    'gutters',
                    'flashing',
                    'labor',
                    'other'
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernDropdown<String>(
                  value: _selectedUnit,
                  label: 'Unit',
                  icon: Icons.straighten,
                  items: const [
                    'sq ft',
                    'sq',
                    'lin ft',
                    'each',
                    'bundle',
                    'box',
                    'hour',
                    'day'
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value!;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildModernTextField(
            controller: _skuController,
            label: 'SKU (Optional)',
            hint: 'Product code or SKU',
            icon: Icons.qr_code,
          ),

          const SizedBox(height: 20),

          _buildModernSwitch(
            title: 'Active Product',
            subtitle: 'Product is available for use in quotes',
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLevelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Level Pricing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create different pricing tiers for your product (Good, Better, Best)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          _buildModernSwitch(
            title: 'Enable Multi-Level Pricing',
            subtitle: 'Create different price tiers for this product',
            value: _isMultiLevel,
            onChanged: (value) {
              setState(() {
                _isMultiLevel = value;
                if (!value) {
                  _definesLevel = false;
                  _levelPrices.clear();
                  for (final controller in _levelControllers.values) {
                    controller.clear();
                  }
                }
              });
            },
          ),

          if (_isMultiLevel) ...[
            const SizedBox(height: 20),

            _buildModernSwitch(
              title: 'This Product Defines Quality Levels',
              subtitle: 'Use this product to create quote tiers (e.g., different shingle types)',
              value: _definesLevel,
              onChanged: (value) {
                setState(() {
                  _definesLevel = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Text(
              'Set Pricing for Each Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 12),

            ...(_availableLevels.map((level) => _buildLevelPricingCard(level))),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(_selectedCategory),
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text
                            : 'Product Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedCategory.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _descriptionController.text,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!_isMultiLevel) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Price:'),
                        Text(
                          '\$${_basePriceController.text.isNotEmpty ? _basePriceController.text : "0.00"} / $_selectedUnit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ...(_availableLevels.where((level) =>
                        _levelPrices.containsKey(level['id'])
                    ).map((level) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            level['icon'],
                            color: level['color'],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('${level['name']}:'),
                          const Spacer(),
                          Text(
                            '\$${_levelPrices[level['id']]!.toStringAsFixed(2)} / $_selectedUnit',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: level['color'],
                            ),
                          ),
                        ],
                      ),
                    ))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelPricingCard(Map<String, dynamic> level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _levelPrices.containsKey(level['id'])
              ? level['color'].withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: level['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    level['icon'],
                    color: level['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: level['color'],
                        ),
                      ),
                      Text(
                        'Set price for ${level['name'].toLowerCase()} tier',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _levelPrices.containsKey(level['id']),
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        final basePrice = double.tryParse(_basePriceController.text) ?? 0.0;
                        _levelPrices[level['id']] = basePrice;
                        _levelControllers[level['id']]!.text = basePrice.toStringAsFixed(2);
                      } else {
                        _levelPrices.remove(level['id']);
                        _levelControllers[level['id']]!.clear();
                      }
                    });
                  },
                  activeColor: level['color'],
                ),
              ],
            ),

            if (_levelPrices.containsKey(level['id'])) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _levelControllers[level['id']],
                decoration: InputDecoration(
                  labelText: 'Price per $_selectedUnit',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: level['color'], width: 2),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) {
                    _levelPrices[level['id']] = price;
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildModernDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString().toUpperCase()),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'roofing':
        return Icons.roofing;
      case 'materials':
        return Icons.inventory_2;
      case 'gutters':
        return Icons.water_drop;
      case 'flashing':
        return Icons.flash_on;
      case 'labor':
        return Icons.engineering;
      default:
        return Icons.category;
    }
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    if (_isMultiLevel && _levelPrices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set at least one level price for multi-level products'),
          backgroundColor: Colors.orange,
        ),
      );
      _tabController.animateTo(1);
      return;
    }

    final appState = context.read<AppStateProvider>();
    final price = double.parse(_basePriceController.text);

    // Prepare level prices
    final levelPrices = <String, double>{};
    if (_isMultiLevel) {
      levelPrices.addAll(_levelPrices);
    } else {
      levelPrices['base'] = price;
    }

    if (_isEditing) {
      widget.product!.updateInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: price,
        unit: _selectedUnit,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
        definesLevel: _definesLevel,
        levelPrices: levelPrices,
      );
      appState.updateProduct(widget.product!);
    } else {
      final product = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: price,
        unit: _selectedUnit,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
        definesLevel: _definesLevel,
        levelPrices: levelPrices,
      );
      appState.addProduct(product);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Product updated successfully!' : 'Product created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }}