import 'package:flutter/material.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class CustomerImportController {
  CustomerImportController(this.context, this.appState);

  final BuildContext context;
  final AppStateProvider appState;

  void importFromContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contacts import functionality coming soon'),
      ),
    );
  }
}
