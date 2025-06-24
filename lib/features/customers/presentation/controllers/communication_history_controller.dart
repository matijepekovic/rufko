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

    final lowerMessage = message.toLowerCase();
    
    // Check for specific outbound message patterns
    if (lowerMessage.contains('quick sms sent:') ||
        lowerMessage.contains('outbound call to')) {
      return true;
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
    String message;
    
    if (responseType == 'email') {
      // For email responses, try to find an existing thread to reply to
      final emailThreads = groupEmailsByThread();
      
      if (emailThreads.isNotEmpty) {
        // Find the most recent thread to determine if this is a reply
        final latestThread = emailThreads.first;
        final normalizedSubject = latestThread['normalizedSubject'] as String;
        
        // If the response doesn't specify a subject, treat it as a reply to latest thread
        if (!response.toLowerCase().contains('subject:')) {
          message = 'Customer responded via email: Subject: Re: $normalizedSubject\n$response';
        } else {
          message = 'Customer responded via email: $response';
        }
      } else {
        // No existing threads, this is a new email
        if (!response.toLowerCase().contains('subject:')) {
          message = 'Customer responded via email: Subject: New Email\n$response';
        } else {
          message = 'Customer responded via email: $response';
        }
      }
    } else {
      message = 'Customer responded via $responseType: $response';
    }

    customer.addCommunication(message, type: responseType);
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

  /// Add outbound email with proper threading context
  Future<void> addOutboundEmail({
    required String subject,
    required String content,
    String? replyToThread,
  }) async {
    String message;
    
    if (replyToThread != null && replyToThread.isNotEmpty) {
      // This is a reply to an existing thread
      final normalizedReplySubject = _normalizeEmailSubject(subject);
      final normalizedThreadSubject = _normalizeEmailSubject(replyToThread);
      
      // Check if this is actually a reply (subjects match when normalized)
      if (normalizedReplySubject == normalizedThreadSubject) {
        message = 'Email sent: Subject: Re: $replyToThread\n$content';
      } else {
        // Different subject, new thread
        message = 'Email sent: Subject: $subject\n$content';
      }
    } else {
      // New email thread
      message = 'Email sent: Subject: $subject\n$content';
    }

    customer.addCommunication(message, type: 'email');
    await context.read<AppStateProvider>().updateCustomer(customer);
    notifyListeners();
  }

  /// Check if a subject would be threaded with existing emails
  bool wouldCreateNewThread(String subject) {
    final normalizedSubject = _normalizeEmailSubject(subject);
    final existingThreads = groupEmailsByThread();
    
    return !existingThreads.any((thread) => 
        thread['normalizedSubject'] == normalizedSubject);
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

  /// Update outbound communication (SMS, calls)
  Future<void> updateOutboundCommunication(
    String originalMessage,
    String timestamp,
    String newMessage,
  ) async {
    try {
      final communicationHistory = customer.communicationHistory;

      for (int i = 0; i < communicationHistory.length; i++) {
        final entry = communicationHistory[i];
        final parts = entry.split(': ');

        if (parts.isNotEmpty && parts[0] == timestamp) {
          final existingMessage = parts.sublist(1).join(': ');
          
          // Only update if this is the right entry
          if (existingMessage == originalMessage) {
            final updatedEntry = '$timestamp: $newMessage';
            communicationHistory[i] = updatedEntry;

            await context.read<AppStateProvider>().updateCustomer(customer);
            notifyListeners();

            return;
          }
        }
      }

      throw Exception('Could not find the original communication to update');
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

  /// Get only email communications
  List<Map<String, dynamic>> getEmailCommunications() {
    final emailComms = <Map<String, dynamic>>[];
    
    for (final entry in customer.communicationHistory) {
      final parts = entry.split(': ');
      if (parts.length < 2) continue;
      
      final timestamp = parts[0];
      final message = parts.sublist(1).join(': ');
      
      // Check if this is an email communication
      if (message.contains('📧') || 
          message.toLowerCase().contains('email') ||
          message.toLowerCase().contains('subject:')) {
        
        emailComms.add({
          'timestamp': timestamp,
          'message': message,
          'cleanMessage': cleanMessage(message),
          'isOutgoing': isOutgoingMessage(message),
        });
      }
    }
    
    return emailComms.reversed.toList(); // Most recent first
  }

  /// Group emails by thread using proper email threading logic
  List<Map<String, dynamic>> groupEmailsByThread() {
    final emails = getEmailCommunications();
    final threads = <String, List<Map<String, dynamic>>>{};
    
    for (final email in emails) {
      final message = email['message'] as String;
      String rawSubject = 'No Subject';
      
      // Extract subject if present
      final subjectMatch = RegExp(r'Subject:\s*([^\n]+)').firstMatch(message);
      if (subjectMatch != null) {
        rawSubject = subjectMatch.group(1)?.trim() ?? 'No Subject';
      } else if (message.contains('Email sent using template')) {
        // Extract template name as subject
        final templateMatch = RegExp(r'"([^"]+)"').firstMatch(message);
        rawSubject = templateMatch?.group(1) ?? 'Template Email';
      }
      
      // Normalize subject for threading
      final normalizedSubject = _normalizeEmailSubject(rawSubject);
      
      // Add email with both raw and normalized subjects
      email['rawSubject'] = rawSubject;
      email['normalizedSubject'] = normalizedSubject;
      
      // Group by normalized subject (this creates proper threads)
      if (!threads.containsKey(normalizedSubject)) {
        threads[normalizedSubject] = [];
      }
      threads[normalizedSubject]!.add(email);
    }
    
    // Convert to list format with thread info
    final threadList = <Map<String, dynamic>>[];
    threads.forEach((normalizedSubject, threadEmails) {
      // Sort emails within thread by timestamp (oldest first for proper conversation order)
      threadEmails.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp']) ?? DateTime.now();
        final bTime = DateTime.tryParse(b['timestamp']) ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
      
      // Use the original subject from the first email as the display subject
      final displaySubject = threadEmails.first['rawSubject'] as String;
      
      threadList.add({
        'subject': displaySubject,
        'normalizedSubject': normalizedSubject,
        'emails': threadEmails,
        'latestTimestamp': threadEmails.last['timestamp'], // Most recent email
        'messageCount': threadEmails.length,
        'hasUnread': false, // Could be enhanced later
      });
    });
    
    // Sort threads by latest message (most recent threads first)
    threadList.sort((a, b) {
      final aTime = DateTime.tryParse(a['latestTimestamp']) ?? DateTime.now();
      final bTime = DateTime.tryParse(b['latestTimestamp']) ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    
    return threadList;
  }

  /// Normalize email subject for proper threading (like Gmail/Outlook)
  String _normalizeEmailSubject(String subject) {
    String normalized = subject.trim();
    
    // Remove common email prefixes (case insensitive)
    final prefixPattern = RegExp(r'^(re|fwd|fw|forward):\s*', caseSensitive: false);
    
    // Keep removing prefixes until none are found
    String previous;
    do {
      previous = normalized;
      normalized = normalized.replaceFirst(prefixPattern, '').trim();
    } while (normalized != previous && normalized.isNotEmpty);
    
    // Remove multiple spaces and normalize
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If subject becomes empty after normalization, use fallback
    if (normalized.isEmpty) {
      return 'No Subject';
    }
    
    return normalized;
  }

  /// Parse email content to extract subject and body
  Map<String, String> parseEmailContent(String message) {
    String subject = 'No Subject';
    String body = message;
    
    // Try to extract subject
    final subjectMatch = RegExp(r'Subject:\s*([^\n]+)').firstMatch(message);
    if (subjectMatch != null) {
      subject = subjectMatch.group(1)?.trim() ?? 'No Subject';
      // Remove subject from body
      body = message.replaceFirst(subjectMatch.group(0)!, '').trim();
    }
    
    // Clean up the body
    body = cleanMessage(body);
    
    return {
      'subject': subject,
      'body': body,
    };
  }
}