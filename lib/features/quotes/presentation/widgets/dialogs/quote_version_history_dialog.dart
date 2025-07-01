import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../data/models/business/customer.dart';
import '../../controllers/quote_versioning_controller.dart';
import '../../screens/simplified_quote_detail_screen.dart';

/// Dialog for viewing quote version history in a unified timeline
class QuoteVersionHistoryDialog extends StatefulWidget {
  final SimplifiedMultiLevelQuote quote;
  final Customer customer;

  const QuoteVersionHistoryDialog({
    super.key,
    required this.quote,
    required this.customer,
  });

  @override
  State<QuoteVersionHistoryDialog> createState() => _QuoteVersionHistoryDialogState();
}

class _QuoteVersionHistoryDialogState extends State<QuoteVersionHistoryDialog> {
  late QuoteVersioningController _controller;
  final _dateFormat = DateFormat('MMM d, h:mm a');

  @override
  void initState() {
    super.initState();
    _controller = QuoteVersioningController.fromContext(context);
    _controller.setCurrentQuote(widget.quote);
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final parentQuoteId = widget.quote.parentQuoteId ?? widget.quote.id;
    await Future.wait([
      _controller.loadVersions(parentQuoteId),
      _controller.loadEditHistory(parentQuoteId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.9).clamp(400.0, 600.0);
    final dialogHeight = (screenSize.height * 0.8).clamp(500.0, 700.0);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _controller.isLoading
                      ? _buildLoadingState()
                      : _controller.lastError != null
                          ? _buildErrorState()
                          : _buildTimeline(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final versionCount = _controller.versions.length;
    final lastUpdate = _controller.versions.isNotEmpty 
        ? _controller.versions.first.updatedAt 
        : widget.quote.updatedAt;
    final timeAgo = _getTimeAgo(lastUpdate);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote History',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$versionCount version${versionCount != 1 ? 's' : ''} • Last updated $timeAgo',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading version history...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading version history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.lastError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_controller.versions.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No version history',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version history will appear here when changes are made',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Create a map of version to edit history for easy lookup
    final Map<int, String> versionEditReasons = {};
    final Map<int, String> versionEditDescriptions = {};
    for (final history in _controller.editHistory) {
      versionEditReasons[history.version] = history.editReason.displayName;
      versionEditDescriptions[history.version] = history.editDescription ?? '';
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _controller.versions.length,
      itemBuilder: (context, index) {
        final version = _controller.versions[index];
        final isCurrentVersion = version.isCurrentVersion;
        final isLast = index == _controller.versions.length - 1;
        
        // Get edit reason for this version
        final editReason = versionEditReasons[version.version] ?? 
            (version.version == 1 ? 'Quote Created' : 'Version Updated');
        final editDescription = versionEditDescriptions[version.version] ?? 
            (version.version == 1 ? 'Initial quote generation' : '');

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrentVersion 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 100,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Card(
                  elevation: isCurrentVersion ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCurrentVersion
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: isCurrentVersion ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: isCurrentVersion ? null : () => _viewVersion(version),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Version header
                        Row(
                          children: [
                            Text(
                              'v${version.version}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCurrentVersion 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (isCurrentVersion) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Text(
                              '• $editReason',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date and description
                        Text(
                          _dateFormat.format(version.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (editDescription.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"$editDescription"',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(version.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getStatusColor(version.status).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Status: ${_getStatusLabel(version.status)}',
                            style: TextStyle(
                              color: _getStatusColor(version.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  void _viewVersion(SimplifiedMultiLevelQuote version) {
    Navigator.of(context).pop(); // Close dialog first
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SimplifiedQuoteDetailScreen(
          quote: version,
          customer: widget.customer,
          isHistoricalVersion: true,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Theme.of(context).colorScheme.secondary;
      case 'sent':
        return Theme.of(context).colorScheme.primary;
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'declined':
        return Theme.of(context).colorScheme.error;
      case 'expired':
        return Colors.orange;
      case 'pdf_generated':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'sent':
        return 'Sent';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
      case 'declined':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'pdf_generated':
        return 'PDF Ready';
      default:
        return status;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}