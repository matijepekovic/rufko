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

class _CreateMultiLevelQuoteScreenState extends State<CreateMultiLevelQuoteScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final Set<String> _selectedLevels = {};
  bool _isLoading = false;

  // Available quote levels with enhanced styling
  final List<Map<String, dynamic>> _quoteLevels = [
    {
      'id': 'good',
      'name': 'Good',
      'subtitle': 'Quality materials, standard installation',
      'color': Colors.blue,
      'icon': Icons.star_border,
      'popular': false,
      'description': 'Reliable quality at an affordable price',
    },
    {
      'id': 'better',
      'name': 'Better',
      'subtitle': 'Premium materials, enhanced warranty',
      'color': Colors.orange,
      'icon': Icons.star_half,
      'popular': true,
      'description': 'Enhanced durability with extended warranty',
    },
    {
      'id': 'best',
      'name': 'Best',
      'subtitle': 'Top-tier materials, comprehensive warranty',
      'color': Colors.green,
      'icon': Icons.star,
      'popular': false,
      'description': 'Premium quality with maximum protection',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Pre-select popular option
    _selectedLevels.add('better');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Multi-Level Quote'),
            Text(
              'for ${widget.customer.name}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.home), text: 'Overview'),
                Tab(icon: Icon(Icons.layers), text: 'Levels'),
                Tab(icon: Icon(Icons.build), text: 'Generate'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLevelsTab(),
          _buildGenerateTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Generating Multi-Level Quote...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a few moments',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Project Overview', Icons.home),
          const SizedBox(height: 24),

          // Customer Info Card
          _buildInfoCard(
            title: 'Customer Information',
            icon: Icons.person,
            color: Colors.blue,
            children: [
              _buildInfoRow('Name', widget.customer.name),
              if (widget.customer.address != null)
                _buildInfoRow('Address', widget.customer.address!),
              if (widget.customer.phone != null)
                _buildInfoRow('Phone', widget.customer.phone!),
              if (widget.customer.email != null)
                _buildInfoRow('Email', widget.customer.email!),
            ],
          ),

          const SizedBox(height: 20),

          // Roof Data Card
          _buildInfoCard(
            title: 'Roof Measurements',
            icon: Icons.roofing,
            color: Colors.green,
            children: [
              _buildInfoRow('Roof Area', '${widget.roofScopeData.roofArea.toStringAsFixed(0)} sq ft'),
              _buildInfoRow('Squares', widget.roofScopeData.numberOfSquares.toStringAsFixed(1)),
              _buildInfoRow('Pitch', widget.roofScopeData.pitch.toStringAsFixed(1)),
              if (widget.roofScopeData.ridgeLength > 0)
                _buildInfoRow('Ridge Length', '${widget.roofScopeData.ridgeLength.toStringAsFixed(0)} ft'),
              if (widget.roofScopeData.valleyLength > 0)
                _buildInfoRow('Valley Length', '${widget.roofScopeData.valleyLength.toStringAsFixed(0)} ft'),
              if (widget.roofScopeData.gutterLength > 0)
                _buildInfoRow('Gutter Length', '${widget.roofScopeData.gutterLength.toStringAsFixed(0)} ft'),
            ],
          ),

          const SizedBox(height: 24),

          // Multi-Level Benefits Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Why Multi-Level Quotes?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBenefitItem(
                  'Increase Sales by 25-40%',
                  'Customers are more likely to choose mid-tier options',
                  Icons.trending_up,
                ),
                _buildBenefitItem(
                  'Professional Presentation',
                  'Show different quality levels side-by-side',
                  Icons.business_center,
                ),
                _buildBenefitItem(
                  'Customer Choice',
                  'Let customers decide what fits their budget',
                  Icons.thumb_up,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Select Quote Levels', Icons.layers),
          const SizedBox(height: 16),
          Text(
            'Choose which pricing tiers to include in your quote. We recommend including at least 2-3 options.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          ...(_quoteLevels.map((level) => _buildLevelSelectionCard(level))),

          if (_selectedLevels.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedLevels.length} level${_selectedLevels.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Generate Quote', Icons.build),
          const SizedBox(height: 24),

          // Quote Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                        Icons.layers,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Multi-Level Quote Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildSummaryItem(
                  'Customer',
                  widget.customer.name,
                  Icons.person,
                ),

                const SizedBox(height: 12),
                _buildSummaryItem(
                  'Quote Levels',
                  _selectedLevels.map((id) =>
                  _quoteLevels.firstWhere((l) => l['id'] == id)['name']
                  ).join(', '),
                  Icons.layers,
                ),

                const SizedBox(height: 12),
                _buildSummaryItem(
                  'Roof Area',
                  '${widget.roofScopeData.roofArea.toStringAsFixed(0)} sq ft (${widget.roofScopeData.numberOfSquares.toStringAsFixed(1)} squares)',
                  Icons.roofing,
                ),

                const SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedLevels.isEmpty ? null : _generateQuote,
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text(
                      'Generate Multi-Level Quote',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Process Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'What Happens Next?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. We\'ll calculate materials based on your roof measurements\n'
                      '2. Different quality products will be assigned to each level\n'
                      '3. Labor costs will be calculated for each tier\n'
                      '4. You\'ll get a professional comparison chart',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelectionCard(Map<String, dynamic> level) {
    final isSelected = _selectedLevels.contains(level['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedLevels.remove(level['id']);
            } else {
              _selectedLevels.add(level['id']);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? level['color'].withOpacity(0.5)
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? level['color'].withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: level['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  level['icon'],
                  color: level['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          level['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: level['color'],
                          ),
                        ),
                        if (level['popular']) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'MOST POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level['subtitle'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level['description'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedLevels.add(level['id']);
                    } else {
                      _selectedLevels.remove(level['id']);
                    }
                  });
                },
                activeColor: level['color'],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _tabController.index == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _getNextAction(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _getNextButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_tabController.index) {
      case 0:
        return 'Select Levels';
      case 1:
        return _selectedLevels.isEmpty ? 'Select Levels First' : 'Review & Generate';
      case 2:
        return 'Generate Quote';
      default:
        return 'Next';
    }
  }

  VoidCallback? _getNextAction() {
    switch (_tabController.index) {
      case 0:
        return () {
          _tabController.animateTo(1);
        };
      case 1:
        return _selectedLevels.isEmpty
            ? null
            : () {
          _tabController.animateTo(2);
        };
      case 2:
        return _selectedLevels.isEmpty ? null : _generateQuote;
      default:
        return null;
    }
  }

  Future<void> _generateQuote() async {
    if (_selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one level'),
          backgroundColor: Colors.orange,
        ),
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
        _selectedLevels.toList(),
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
        SnackBar(
          content: Text('Error creating quote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Enhanced Multi-Level Quote Detail Screen
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

class _MultiLevelQuoteDetailScreenState extends State<MultiLevelQuoteDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort levels by their level number
    final sortedLevels = widget.quote.levels.values.toList()
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quote ${widget.quote.quoteNumber}'),
            Text(
              widget.customer.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit functionality coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.compare), text: 'Compare'),
                Tab(icon: Icon(Icons.list), text: 'Details'),
                Tab(icon: Icon(Icons.share), text: 'Share'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildComparisonTab(sortedLevels),
          _buildDetailsTab(sortedLevels),
          _buildShareTab(sortedLevels),
        ],
      ),
    );
  }

  Widget _buildComparisonTab(List<LevelQuote> levels) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerInfo(),
          const SizedBox(height: 24),
          _buildLevelComparison(levels),
          if (widget.quote.commonItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildCommonItems(),
          ],
          if (widget.quote.addons.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAddOns(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(List<LevelQuote> levels) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Individual level details
          ...levels.map((level) => _buildLevelDetailCard(level)),
        ],
      ),
    );
  }

  Widget _buildShareTab(List<LevelQuote> levels) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Quote',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Share options
          _buildShareOption(
            'Generate PDF',
            'Create a professional PDF to email or print',
            Icons.picture_as_pdf,
            Colors.red,
            _generatePdf,
          ),

          const SizedBox(height: 16),

          _buildShareOption(
            'Send via Email',
            'Email the quote directly to your customer',
            Icons.email,
            Colors.blue,
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email functionality coming soon')),
              );
            },
          ),

          const SizedBox(height: 16),

          _buildShareOption(
            'Share Link',
            'Generate a secure link to share the quote online',
            Icons.link,
            Colors.green,
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link sharing coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.customer.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(widget.quote.status),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.customer.address != null)
            Text(
              widget.customer.address!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Quote #: ${widget.quote.quoteNumber}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Text(
                'Valid Until: ${_formatDate(widget.quote.validUntil)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelComparison(List<LevelQuote> levels) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Compare Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Level comparison cards
          ...levels.map((level) => _buildLevelComparisonCard(level)),
        ],
      ),
    );
  }

  Widget _buildLevelComparisonCard(LevelQuote level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getLevelColor(level.levelNumber).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getLevelColor(level.levelNumber).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getLevelColor(level.levelNumber).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLevelIcon(level.levelNumber),
                      color: _getLevelColor(level.levelNumber),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    level.levelName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(level.levelNumber),
                    ),
                  ),
                ],
              ),
              Text(
                '\${widget.quote.getLevelTotal(level.levelId).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(level.levelNumber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${level.items.length} items included',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDetailCard(LevelQuote level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getLevelColor(level.levelNumber).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getLevelIcon(level.levelNumber),
                  color: _getLevelColor(level.levelNumber),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                level.levelName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(level.levelNumber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items list
          ...level.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '\${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\${widget.quote.getLevelTotal(level.levelId).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(level.levelNumber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommonItems() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Common Items (Included in All Levels)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.quote.commonItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.productName)),
                Text('${item.quantity} ${item.unit}'),
                const SizedBox(width: 16),
                Text('\${item.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
          )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Common Items Subtotal:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\${widget.quote.commonSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddOns() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Optional Add-ons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.quote.addons.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.productName)),
                Text('${item.quantity} ${item.unit}'),
                const SizedBox(width: 16),
                Text('\${item.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShareOption(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
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

  Color _getLevelColor(int levelNumber) {
    switch (levelNumber % 3) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  IconData _getLevelIcon(int levelNumber) {
    switch (levelNumber % 3) {
      case 0:
        return Icons.star_border;
      case 1:
        return Icons.star_half;
      case 2:
        return Icons.star;
      default:
        return Icons.diamond;
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
        SnackBar(
          content: const Text('PDF generated successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // TODO: Open PDF file
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }}
