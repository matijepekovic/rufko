import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardStatusHelper {
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'sent':
        return Colors.blue.shade600;
      case 'approved':
      case 'accepted':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  static IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_outlined;
      case 'sent':
        return Icons.send_outlined;
      case 'approved':
      case 'accepted':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
