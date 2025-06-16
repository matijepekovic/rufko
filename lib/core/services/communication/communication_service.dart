import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/business/customer.dart';
import '../../../data/providers/state/app_state_provider.dart';

/// Service class for handling communication operations (SMS, Email)
/// Separated from UI concerns for better testability and maintainability
class CommunicationService {
  const CommunicationService();

  /// Result class for communication operations
  static const CommunicationResult success = CommunicationResult.success();
  static const CommunicationResult noPhone = CommunicationResult.error('No phone number');
  static const CommunicationResult noEmail = CommunicationResult.error('No email address');

  /// Send SMS to customer using template
  Future<CommunicationResult> sendTemplateSMS({
    required Customer customer,
    required dynamic template,
    required String message,
    required AppStateProvider appState,
  }) async {
    // Log communication
    final updatedCustomer = _logCommunication(
      customer,
      'SMS sent using template "${template.templateName}" - Message: '
      '${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      'text',
    );

    // Update customer data
    await appState.updateCustomer(updatedCustomer);

    // Send SMS if phone number exists
    if (customer.phone != null) {
      return await _sendSMS(customer.phone!, message);
    } else {
      return noPhone;
    }
  }

  /// Send email to customer using template
  Future<CommunicationResult> sendTemplateEmail({
    required Customer customer,
    required dynamic template,
    required String subject,
    required String content,
    required AppStateProvider appState,
  }) async {
    // Log communication
    final updatedCustomer = _logCommunication(
      customer,
      'Email sent using template "${template.templateName}" - Subject: $subject',
      'email',
    );

    // Update customer data
    await appState.updateCustomer(updatedCustomer);

    // Send email if email address exists
    if (customer.email != null) {
      return await _sendEmail(customer.email!, subject, content);
    } else {
      return noEmail;
    }
  }

  /// Create customer data map for template variable replacement
  Map<String, String> buildCustomerDataMap({
    required Customer customer,
    required AppStateProvider appState,
  }) {
    final settings = appState.appSettings;

    return {
      'customerName': customer.name,
      'customerFirstName': customer.name.split(' ').first,
      'customerLastName': customer.name.contains(' ') 
          ? customer.name.split(' ').skip(1).join(' ') 
          : '',
      'customerPhone': customer.phone ?? 'Not provided',
      'customerEmail': customer.email ?? 'Not provided',
      'customerStreetAddress': customer.streetAddress ?? '',
      'customerCity': customer.city ?? '',
      'customerState': customer.stateAbbreviation ?? '',
      'customerZipCode': customer.zipCode ?? '',
      'customerFullAddress': customer.fullDisplayAddress,
      'companyName': settings?.companyName ?? 'Your Company Name',
      'companyPhone': settings?.companyPhone ?? 'Your Phone',
      'companyEmail': settings?.companyEmail ?? 'Your Email',
      'companyAddress': settings?.companyAddress ?? 'Your Address',
      'todaysDate': DateTime.now().toString().split(' ')[0],
      'totalQuotes': appState.getSimplifiedQuotesForCustomer(customer.id).length.toString(),
      'customerSince': customer.createdAt.toString().split(' ')[0],
      'representativeName': 'Your Sales Rep',
      'appointmentDate': 'TBD',
      'appointmentTime': 'TBD',
      'quoteNumber': 'Will be assigned',
      'projectAddress': customer.fullDisplayAddress,
    };
  }

  /// EXACT COPY of the communication creation and saving logic from CommunicationEntryController
  /// This is the ORIGINAL working code, just moved to a service
  static Future<void> saveCommunicationEntry({
    required AppStateProvider appState,
    required Customer customer,
    required String typeLabel,
    required bool isUrgent,
    required String subject,
    required String content,
  }) async {
    // EXACT COPY of lines 27-35 from CommunicationEntryController.saveCommunication()
    String prefix = typeLabel.split(' ').first;
    String message = prefix;
    if (isUrgent) message += ' [URGENT]';
    if (subject.trim().isNotEmpty) {
      message += ' [${subject.trim()}]';
    }
    message += ' ${content.trim()}';
    customer.addCommunication(message);
    await appState.updateCustomer(customer);
  }

  Customer _logCommunication(Customer customer, String message, String type) {
    customer.addCommunication(message, type: type);
    return customer;
  }

  Future<CommunicationResult> _sendSMS(String phoneNumber, String message) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return success;
      } else {
        return const CommunicationResult.error('Cannot launch SMS app');
      }
    } catch (e) {
      return CommunicationResult.error('SMS sending failed: $e');
    }
  }

  Future<CommunicationResult> _sendEmail(String emailAddress, String subject, String body) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: emailAddress,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return success;
      } else {
        return const CommunicationResult.error('Cannot launch email app');
      }
    } catch (e) {
      return CommunicationResult.error('Email sending failed: $e');
    }
  }
}

/// Result class for communication operations
class CommunicationResult {
  const CommunicationResult.success() : this._(true, null);
  const CommunicationResult.error(String message) : this._(false, message);
  
  const CommunicationResult._(this.isSuccess, this.errorMessage);

  final bool isSuccess;
  final String? errorMessage;

  bool get isError => !isSuccess;
}