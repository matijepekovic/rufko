// lib/widgets/inspection_floating_button.dart

import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import 'package:provider/provider.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../screens/inspection_viewer_screen.dart';

class InspectionFloatingButton extends StatelessWidget {
  final Customer customer;
  const InspectionFloatingButton({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final inspectionDocs = appState.getInspectionDocumentsForCustomer(customer.id);

    if (inspectionDocs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 60),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '${inspectionDocs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          FloatingActionButton.extended(
            onPressed: () => _showInspectionModal(context),
            icon: const Icon(Icons.assignment),
            label: const Text('Inspection'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip:
                'View ${inspectionDocs.length} inspection document${inspectionDocs.length == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }

  void _showInspectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inspection Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Reference while building quote',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close inspection viewer',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InspectionViewerScreen(
                  customer: customer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
