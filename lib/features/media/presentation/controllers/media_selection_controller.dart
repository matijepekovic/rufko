import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class MediaSelectionController {
  MediaSelectionController({
    required this.context,
    required this.customer,
    required this.showErrorSnackBar,
    required this.onStateChanged,
  });

  final BuildContext context;
  final Customer customer;
  final void Function(String message) showErrorSnackBar;
  final VoidCallback onStateChanged;

  bool isSelectionMode = false;
  Set<String> selectedMediaIds = <String>{};

  void enterSelectionMode() {
    isSelectionMode = true;
    selectedMediaIds.clear();
    onStateChanged();
  }

  void exitSelectionMode() {
    isSelectionMode = false;
    selectedMediaIds.clear();
    onStateChanged();
  }

  void toggleMediaSelection(String mediaId) {
    if (selectedMediaIds.contains(mediaId)) {
      selectedMediaIds.remove(mediaId);
    } else {
      selectedMediaIds.add(mediaId);
    }
    onStateChanged();
  }

  void selectAllMedia() {
    final appState = context.read<AppStateProvider>();
    final mediaItems = appState.getProjectMediaForCustomer(customer.id);
    if (selectedMediaIds.length == mediaItems.length) {
      selectedMediaIds.clear();
    } else {
      selectedMediaIds = mediaItems.map((m) => m.id).toSet();
    }
    onStateChanged();
  }

  void deleteSelectedMedia() {
    if (selectedMediaIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selectedMediaIds.length} file${selectedMediaIds.length == 1 ? '' : 's'}'),
        content: Text(
          selectedMediaIds.length == 1
              ? 'Are you sure you want to delete this file?'
              : 'Are you sure you want to delete these ${selectedMediaIds.length} files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                final appState = context.read<AppStateProvider>();
                final mediaItems = appState.getProjectMediaForCustomer(customer.id);
                final itemsToDelete = mediaItems.where((m) => selectedMediaIds.contains(m.id)).toList();
                for (final mediaItem in itemsToDelete) {
                  final file = File(mediaItem.filePath);
                  if (await file.exists()) {
                    await file.delete();
                  }
                  await appState.deleteProjectMedia(mediaItem.id);
                }
                exitSelectionMode();
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${itemsToDelete.length} file${itemsToDelete.length == 1 ? '' : 's'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                navigator.pop();
                showErrorSnackBar('Error deleting files: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
