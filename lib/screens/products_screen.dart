import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state_provider.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'excel_mapping_screen.dart'; // Import the mapping screen
import '../services/excel_service.dart'; // Import ExcelService

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
      builder: (context) => _ProductFormDialog(),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
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
        allowedExtensions: ['xlsx', 'xls'], // Consider adding .csv if supported
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final appState = context.read<AppStateProvider>();
        final excelService = ExcelService(); // Instantiate ExcelService

        appState.setLoading(true, 'Analyzing Excel file...');
        try {
          // Get structure for mapping
          final excelStructure = await excelService.getExcelStructureForMapping(filePath);
          appState.setLoading(false);

          if (!mounted) return;

          // Navigate to the mapping screen
          final importedProductCount = await Navigator.push<int?>(
            context,
            MaterialPageRoute(
              builder: (context) => ExcelMappingScreen(
                filePath: filePath,
                excelInfo: excelStructure, // Pass the whole structure
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
          // If importedProductCount is null, it means the user cancelled or an error handled by mapping screen.

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
    } catch (e) { // Catch errors from FilePicker itself
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

class _ProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  final _skuController = TextEditingController();

  String _selectedCategory = 'materials';
  bool _isActive = true;

  final List<String> _categories = [
    'materials',
    'roofing',
    'gutters',
    'flashing',
    'labor',
    'other'
  ];

  final List<String> _units = [
    'sq',
    'sq ft',
    'lin ft',
    'each',
    'bundle',
    'box',
    'hour',
    'day'
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.unitPrice.toString();
      _unitController.text = widget.product!.unit;
      _skuController.text = widget.product!.sku ?? '';
      _selectedCategory = widget.product!.category;
      _isActive = widget.product!.isActive;
    } else {
      _unitController.text = 'sq ft';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Price *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unit price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _unitController.text.isNotEmpty ? _unitController.text : null,
                  decoration: const InputDecoration(
                    labelText: 'Unit *',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  items: _units.map((unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _unitController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Unit is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.toUpperCase()),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU/Code',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Product is available for quotes'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppStateProvider>();
    final price = double.parse(_priceController.text);

    if (_isEditing) {
      widget.product!.updateInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: price,
        unit: _unitController.text,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
      );
      appState.updateProduct(widget.product!);
    } else {
      final product = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        unitPrice: price,
        unit: _unitController.text,
        category: _selectedCategory,
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        isActive: _isActive,
      );
      appState.addProduct(product);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Product updated' : 'Product added'),
      ),
    );
  }
}

