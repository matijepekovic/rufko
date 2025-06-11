import 'package:flutter/material.dart';

class CustomerImportController {
  CustomerImportController(this.context);

  final BuildContext context;

  void importFromContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contacts import functionality coming soon'),
      ),
    );
  }
}
