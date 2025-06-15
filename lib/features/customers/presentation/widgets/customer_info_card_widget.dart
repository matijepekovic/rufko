import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/business/customer.dart';

/// Widget for displaying customer information card
/// Extracted from InfoTab to create reusable component
class CustomerInfoCardWidget extends StatelessWidget {
  final Customer customer;

  const CustomerInfoCardWidget({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerHeader(context),
            const SizedBox(height: 20),
            _buildContactInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context) {
    return Row(
      children: [
        _buildCustomerAvatar(context),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCustomerDetails(context),
        ),
      ],
    );
  }

  Widget _buildCustomerAvatar(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        color: Theme.of(context).primaryColor,
        size: 28,
      ),
    );
  }

  Widget _buildCustomerDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          customer.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Customer since ${DateFormat('MMM yyyy').format(customer.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow(
          context,
          Icons.phone_outlined,
          'Phone',
          customer.phone ?? 'Not provided',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          Icons.email_outlined,
          'Email',
          customer.email ?? 'Not provided',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          context,
          Icons.location_on_outlined,
          'Address',
          _getDisplayAddress(),
        ),
        if (customer.notes != null && customer.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.note_outlined,
            'Notes',
            customer.notes!,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayAddress() {
    return customer.fullDisplayAddress.isNotEmpty &&
            customer.fullDisplayAddress != 'No address provided'
        ? customer.fullDisplayAddress
        : 'Not provided';
  }
}