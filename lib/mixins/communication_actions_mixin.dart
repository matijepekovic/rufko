import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

mixin CommunicationActionsMixin<T extends StatefulWidget> on State<T> {
  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone app opened'), backgroundColor: Colors.green),
        );
      } else {
        showErrorSnackBar('Cannot make phone calls on this device');
      }
    } catch (e) {
      showErrorSnackBar('Error making phone call: $e');
    }
  }

  Future<void> sendEmail(String emailAddress, {String? subject, String? body}) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: emailAddress,
        query: _buildEmailQuery(subject: subject, body: body),
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email app opened'), backgroundColor: Colors.blue),
        );
      } else {
        showErrorSnackBar('Cannot send emails on this device');
      }
    } catch (e) {
      showErrorSnackBar('Error sending email: $e');
    }
  }

  Future<void> sendSMS(String phoneNumber, {String? message}) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: message != null ? {'body': message} : null,
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS app opened'), backgroundColor: Colors.purple),
        );
      } else {
        showErrorSnackBar('Cannot send SMS on this device');
      }
    } catch (e) {
      showErrorSnackBar('Error sending SMS: $e');
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
}
