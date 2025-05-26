// lib/screens/customer_detail_screen.dart - COMPLETE WITH MEDIA FUNCTIONALITY

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'dart:math' as math;

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingMedia = false;

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
                case 'edit_customer':
                  _editCustomer();
                  break;
                case 'delete_customer':
                  _showDeleteCustomerConfirmation();
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
                value: 'edit_customer',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Customer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_customer',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Customer', style: TextStyle(color: Colors.red)),
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    final currentTab = _tabController.index;

    switch (currentTab) {
      case 1: // Quotes tab
        return FloatingActionButton.extended(
          onPressed: _navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('New Quote'),
          backgroundColor: Theme.of(context).primaryColor,
        );
      case 2: // RoofScope tab
        return FloatingActionButton.extended(
          onPressed: _importRoofScope,
          icon: const Icon(Icons.file_upload),
          label: const Text('Import PDF'),
          backgroundColor: Colors.orange,
        );
      case 3: // Media tab
        return FloatingActionButton.extended(
          onPressed: _showMediaOptions,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add Media'),
          backgroundColor: Colors.teal,
        );
      default:
        return FloatingActionButton.extended(
          onPressed: _navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('New Quote'),
          backgroundColor: Theme.of(context).primaryColor,
        );
    }
  }

  // [Previous tab building methods remain the same until _buildMediaTab()]

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

  // COMPLETE MEDIA TAB IMPLEMENTATION
  Widget _buildMediaTab() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final mediaItems = appState.getProjectMediaForCustomer(widget.customer.id);
        mediaItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (_isProcessingMedia) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing media...'),
              ],
            ),
          );
        }

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
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Upload Document'),
                    ),
                  ],
                )
              ],
            ),
          );
        }

        // Group media by category
        final groupedMedia = <String, List<ProjectMedia>>{};
        for (final media in mediaItems) {
          groupedMedia.putIfAbsent(media.category, () => []).add(media);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMediaStat('Total Files', '${mediaItems.length}', Icons.folder),
                      _buildMediaStat('Images', '${mediaItems.where((m) => m.isImage).length}', Icons.image),
                      _buildMediaStat('Documents', '${mediaItems.where((m) => !m.isImage).length}', Icons.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Media by category
              ...groupedMedia.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getCategoryColor(category).withOpacity(0.3)),
                          ),
                          child: Text(
                            _formatCategoryName(category),
                            style: TextStyle(
                              color: _getCategoryColor(category),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${items.length})',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showCategoryMedia(category, items),
                          icon: const Icon(Icons.fullscreen, size: 16),
                          label: const Text('View All'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: math.min(items.length, 10), // Show max 10 items
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            child: _buildCompactMediaCard(items[index]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCompactMediaCard(ProjectMedia mediaItem) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewMedia(mediaItem),
        onLongPress: () => _showMediaContextMenu(mediaItem),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: mediaItem.isImage
                    ? Stack(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    if (File(mediaItem.filePath).existsSync())
                      Positioned.fill(
                        child: Image.file(
                          File(mediaItem.filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image,
                              size: 32,
                              color: Colors.grey[400],
                            );
                          },
                        ),
                      ),
                  ],
                )
                    : Icon(
                  mediaItem.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.insert_drive_file_outlined,
                  size: 32,
                  color: Colors.grey[400],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaItem.fileName,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mediaItem.formattedFileSize,
                    style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MEDIA FUNCTIONALITY METHODS

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Media',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture with camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: Colors.green.shade700),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.file_upload, color: Colors.orange.shade700),
              ),
              title: const Text('Upload Document'),
              subtitle: const Text('PDF, Word, Excel files'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedMedia(File(image.path), 'image');
      }
    } catch (e) {
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processSelectedMedia(File(image.path), 'image');
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _processSelectedMedia(file, 'document');
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting document: $e');
    }
  }

  Future<void> _processSelectedMedia(File file, String fileType) async {
    setState(() => _isProcessingMedia = true);

    try {
      // Calculate file size
      final fileSize = await file.length();

      // Get file info
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      // Determine file type
      String detectedType = fileType;
      if (fileExtension == '.pdf') {
        detectedType = 'pdf';
      } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(fileExtension)) {
        detectedType = 'image';
      }

      // Show media details dialog
      final ProjectMedia? mediaItem = await showDialog<ProjectMedia>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _MediaDetailsDialog(
          file: file,
          fileName: fileName,
          fileType: detectedType,
          fileSize: fileSize,
          customerId: widget.customer.id,
        ),
      );

      if (mediaItem != null) {
        // Add to app state
        await context.read<AppStateProvider>().addProjectMedia(mediaItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${mediaItem.fileName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error processing media: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingMedia = false);
      }
    }
  }

  Future<void> _viewMedia(ProjectMedia mediaItem) async {
    try {
      if (mediaItem.isImage) {
        // Show full-screen image viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _FullScreenImageViewer(mediaItem: mediaItem),
          ),
        );
      } else {
        // Open with system default app
        final result = await OpenFilex.open(mediaItem.filePath);
        if (result.type != ResultType.done) {
          _showErrorSnackBar('Cannot open file: ${result.message}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error opening media: $e');
    }
  }

  void _showMediaContextMenu(ProjectMedia mediaItem) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                _viewMedia(mediaItem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              onTap: () {
                Navigator.pop(context);
                _editMediaDetails(mediaItem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sharing
                _showErrorSnackBar('Sharing functionality coming soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMedia(mediaItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editMediaDetails(ProjectMedia mediaItem) {
    showDialog(
      context: context,
      builder: (context) => _MediaDetailsDialog.edit(
        mediaItem: mediaItem,
        onSave: (updatedMedia) async {
          await context.read<AppStateProvider>().updateProjectMedia(updatedMedia);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Media details updated'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _deleteMedia(ProjectMedia mediaItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${mediaItem.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete file from device
                final file = File(mediaItem.filePath);
                if (await file.exists()) {
                  await file.delete();
                }

                // Remove from app state
                await context.read<AppStateProvider>().deleteProjectMedia(mediaItem.id);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${mediaItem.fileName}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackBar('Error deleting media: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCategoryMedia(String category, List<ProjectMedia> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryMediaScreen(
          category: category,
          mediaItems: items,
          customerName: widget.customer.name,
        ),
      ),
    );
  }

  // ROOFSCOPE IMPORT IMPLEMENTATION
  Future<void> _importRoofScope() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        setState(() => _isProcessingMedia = true);

        try {
          final appState = context.read<AppStateProvider>();
          final roofScopeData = await appState.extractRoofScopeFromPdf(
            filePath,
            widget.customer.id,
          );

          if (roofScopeData != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('RoofScope data extracted successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Also add the PDF as project media
            final fileName = path.basename(filePath);
            final fileSize = await File(filePath).length();

            final mediaItem = ProjectMedia(
              customerId: widget.customer.id,
              filePath: filePath,
              fileName: fileName,
              fileType: 'pdf',
              category: 'roofscope_reports',
              description: 'RoofScope report with extracted measurements',
              fileSizeBytes: fileSize,
            );

            await appState.addProjectMedia(mediaItem);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not extract RoofScope data from this PDF'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar('Error processing RoofScope PDF: $e');
          }
        } finally {
          if (mounted) {
            setState(() => _isProcessingMedia = false);
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting PDF: $e');
    }
  }

  // HELPER METHODS
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'before_photos':
        return Colors.blue;
      case 'after_photos':
        return Colors.green;
      case 'damage_report':
        return Colors.red;
      case 'progress_photos':
        return Colors.orange;
      case 'roofscope_reports':
        return Colors.purple;
      case 'contracts':
        return Colors.indigo;
      case 'invoices':
        return Colors.teal;
      case 'permits':
        return Colors.brown;
      case 'insurance_docs':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // [Previous helper methods remain the same]
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

  String _formatCommunicationDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  void _editCustomer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomerEditDialog(
        customer: widget.customer,
        onCustomerUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  void _showDeleteCustomerConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete ${widget.customer.name}?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also delete all quotes, RoofScope data, and media associated with this customer.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppStateProvider>().deleteCustomer(widget.customer.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.customer.name} deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                _editCustomer();
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
                _showMediaOptions();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// MEDIA DETAILS DIALOG
class _MediaDetailsDialog extends StatefulWidget {
  final File? file;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String customerId;
  final ProjectMedia? mediaItem;
  final Function(ProjectMedia)? onSave;

  const _MediaDetailsDialog({
    Key? key,
    this.file,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.customerId,
    this.mediaItem,
    this.onSave,
  }) : super(key: key);

  const _MediaDetailsDialog.edit({
    Key? key,
    required ProjectMedia this.mediaItem,
    required Function(ProjectMedia) this.onSave,
  }) : file = null,
        fileName = null,
        fileType = null,
        fileSize = null,
        customerId = '';

  @override
  State<_MediaDetailsDialog> createState() => _MediaDetailsDialogState();
}

class _MediaDetailsDialogState extends State<_MediaDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCategory = 'general';
  List<String> _tags = [];

  final List<String> _categories = [
    'general',
    'before_photos',
    'after_photos',
    'damage_report',
    'progress_photos',
    'roofscope_reports',
    'contracts',
    'invoices',
    'permits',
    'insurance_docs',
  ];

  bool get _isEditing => widget.mediaItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final media = widget.mediaItem!;
      _descriptionController.text = media.description ?? '';
      _selectedCategory = media.category;
      _tags = List.from(media.tags);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.add_photo_alternate,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Media Details' : 'Add Media Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File preview/info
                      if (!_isEditing && widget.file != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: widget.fileType == 'image'
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      widget.file!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.broken_image, color: Colors.grey[400]);
                                      },
                                    ),
                                  )
                                      : Icon(
                                    widget.fileType == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.insert_drive_file,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.fileName ?? 'Unknown file',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        widget.fileSize != null
                                            ? _formatFileSize(widget.fileSize!)
                                            : 'Unknown size',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Category selection
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_formatCategoryName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? 'general';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Description (Optional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Add a description...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Text(
                        'Tags',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.tag),
                                hintText: 'Add a tag and press Enter',
                              ),
                              onFieldSubmitted: _addTag,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _addTag(_tagController.text),
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeTag(tag),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveMedia,
                    child: Text(_isEditing ? 'Update' : 'Add Media'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveMedia() {
    if (_isEditing) {
      // Update existing media
      final updatedMedia = widget.mediaItem!;
      updatedMedia.updateDetails(
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
      );

      widget.onSave?.call(updatedMedia);
      Navigator.pop(context);
    } else {
      // Create new media
      final mediaItem = ProjectMedia(
        customerId: widget.customerId,
        filePath: widget.file!.path,
        fileName: widget.fileName!,
        fileType: widget.fileType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        fileSizeBytes: widget.fileSize,
      );

      Navigator.pop(context, mediaItem);
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// FULL SCREEN IMAGE VIEWER
class _FullScreenImageViewer extends StatelessWidget {
  final ProjectMedia mediaItem;

  const _FullScreenImageViewer({
    Key? key,
    required this.mediaItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        title: Text(
          mediaItem.fileName,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.file(
            File(mediaItem.filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Cannot load image',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// CATEGORY MEDIA SCREEN
class _CategoryMediaScreen extends StatelessWidget {
  final String category;
  final List<ProjectMedia> mediaItems;
  final String customerName;

  const _CategoryMediaScreen({
    Key? key,
    required this.category,
    required this.mediaItems,
    required this.customerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatCategoryName(category)),
            Text(
              '$customerName • ${mediaItems.length} items',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = mediaItems[index];
          return Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // Navigate back to detail screen and view media
                Navigator.pop(context);
                // TODO: Trigger view media
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.grey[200],
                      child: mediaItem.isImage
                          ? Image.file(
                        File(mediaItem.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey[400],
                          );
                        },
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(mediaItem.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          mediaItem.formattedFileSize,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

// CUSTOMER EDIT DIALOG (kept from original)
class _CustomerEditDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onCustomerUpdated;
  const _CustomerEditDialog({
    Key? key,
    required this.customer,
    this.onCustomerUpdated,
  }) : super(key: key);

  @override
  State<_CustomerEditDialog> createState() => _CustomerEditDialogState();
}

class _CustomerEditDialogState extends State<_CustomerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.customer.name;
    _phoneController.text = widget.customer.phone ?? '';
    _emailController.text = widget.customer.email ?? '';
    _addressController.text = widget.customer.address ?? '';
    _notesController.text = widget.customer.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text('Edit Customer', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name*',
                        icon: Icons.person,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                        hint: 'Additional information...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _saveCustomer, child: const Text('Update Customer')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
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
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppStateProvider>();

    widget.customer.updateInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    appState.updateCustomer(widget.customer);

    Navigator.pop(context);
    widget.onCustomerUpdated?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer updated successfully!'), backgroundColor: Colors.green),
    );
  }
}