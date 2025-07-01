import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/customer/customer_operations_service.dart';
import '../widgets/media_tab_controller.dart';
import '../widgets/dialogs/project_note_dialog.dart';
import 'communication_history_controller.dart';

/// Legacy CustomerActionsController for backward compatibility
/// This maintains the old API while the new clean architecture is being rolled out
@Deprecated('Use CustomerActionsUIController with service layer pattern')
class CustomerActionsControllerLegacy {
  CustomerActionsControllerLegacy({
    required this.context,
    required this.customer,
    required this.navigateToCreateQuoteScreen,
    required this.mediaController,
    required this.showQuickCommunicationOptions,
    required this.onUpdated,
  });

  final BuildContext context;
  final Customer customer;
  final VoidCallback navigateToCreateQuoteScreen;
  final MediaTabController mediaController;
  final VoidCallback showQuickCommunicationOptions;
  final VoidCallback? onUpdated;

  void editCustomer() {
    // Call extracted service with EXACT same logic
    CustomerOperationsService.showEditCustomerDialog(
      context: context,
      customer: customer,
      onCustomerUpdated: onUpdated,
    );
  }

  void showDeleteCustomerConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete ${customer.name}?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.shade200),
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
              // Call extracted service with EXACT same logic
              CustomerOperationsService.performCustomerDeletion(
                context: context,
                customer: customer,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showQuickActions() {
    CustomerOperationsService.showQuickActions(
      context: context,
      customer: customer,
      editCustomer: editCustomer,
      navigateToCreateQuoteScreen: navigateToCreateQuoteScreen,
      showQuickCommunicationOptions: showQuickCommunicationOptions,
      showDeleteCustomerConfirmation: showDeleteCustomerConfirmation,
      showMediaOptions: () => _showMediaOptionsDialog(),
      showAddProjectNoteDialog: _showAddProjectNoteDialog,
      scheduleJob: _scheduleJob,
      goToLocation: _goToLocation,
    );
  }

  void _showAddProjectNoteDialog() {
    final communicationController = CommunicationHistoryController(
      customer: customer,
      context: context,
    );
    
    showDialog(
      context: context,
      builder: (context) => ProjectNoteDialog(
        customer: customer,
        controller: communicationController,
      ),
    );
  }

  void _scheduleJob() {
    // TODO: Implement job scheduling
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule Job - TODO: Implement')),
    );
  }

  void _goToLocation() {
    final displayAddress = customer.fullDisplayAddress;
    
    if (displayAddress.isEmpty || displayAddress == 'No address provided') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No address available for this customer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show the same address dialog as customer card
    _showAddressActionDialog(context, displayAddress);
  }
  
  // Address action dialog - copied from customer card for consistency
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
  
  // Maps functionality - renamed for consistency with customer card
  Future<void> _openAddressInMaps(String address) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Try Google Maps first, then fallback to generic geo scheme
      final encodedAddress = Uri.encodeComponent(address);
      final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        messenger.showSnackBar(
          const SnackBar(content: Text('Maps app opened'), backgroundColor: Colors.green),
        );
        // Log communication after successful maps launch
        await _logCommunication('🗺️ Opened ${customer.name} address in maps');
      } else {
        // Fallback to geo scheme
        final Uri geoUri = Uri.parse('geo:0,0?q=$encodedAddress');
        if (await canLaunchUrl(geoUri)) {
          await launchUrl(geoUri);
          messenger.showSnackBar(
            const SnackBar(content: Text('Maps app opened'), backgroundColor: Colors.green),
          );
          // Log communication after successful maps launch
          await _logCommunication('🗺️ Opened ${customer.name} address in maps');
        } else {
          throw Exception('Cannot open maps on this device');
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error opening maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Clipboard functionality - copied from customer card for consistency
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }
  
  // Media options dialog - shows all three upload options
  void _showMediaOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Multiple Photos'),
              subtitle: const Text('Use camera to take multiple photos'),
              onTap: () {
                Navigator.pop(context);
                mediaController.takeMultiplePhotos();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Upload Photos'),
              subtitle: const Text('Choose multiple photos from gallery'),
              onTap: () {
                Navigator.pop(context);
                mediaController.pickMultipleImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.orange),
              title: const Text('Upload Documents'),
              subtitle: const Text('Select PDF, Word, Excel files'),
              onTap: () {
                Navigator.pop(context);
                mediaController.pickMultipleDocuments();
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
  
  // Automatic Communication Logging (same as customer card)
  Future<void> _logCommunication(String message) async {
    try {
      final appState = context.read<AppStateProvider>();
      
      // Use Customer's built-in addCommunication method
      customer.addCommunication(
        message,
        type: 'note',
      );
      
      // Update through AppState
      appState.updateCustomer(customer);
    } catch (e) {
      // Log error but don't show to user to avoid interrupting workflow
      debugPrint('Failed to log communication: $e');
    }
  }
}