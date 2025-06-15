import 'package:intl/intl.dart';

/// Format communication date for display in chat bubbles
String formatCommunicationDate(String timestamp) {
  return CommunicationUtils.formatCommunicationDate(timestamp);
}

/// Utility functions for communication formatting and processing
/// Extracted from InfoTab to centralize common functionality
class CommunicationUtils {
  
  /// Format communication date for display
  static String formatCommunicationDate(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return DateFormat('E h:mm a').format(dateTime);
      } else {
        return DateFormat('M/d/yy h:mm a').format(dateTime);
      }
    } catch (_) {
      return timestamp;
    }
  }

  /// Parse timestamp from communication entry
  static String parseTimestamp(String entry) {
    final parts = entry.split(': ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Parse message content from communication entry  
  static String parseMessage(String entry) {
    final parts = entry.split(': ');
    return parts.length > 1 ? parts.sublist(1).join(': ') : entry;
  }

  /// Check if a message indicates an opened communication
  static bool isOpenedMessage(String message) {
    return message.toLowerCase().contains('opened sms to') ||
           message.toLowerCase().contains('opened email to');
  }

  /// Extract phone number from message
  static String? extractPhoneNumber(String message) {
    final phoneMatch = RegExp(r'(\d{10,})').firstMatch(message);
    return phoneMatch?.group(1);
  }

  /// Extract email address from message
  static String? extractEmailAddress(String message) {
    final emailMatch = RegExp(r'([^\s]+@[^\s]+)').firstMatch(message);
    return emailMatch?.group(1);
  }

  /// Check if message contains project note
  static bool isProjectNote(String message) {
    return message.contains('PROJECT_NOTE:');
  }

  /// Extract project note content
  static String extractProjectNoteContent(String message) {
    return message.replaceFirst('PROJECT_NOTE: ', '');
  }

  /// Validate response content
  static String? validateResponseContent(String content) {
    if (content.trim().isEmpty) {
      return 'Response cannot be empty';
    }
    if (content.length > 1000) {
      return 'Response is too long (max 1000 characters)';
    }
    return null;
  }

  /// Validate note content
  static String? validateNoteContent(String content) {
    if (content.trim().isEmpty) {
      return 'Note content cannot be empty';
    }
    if (content.length > 2000) {
      return 'Note is too long (max 2000 characters)';
    }
    return null;
  }

  /// Get message priority based on content
  static String getMessagePriority(String message) {
    final urgentKeywords = ['urgent', 'emergency', 'asap', 'immediately'];
    final lowerMessage = message.toLowerCase();
    
    if (urgentKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return 'high';
    }
    
    final importantKeywords = ['important', 'priority', 'deadline'];
    if (importantKeywords.any((keyword) => lowerMessage.contains(keyword))) {
      return 'medium';
    }
    
    return 'normal';
  }

  /// Get suggested response time based on message type
  static Duration getSuggestedResponseTime(String messageType) {
    switch (messageType) {
      case 'call':
        return const Duration(hours: 1);
      case 'sms':
        return const Duration(hours: 2);
      case 'email':
        return const Duration(hours: 24);
      default:
        return const Duration(hours: 4);
    }
  }

  /// Check if response is overdue
  static bool isResponseOverdue(String timestamp, String messageType) {
    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final suggestedTime = getSuggestedResponseTime(messageType);
      
      return now.difference(messageTime) > suggestedTime;
    } catch (_) {
      return false;
    }
  }

  /// Generate communication summary statistics
  static Map<String, dynamic> generateCommunicationStats(List<String> history) {
    final stats = <String, dynamic>{
      'total': history.length,
      'byType': <String, int>{},
      'responseRate': 0.0,
      'averageResponseTime': Duration.zero,
    };

    int customerResponses = 0;
    int businessMessages = 0;
    final responseTimes = <Duration>[];

    for (final entry in history) {
      final message = parseMessage(entry);
      
      if (message.toLowerCase().contains('customer responded via')) {
        customerResponses++;
        // Calculate response time logic here if needed
      } else {
        businessMessages++;
      }

      // Count by type
      final messageType = _getMessageTypeFromContent(message);
      stats['byType'][messageType] = (stats['byType'][messageType] ?? 0) + 1;
    }

    if (businessMessages > 0) {
      stats['responseRate'] = customerResponses / businessMessages;
    }

    if (responseTimes.isNotEmpty) {
      final totalTime = responseTimes.fold<Duration>(
        Duration.zero,
        (prev, time) => prev + time,
      );
      stats['averageResponseTime'] = Duration(
        milliseconds: totalTime.inMilliseconds ~/ responseTimes.length,
      );
    }

    return stats;
  }

  static String _getMessageTypeFromContent(String message) {
    if (message.contains('📞') || message.toLowerCase().contains('call')) return 'call';
    if (message.contains('📧') || message.toLowerCase().contains('email')) return 'email';
    if (message.contains('💬') || message.toLowerCase().contains('sms')) return 'sms';
    if (message.contains('🤝') || message.toLowerCase().contains('meeting')) return 'meeting';
    if (message.contains('🏠') || message.toLowerCase().contains('site')) return 'site_visit';
    if (message.contains('📅') || message.toLowerCase().contains('follow')) return 'follow_up';
    return 'note';
  }
}