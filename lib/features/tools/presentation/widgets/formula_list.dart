import 'package:flutter/material.dart';
import '../../../../core/models/calculator/custom_formula.dart';
import '../../../../core/services/calculator/formula_service.dart';

class FormulaList extends StatefulWidget {
  final Function(CustomFormula) onFormulaSelected;
  final Function(int) onFormulaDeleted;

  const FormulaList({
    super.key,
    required this.onFormulaSelected,
    required this.onFormulaDeleted,
  });

  @override
  State<FormulaList> createState() => _FormulaListState();
}

class _FormulaListState extends State<FormulaList> {
  final TextEditingController _searchController = TextEditingController();
  final FormulaService _formulaService = FormulaService.instance;
  
  List<CustomFormula> _formulas = [];
  List<CustomFormula> _filteredFormulas = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formulas = await _formulaService.getAllFormulas();
      final categories = await _formulaService.getCategories();
      
      setState(() {
        _formulas = formulas;
        _categories = categories;
        _filterFormulas();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterFormulas();
  }

  void _filterFormulas() {
    List<CustomFormula> filtered = _formulas;

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((formula) {
        return formula.name.toLowerCase().contains(query) ||
               formula.description?.toLowerCase().contains(query) == true ||
               formula.expression.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((formula) {
        return formula.categoryDisplayName == _selectedCategory;
      }).toList();
    }

    // Filter by favorites
    if (_showFavoritesOnly) {
      filtered = filtered.where((formula) => formula.isFavorite).toList();
    }

    setState(() {
      _filteredFormulas = filtered;
    });
  }

  Future<void> _toggleFavorite(CustomFormula formula) async {
    try {
      await _formulaService.toggleFavorite(formula.id!, !formula.isFavorite);
      await _loadData(); // Reload to get updated data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFormula(CustomFormula formula) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Formula'),
        content: Text('Are you sure you want to delete "${formula.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && formula.id != null) {
      widget.onFormulaDeleted(formula.id!);
      await _loadData(); // Reload to get updated data
    }
  }

  Future<void> _duplicateFormula(CustomFormula formula) async {
    try {
      await _formulaService.duplicateFormula(formula.id!);
      await _loadData(); // Reload to get updated data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formula "${formula.name}" duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating formula: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search formulas...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Favorites filter
                    FilterChip(
                      label: const Text('Favorites'),
                      selected: _showFavoritesOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showFavoritesOnly = selected;
                        });
                        _filterFormulas();
                      },
                      avatar: Icon(
                        _showFavoritesOnly ? Icons.star : Icons.star_border,
                        size: 18,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Category filters
                    ..._categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                            });
                            _filterFormulas();
                          },
                        ),
                      );
                    }),
                    
                    // Clear filters
                    if (_selectedCategory != null || _showFavoritesOnly)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _showFavoritesOnly = false;
                          });
                          _filterFormulas();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Formulas list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredFormulas.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredFormulas.length,
                        itemBuilder: (context, index) {
                          final formula = _filteredFormulas[index];
                          return _FormulaCard(
                            formula: formula,
                            onTap: () => widget.onFormulaSelected(formula),
                            onFavoriteToggle: () => _toggleFavorite(formula),
                            onDelete: () => _deleteFormula(formula),
                            onDuplicate: () => _duplicateFormula(formula),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasSearchOrFilter = _searchController.text.isNotEmpty || 
                             _selectedCategory != null || 
                             _showFavoritesOnly;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchOrFilter ? Icons.search_off : Icons.functions,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchOrFilter 
                ? 'No formulas found'
                : 'No formulas created yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchOrFilter
                ? 'Try adjusting your search or filters'
                : 'Create your first formula to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (hasSearchOrFilter) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = null;
                  _showFavoritesOnly = false;
                });
                _filterFormulas();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final CustomFormula formula;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _FormulaCard({
    required this.formula,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Favorite star
                  IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      formula.isFavorite ? Icons.star : Icons.star_border,
                      color: formula.isFavorite 
                          ? Colors.amber 
                          : colorScheme.onSurfaceVariant,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Formula name
                  Expanded(
                    child: Text(
                      formula.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Global badge
                  if (formula.isGlobal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Global',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  
                  // Menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onTap();
                          break;
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      if (!formula.isGlobal) // Can't delete global formulas
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Expression
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  formula.expression,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              
              // Description
              if (formula.description?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    formula.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              
              // Footer info
              Row(
                children: [
                  // Category
                  if (formula.category?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formula.category!,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Variables count
                  if (formula.hasVariables)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.input,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formula.variables.length} var${formula.variables.length == 1 ? '' : 's'}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}