import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/communication/communication_service.dart';

/// Controller handling creation and saving of communication entries.
class CommunicationEntryController {
  CommunicationEntryController({
    required this.context,
    required this.customer,
    this.onCommunicationAdded,
  });

  final BuildContext context;
  final Customer customer;
  final VoidCallback? onCommunicationAdded;

  /// Build the communication message string and save it.
  void saveCommunication({
    required String typeLabel,
    required bool isUrgent,
    required String subject,
    required String content,
  }) async {
    try {
      await CommunicationService.saveCommunicationEntry(
        appState: context.read<AppStateProvider>(),
        customer: customer,
        typeLabel: typeLabel,
        isUrgent: isUrgent,
        subject: subject,
        content: content,
      );
      onCommunicationAdded?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Communication logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving communication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
