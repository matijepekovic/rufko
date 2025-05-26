// lib/screens/customer_detail_screen.dart - FIXED

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/roof_scope_data.dart';
import '../models/project_media.dart';
import '../models/simplified_quote.dart';
import '../providers/app_state_provider.dart';

import 'simplified_quote_screen.dart';
import 'simplified_quote_detail_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _communicationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _communicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCustomer,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_quote':
                  _navigateToCreateQuoteScreen();
                  break;
                case 'quick_actions':
                  _showQuickActions();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_quote',
                child: Row(
                  children: [
                    Icon(Icons.add_box, size: 18),
                    SizedBox(width: 8),
                    Text('New Quote'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quick_actions',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Quick Actions'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.description), text: 'Quotes'),
            Tab(icon: Icon(Icons.roofing), text: 'RoofScope'),
            Tab(icon: Icon(Icons.photo_library), text: 'Media'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildSimplifiedQuotesTab(),
          _buildRoofScopeTab(),
          _buildMediaTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateQuoteScreen,
        icon: const Icon(Icons.add),
        label: const Text('New Quote'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Customer since ${DateFormat('MMM yyyy').format(widget.customer.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(Icons.phone_outlined, 'Phone', widget.customer.phone ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email_outlined, 'Email', widget.customer.email ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Address', widget.customer.address ?? 'Not provided'),
                  if (widget.customer.notes != null && widget.customer.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.note_outlined, 'Notes', widget.customer.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Communication History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_comment_outlined),
                        onPressed: _addCommunication,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.customer.communicationHistory.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text('No communication history recorded.'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.customer.communicationHistory.length,
                      itemBuilder: (context, index) {
                        final entry = widget.customer.communicationHistory.reversed.toList()[index];
                        final parts = entry.split(': ');
                        final timestamp = parts.isNotEmpty ? parts[0] : '';
                        final message = parts.length > 1 ? parts.sublist(1).join(': ') : entry;
                        return Card(
                          elevation: 0.5,
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: Colors.blueGrey,
                            ),
                            title: Text(
                              message,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              _formatCommunicationDate(timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedQuotesTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final quotes = appState.getSimplifiedQuotesForCustomer(widget.customer.id);
        quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (quotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No quotes for ${widget.customer.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToCreateQuoteScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Quote'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            double representativeTotal = 0;
            String levelSummary = "${quote.levels.length} level${quote.levels.length == 1 ? "" : "s"}";

            if (quote.levels.isNotEmpty) {
              representativeTotal = quote.getDisplayTotalForLevel(quote.levels.first.id);
            }

            return Card(
              elevation: 1.5,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  'Quote #: ${quote.quoteNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Status: ${quote.status.toUpperCase()} - $levelSummary\nCreated: ${DateFormat('MMM dd, yyyy').format(quote.createdAt)}',
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(representativeTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                onTap: () => _navigateToSimplifiedQuoteDetail(quote),
                isThreeLine: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoofScopeTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final roofScopes = appState.getRoofScopeDataForCustomer(widget.customer.id);
        roofScopes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (roofScopes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.roofing_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No RoofScope data for this customer.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _importRoofScope,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import RoofScope PDF'),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roofScopes.length,
          itemBuilder: (context, index) => _buildRoofScopeCard(roofScopes[index]),
        );
      },
    );
  }

  Widget _buildMediaTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final mediaItems = appState.getProjectMediaForCustomer(widget.customer.id);
        mediaItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mediaItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.perm_media_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No media files for this customer.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addMedia,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add Media'),
                )
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: mediaItems.length,
          itemBuilder: (context, index) => _buildMediaCard(mediaItems[index]),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoofScopeCard(RoofScopeData data) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data.sourceFileName ?? 'RoofScope Report',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(data.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementItem(
                    'Roof Area',
                    '${data.roofArea.toStringAsFixed(1)} sq ft',
                  ),
                ),
                Expanded(
                  child: _buildMeasurementItem(
                    'Squares',
                    data.numberOfSquares.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementItem(
                    'Pitch',
                    data.pitch.toStringAsFixed(1) + "/12",
                  ),
                ),
                Expanded(
                  child: _buildMeasurementItem(
                    'Ridge',
                    '${data.ridgeLength.toStringAsFixed(1)} ft',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(ProjectMedia mediaItem) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped ${mediaItem.fileName}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: mediaItem.isImage
                    ? Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.grey[400],
                )
                    : Icon(
                  mediaItem.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.insert_drive_file_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaItem.fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mediaItem.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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

  String _formatCommunicationDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  void _editCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit customer functionality coming soon')),
    );
  }

  void _addCommunication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Communication Note'),
        content: TextField(
          controller: _communicationController,
          decoration: const InputDecoration(
            hintText: 'Enter communication note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_communicationController.text.isNotEmpty) {
                widget.customer.addCommunication(_communicationController.text);
                context.read<AppStateProvider>().updateCustomer(widget.customer);
                _communicationController.clear();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateQuoteScreen({RoofScopeData? roofScopeData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteScreen(
          customer: widget.customer,
          roofScopeData: roofScopeData,
        ),
      ),
    );
  }

  void _navigateToSimplifiedQuoteDetail(SimplifiedMultiLevelQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimplifiedQuoteDetailScreen(
          quote: quote,
          customer: widget.customer,
        ),
      ),
    );
  }

  void _importRoofScope() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RoofScope import functionality coming soon')),
    );
  }

  void _addMedia() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add media functionality coming soon')),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.green),
              title: const Text('Create New Quote'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateQuoteScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.orange),
              title: const Text('Import RoofScope'),
              onTap: () {
                Navigator.pop(context);
                _importRoofScope();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Add Media'),
              onTap: () {
                Navigator.pop(context);
                _addMedia();
              },
            ),
          ],
        ),
      ),
    );
  }
}