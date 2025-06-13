import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/business/customer.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class CommunicationController {
  CommunicationController({
    required this.context,
    required this.customer,
    this.onUpdated,
  });

  final BuildContext context;
  final Customer customer;
  final VoidCallback? onUpdated;

  Map<String, String> buildCustomerDataMap() {
    final appState = context.read<AppStateProvider>();
    final settings = appState.appSettings;

    return {
      'customerName': customer.name,
      'customerFirstName': customer.name.split(' ').first,
      'customerLastName':
          customer.name.contains(' ') ? customer.name.split(' ').skip(1).join(' ') : '',
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
      'currentTime': TimeOfDay.now().format(context),
      'totalQuotes':
          appState.getSimplifiedQuotesForCustomer(customer.id).length.toString(),
      'customerSince': customer.createdAt.toString().split(' ')[0],
      'representativeName': 'Your Sales Rep',
      'appointmentDate': 'TBD',
      'appointmentTime': 'TBD',
      'quoteNumber': 'Will be assigned',
      'projectAddress': customer.fullDisplayAddress,
    };
  }

  void sendTemplateSMS(dynamic template, String message) {
    customer.addCommunication(
      'SMS sent using template "${template.templateName}" - Message: '
      '${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      type: 'text',
    );
    context.read<AppStateProvider>().updateCustomer(customer);
    onUpdated?.call();

    if (customer.phone != null) {
      _sendSMS(customer.phone!, message: message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer has no phone number. Communication logged only.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void sendTemplateEmail(dynamic template, String subject, String content) {
    customer.addCommunication(
      'Email sent using template "${template.templateName}" - Subject: $subject',
      type: 'email',
    );
    context.read<AppStateProvider>().updateCustomer(customer);
    onUpdated?.call();

    if (customer.email != null) {
      _sendEmail(customer.email!, subject: subject, body: content);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Customer has no email address. Communication logged only.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _sendEmail(String emailAddress, {String? subject, String? body}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: emailAddress,
        query: _buildEmailQuery(subject: subject, body: body),
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        messenger.showSnackBar(
          const SnackBar(content: Text('Email app opened'), backgroundColor: Colors.blue),
        );
      } else {
        _showError('Cannot send emails on this device');
      }
    } catch (e) {
      _showError('Error sending email: $e');
    }
  }

  Future<void> _sendSMS(String phoneNumber, {String? message}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: message != null ? {'body': message} : null,
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        messenger.showSnackBar(
          const SnackBar(content: Text('SMS app opened'), backgroundColor: Colors.purple),
        );
      } else {
        _showError('Cannot send SMS on this device');
      }
    } catch (e) {
      _showError('Error sending SMS: $e');
    }
  }

  String _buildEmailQuery({String? subject, String? body}) {
    final params = <String, String>{};
    if (subject != null) params['subject'] = subject;
    if (body != null) params['body'] = body;
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
