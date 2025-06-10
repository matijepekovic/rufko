import 'package:flutter/material.dart';
// Placeholder map screen. The real implementation requires
// flutter_map and latlong2 packages which are omitted in this
// environment. This screen simply lists customers with coordinates.
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';

class CustomersMapScreen extends StatelessWidget {
  const CustomersMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final customers = appState.customers
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers Map')),
      body: customers.isEmpty
          ? const Center(child: Text('No customer locations available'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle:
                      Text('(${customer.latitude}, ${customer.longitude})'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(customer: customer),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

}
