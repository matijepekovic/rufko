// lib/mixins/file_sharing_mixin.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/business/customer.dart';
import '../../utils/helpers/common_utils.dart';
import '../../../app/theme/rufko_theme.dart';

mixin FileSharingMixin<T extends StatefulWidget> on State<T> {
  bool _isSharing = false;

  bool get isSharing => _isSharing;

  // Helper methods - Define these first
  String _getCompanyName() => 'Your Company Name';

  String _getFileTypeFromExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  void _showShareSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('✅ $message'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Main share method for any file
  Future<void> shareFile({
    required File file,
    required String fileName,
    String? description,
    Customer? customer,
    String? fileType,
  }) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      setState(() => _isSharing = false);
      _showUnifiedShareDialog(
        file: file,
        fileName: fileName,
        description: description,
        customer: customer,
        fileType: fileType,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error preparing file for sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSharing = false);
      }
    }
  }

  // Show unified share options dialog
  void _showUnifiedShareDialog({
    required File file,
    required String fileName,
    String? description,
    Customer? customer,
    String? fileType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    getFileIcon(fileType ?? _getFileTypeFromExtension(fileName)),
                    size: 24,
                    color: RufkoTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share File',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          fileName,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // File info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      getFileIcon(fileType ?? _getFileTypeFromExtension(fileName)),
                      size: 40,
                      color: getFileColor(fileType ?? _getFileTypeFromExtension(fileName)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<int>(
                            future: file.length(),
                            builder: (context, snapshot) {
                              return Text(
                                'Size: ${snapshot.hasData ? formatFileSize(snapshot.data!) : 'Calculating...'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              );
                            },
                          ),
                          if (customer != null)
                            Text(
                              'Customer: ${customer.name}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share options
              const Text(
                'Choose sharing method:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Share options grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  final cardHeight = cardWidth * 0.7;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cardWidth / cardHeight,
                    children: [
                      _buildShareOptionCard(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: 'Send via email',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(file, fileName, 'email', description, customer);
                        },
                      ),
                      _buildShareOptionCard(
                        icon: Icons.bluetooth,
                        title: 'Bluetooth',
                        subtitle: 'Share via Bluetooth',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(file, fileName, 'bluetooth', description, customer);
                        },
                      ),
                      _buildShareOptionCard(
                        icon: Icons.folder_open,
                        title: 'Save to Folder',
                        subtitle: 'Choose location',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(file, fileName, 'folder', description, customer);
                        },
                      ),
                      _buildShareOptionCard(
                        icon: Icons.apps,
                        title: 'More Apps',
                        subtitle: 'Other apps',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          _handleShareAction(file, fileName, 'system', description, customer);
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Quick share button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleShareAction(file, fileName, 'quick', description, customer);
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Quick Share (System Default)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RufkoTheme.primaryColor,
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
      ),
    );
  }

  // Build share option card
  Widget _buildShareOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle different share actions
  Future<void> _handleShareAction(
      File file,
      String fileName,
      String action,
      String? description,
      Customer? customer,
      ) async {
    setState(() => _isSharing = true);

    try {
      switch (action) {
        case 'email':
          await _shareViaEmail(file, fileName, description, customer);
          break;
        case 'bluetooth':
          await _shareViaBluetooth(file, fileName, description, customer);
          break;
        case 'folder':
          await _saveToSpecificFolder(file, fileName);
          break;
        case 'system':
          await _shareViaSystemApps(file, fileName, description, customer);
          break;
        case 'quick':
        default:
          await _shareViaQuickShare(file, fileName, description, customer);
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in share action "$action": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  // Share via email
  Future<void> _shareViaEmail(File file, String fileName, String? description, Customer? customer) async {
    try {
      final customerName = customer?.name ?? 'Customer';
      final subject = 'File: $fileName';
      final body = '''
Hello $customerName,

Please find the attached file: $fileName

${description != null && description.isNotEmpty ? 'Description: $description\n' : ''}
${customer != null ? '''
Customer Details:
- Name: ${customer.name}
- Phone: ${customer.phone ?? 'Not provided'}
- Email: ${customer.email ?? 'Not provided'}
''' : ''}

Best regards,
${_getCompanyName()}
      ''';

      await SharePlus.instance.share(
        ShareParams(
          subject: subject,
          text: body,
          files: [XFile(file.path)],
        ),
      );

      _showShareSuccessMessage('Email app opened');
    } catch (e) {
      throw Exception('Failed to open email app: $e');
    }
  }

  // Share via Bluetooth
  Future<void> _shareViaBluetooth(File file, String fileName, String? description, Customer? customer) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'File: $fileName${customer != null ? ' - ${customer.name}' : ''}',
          files: [XFile(file.path, mimeType: getMimeType(fileName))],
        ),
      );

      _showShareSuccessMessage('Bluetooth sharing initiated');
    } catch (e) {
      throw Exception('Failed to share via Bluetooth: $e');
    }
  }

  // Share via system apps
  Future<void> _shareViaSystemApps(File file, String fileName, String? description, Customer? customer) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'File: $fileName${customer != null ? ' - ${customer.name}' : ''}',
          files: [XFile(file.path)],
        ),
      );

      _showShareSuccessMessage('Share menu opened');
    } catch (e) {
      throw Exception('Failed to open share menu: $e');
    }
  }

  // Quick share
  Future<void> _shareViaQuickShare(File file, String fileName, String? description, Customer? customer) async {
    try {
      final customerInfo = customer != null ? '\nCustomer: ${customer.name}' : '';
      final descriptionInfo = description != null && description.isNotEmpty ? '\nDescription: $description' : '';

      await SharePlus.instance.share(
        ShareParams(
          text: 'File: $fileName$customerInfo$descriptionInfo',
          subject: fileName,
          files: [XFile(file.path)],
        ),
      );

      _showShareSuccessMessage('Shared successfully');
    } catch (e) {
      throw Exception('Failed to share: $e');
    }
  }

  // Save to specific folder (simplified version)
  Future<void> _saveToSpecificFolder(File sourceFile, String fileName) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        File targetFile = File('$selectedDirectory/$fileName');
        int counter = 1;

        while (await targetFile.exists()) {
          final baseName = fileName.replaceAll(RegExp(r'\.[^.]*$'), '');
          final extension = fileName.split('.').last;
          final newFileName = '${baseName}_$counter.$extension';
          targetFile = File('$selectedDirectory/$newFileName');
          counter++;
        }

        await sourceFile.copy(targetFile.path);
        _showShareSuccessMessage('File saved to ${targetFile.path}');
      } else {
        _showShareSuccessMessage('Save cancelled');
      }
    } catch (e) {
      throw Exception('Failed to save to folder: $e');
    }
  }
}