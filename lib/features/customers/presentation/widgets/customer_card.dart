// lib/widgets/customer_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../../data/models/business/customer.dart';
import '../../../../data/models/media/project_media.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../app/theme/rufko_theme.dart';
import '../../../../core/mixins/business/communication_actions_mixin.dart';
import '../screens/customer_detail_screen.dart';

class CustomerCard extends StatefulWidget {
  final Customer customer;
  final int quoteCount;
  final List<ProjectMedia>? customerMedia;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.quoteCount,
    this.customerMedia,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> with CommunicationActionsMixin {
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final displayAddress = widget.customer.fullDisplayAddress;
    final hasImages = widget.customerMedia?.where((media) => 
      media.fileType.toLowerCase().contains('image')).isNotEmpty ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with customer name and actions menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.customer.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onEdit != null || widget.onDelete != null)
                    _buildActionsMenu(context),
                ],
              ),
              
              // Contact information section
              _buildContactInfo(context),

              // Address section
              if (displayAddress.isNotEmpty && displayAddress != 'No address provided')
                _buildAddressSection(context, displayAddress),

              const SizedBox(height: 16),

              // Stats and media section
              _buildStatsSection(context),

              // Image thumbnails
              if (hasImages) ...[
                const SizedBox(height: 16),
                _buildImageThumbnails(context),
              ],

              const SizedBox(height: 16),

              // Footer with date and communication count
              _buildFooterSection(context, dateFormat),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildContactInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone contact row
        if (widget.customer.phone != null && widget.customer.phone!.isNotEmpty)
          _buildContactRow(
            context,
            icon: Icons.phone,
            text: widget.customer.phone!,
            onTap: () => _showPhoneActionDialog(context),
          ),
        // Email contact row
        if (widget.customer.email != null && widget.customer.email!.isNotEmpty)
          _buildContactRow(
            context,
            icon: Icons.email,
            text: widget.customer.email!,
            onTap: () => _showEmailActionDialog(context),
          ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        margin: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) {
        if (value == 'edit') widget.onEdit?.call();
        if (value == 'delete') widget.onDelete?.call();
      },
      itemBuilder: (context) => [
        if (widget.onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: RufkoTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                const Text('Edit'),
              ],
            ),
          ),
        if (widget.onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 12),
                Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context, String displayAddress) {
    return InkWell(
      onTap: () => _showAddressActionDialog(context, displayAddress),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        margin: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Row(
      children: [
        _buildStatChip(
          context,
          icon: Icons.receipt_long_outlined,
          label: '${widget.quoteCount} Quote${widget.quoteCount == 1 ? "" : "s"}',
          color: RufkoTheme.statusBlue,
          onTap: () => _navigateToCustomerTab(context, 2), // quotes tab
        ),
        if (widget.customer.communicationHistory.isNotEmpty) ...[
          const SizedBox(width: 12),
          _buildStatChip(
            context,
            icon: Icons.chat_bubble_outline,
            label: '${widget.customer.communicationHistory.length}',
            color: RufkoTheme.statusPurple,
            onTap: () => _navigateToCustomerTab(context, 1), // communications tab
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: chip,
      );
    }
    return chip;
  }

  Widget _buildImageThumbnails(BuildContext context) {
    final imageMedia = widget.customerMedia!
        .where((media) => media.fileType.toLowerCase().contains('image'))
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Images',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: RufkoTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageMedia.length + (widget.customerMedia!.length > 2 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == imageMedia.length) {
                // "More" indicator - clickable
                return InkWell(
                  onTap: () => _navigateToCustomerTab(context, 4), // media tab
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.more_horiz,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${widget.customerMedia!.length - 2}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () => _navigateToCustomerTab(context, 4), // media tab
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: RufkoTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageThumbnail(imageMedia[index].filePath, 80),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String filePath, double size) {
    return Image.file(
      File(filePath),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: size * 0.4,
          ),
        );
      },
    );
  }

  Widget _buildFooterSection(BuildContext context, DateFormat dateFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Added ${dateFormat.format(widget.customer.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  // Navigation and Dialog Methods

  void _navigateToCustomerTab(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          customer: widget.customer,
          initialTabIndex: tabIndex,
        ),
      ),
    );
  }

  void _showPhoneActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call ${widget.customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call'),
              subtitle: Text(widget.customer.phone!),
              onTap: () {
                Navigator.pop(context);
                _callCustomer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.blue),
              title: const Text('Text Message'),
              subtitle: Text(widget.customer.phone!),
              onTap: () {
                Navigator.pop(context);
                _textCustomer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Phone'),
              subtitle: Text(widget.customer.phone!),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(widget.customer.phone!, 'Phone number');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEmailActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email ${widget.customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('Send Email'),
              subtitle: Text(widget.customer.email!),
              onTap: () {
                Navigator.pop(context);
                _emailCustomer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Email'),
              subtitle: Text(widget.customer.email!),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(widget.customer.email!, 'Email address');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddressActionDialog(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Address Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text('Open in Maps'),
              subtitle: Text(address),
              onTap: () {
                Navigator.pop(context);
                _openAddressInMaps(address);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Address'),
              subtitle: Text(address),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(address, 'Address');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Communication Actions with Automatic Logging

  Future<void> _callCustomer() async {
    if (widget.customer.phone != null) {
      await makePhoneCall(widget.customer.phone!);
      await _logCommunication('📞 Outbound call to ${widget.customer.name}');
    }
  }

  Future<void> _textCustomer() async {
    if (widget.customer.phone != null) {
      await sendSMS(widget.customer.phone!);
      await _logCommunication('💬 SMS sent to ${widget.customer.name}');
    }
  }

  Future<void> _emailCustomer() async {
    if (widget.customer.email != null) {
      await sendEmail(widget.customer.email!);
      await _logCommunication('📧 Email sent to ${widget.customer.name}');
    }
  }

  Future<void> _openAddressInMaps(String address) async {
    await openMaps(address);
    await _logCommunication('🗺️ Opened ${widget.customer.name} address in maps');
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  // Automatic Communication Logging
  Future<void> _logCommunication(String message) async {
    try {
      final appState = context.read<AppStateProvider>();
      
      // Use Customer's built-in addCommunication method
      widget.customer.addCommunication(
        message,
        type: _getMessageType(message),
      );
      
      // Update through AppState
      appState.updateCustomer(widget.customer);
    } catch (e) {
      // Log error but don't show to user to avoid interrupting workflow
      debugPrint('Failed to log communication: $e');
    }
  }

  String _getMessageType(String message) {
    if (message.contains('📞')) return 'call';
    if (message.contains('📧')) return 'email';
    if (message.contains('💬')) return 'text';
    if (message.contains('🗺️')) return 'note';
    return 'note';
  }
}