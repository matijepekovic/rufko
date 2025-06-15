import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Controller that handles all communication history logic
/// Extracted from InfoTab to separate concerns and improve maintainability
class CommunicationHistoryController extends ChangeNotifier {
  final Customer customer;
  final BuildContext context;

  CommunicationHistoryController({
    required this.customer,
    required this.context,
  });

  /// Check if a message is outgoing (from business to customer)
  bool isOutgoingMessage(String message) {
    if (message.toLowerCase().contains('opened sms to') ||
        message.toLowerCase().contains('opened email to')) {
      return false;
    }

    final outgoingKeywords = [
      'sent',
      'delivered',
      'provided',
      'scheduled',
      'completed',
      'quote',
      'invoice',
      'template'
    ];
    final lowerMessage = message.toLowerCase();
    return outgoingKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Get the type of message based on content
  String getMessageType(String message) {
    if (message.contains('📞')) return 'call';
    if (message.contains('📧')) return 'email';
    if (message.contains('💬')) return 'sms';
    if (message.contains('🤝')) return 'meeting';
    if (message.contains('🏠')) return 'site_visit';
    if (message.contains('📅')) return 'follow_up';
    return 'note';
  }

  /// Check if message is a customer response
  bool isCustomerResponse(String message) {
    return message.toLowerCase().contains('customer responded via') ||
        message.toLowerCase().contains('customer replied') ||
        message.toLowerCase().contains('customer said');
  }

  /// Check if there's a customer response after a given timestamp
  bool hasCustomerResponseAfter(String originalTimestamp) {
    try {
      final originalDateTime = DateTime.parse(originalTimestamp);

      for (final entry in customer.communicationHistory) {
        final parts = entry.split(': ');
        if (parts.length < 2) continue;

        final entryTimestamp = parts[0];
        final entryMessage = parts.sublist(1).join(': ');

        try {
          final entryDateTime = DateTime.parse(entryTimestamp);

          if (entryDateTime.isAfter(originalDateTime)) {
            if (entryMessage.toLowerCase().contains('customer responded via') ||
                entryMessage.toLowerCase().contains('customer replied') ||
                entryMessage.toLowerCase().contains('customer said')) {
              return true;
            }
          }
        } catch (_) {
          continue;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Clean message by removing emoji prefixes and sanitizing
  String cleanMessage(String message) {
    try {
      String cleanedMessage = message
          .replaceAll(RegExp(r'^[📞📧💬🤝🏠📅📝]\s*'), '')
          .replaceAll(RegExp(r'\[URGENT\]\s*'), '')
          .trim();

      cleanedMessage = _sanitizeString(cleanedMessage);

      return cleanedMessage.isEmpty ? 'Communication recorded' : cleanedMessage;
    } catch (_) {
      return 'Communication recorded';
    }
  }

  /// Sanitize string by removing invalid characters
  String _sanitizeString(String input) {
    try {
      final sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');

      final buffer = StringBuffer();
      for (int i = 0; i < sanitized.length; i++) {
        final char = sanitized[i];
        final code = char.codeUnitAt(0);

        if ((code >= 0x20 && code <= 0xD7FF) ||
            (code >= 0xE000 && code <= 0xFFFD) ||
            code == 0x09 || code == 0x0A || code == 0x0D) {
          buffer.write(char);
        } else {
          buffer.write(' ');
        }
      }

      return buffer.toString().trim();
    } catch (_) {
      return 'Text encoding error';
    }
  }

  /// Get icon and color for message type
  Widget getMessageTypeIcon(String messageType) {
    IconData icon;
    Color color;

    switch (messageType) {
      case 'call':
        icon = Icons.phone;
        color = Colors.green;
        break;
      case 'email':
        icon = Icons.email;
        color = Colors.blue;
        break;
      case 'sms':
        icon = Icons.sms;
        color = Colors.purple;
        break;
      case 'meeting':
        icon = Icons.handshake;
        color = Colors.orange;
        break;
      case 'site_visit':
        icon = Icons.home;
        color = Colors.brown;
        break;
      case 'follow_up':
        icon = Icons.schedule;
        color = Colors.amber;
        break;
      default:
        icon = Icons.note;
        color = Colors.grey;
    }

    return Icon(icon, size: 14, color: color);
  }

  /// Add customer response to communication history
  Future<void> addCustomerResponse(String responseType, String response) async {
    customer.addCommunication(
      'Customer responded via $responseType: $response',
      type: responseType,
    );

    await context.read<AppStateProvider>().updateCustomer(customer);
    notifyListeners();
  }

  /// Update existing customer response
  Future<void> updateCustomerResponse(
    String originalMessage,
    String timestamp,
    String newResponseType,
    String newResponse,
  ) async {
    try {
      final communicationHistory = customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];
        final parts = entry.split(': ');

        if (parts.isNotEmpty && parts[0] == timestamp) {
          final newMessage = 'Customer responded via $newResponseType: $newResponse';
          final updatedEntry = '$timestamp: $newMessage';

          communicationHistory[i] = updatedEntry;

          await context.read<AppStateProvider>().updateCustomer(customer);
          notifyListeners();

          return;
        }
      }

      throw Exception('Could not find the original response to update');
    } catch (e) {
      rethrow;
    }
  }

  /// Add project note to communication history
  Future<void> addProjectNote(String noteContent) async {
    customer.addCommunication(
      'PROJECT_NOTE: $noteContent',
      type: 'note',
    );

    await context.read<AppStateProvider>().updateCustomer(customer);
    notifyListeners();
  }

  /// Update existing project note
  Future<void> updateProjectNote(
    String originalEntry,
    String timestamp,
    String newContent,
  ) async {
    try {
      final communicationHistory = customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];

        if (entry == originalEntry) {
          final updatedEntry = '$timestamp: PROJECT_NOTE: $newContent';
          communicationHistory[i] = updatedEntry;

          await context.read<AppStateProvider>().updateCustomer(customer);
          notifyListeners();

          return;
        }
      }

      throw Exception('Could not find the original note to update');
    } catch (e) {
      rethrow;
    }
  }

  /// Get sorted communication history (most recent first)
  List<String> getSortedCommunications() {
    return customer.communicationHistory.reversed.toList();
  }

  /// Extract contact method from opened message
  String extractContactMethod(String originalMessage) {
    String contactMethod = '';
    if (originalMessage.toLowerCase().contains('opened sms to')) {
      final phoneMatch = RegExp(r'(\d{10,})').firstMatch(originalMessage);
      contactMethod = phoneMatch?.group(1) ?? customer.phone ?? '';
    } else if (originalMessage.toLowerCase().contains('opened email to')) {
      final emailMatch = RegExp(r'([^\s]+@[^\s]+)').firstMatch(originalMessage);
      contactMethod = emailMatch?.group(1) ?? customer.email ?? '';
    }
    return contactMethod;
  }
}