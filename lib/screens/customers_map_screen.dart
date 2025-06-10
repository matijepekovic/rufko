import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';

class CustomersMapScreen extends StatelessWidget {
  const CustomersMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final customers = appState.customers;

    List<Marker> markers = customers
        .where((c) => c.latitude != null && c.longitude != null)
        .map((customer) {
      final color = _urgencyColor(appState, customer);
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(customer.latitude!, customer.longitude!),
        builder: (ctx) => IconButton(
          icon: Icon(Icons.location_on, color: color),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customer: customer),
              ),
            );
          },
        ),
      );
    }).toList();

    if (markers.isEmpty) {
      // Provide sample markers if no coordinates available
      markers = [
        Marker(
          width: 40,
          height: 40,
          point: const LatLng(37.7749, -122.4194),
          builder: (_) => const Icon(Icons.location_on, color: Colors.blue),
        ),
        Marker(
          width: 40,
          height: 40,
          point: const LatLng(34.0522, -118.2437),
          builder: (_) => const Icon(Icons.location_on, color: Colors.green),
        ),
      ];
    }

    final center = markers.isNotEmpty ? markers.first.point : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers Map')),
      body: FlutterMap(
        options: MapOptions(center: center, zoom: 4),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: const {
              'id': 'mapbox/streets-v11',
              'accessToken': 'YOUR_MAPBOX_ACCESS_TOKEN',
            },
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Color _urgencyColor(AppStateProvider appState, Customer customer) {
    final settings = appState.appSettings;
    if (settings == null) return Colors.blue;
    final daysIdle = DateTime.now().difference(customer.updatedAt).inDays;
    if (daysIdle >= settings.redThresholdDays) return Colors.red;
    if (daysIdle >= settings.orangeThresholdDays) return Colors.orange;
    if (daysIdle >= settings.yellowThresholdDays) return Colors.yellow;
    return Colors.green;
  }
}
