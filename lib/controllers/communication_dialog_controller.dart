import 'package:flutter/material.dart';

import 'communication_controller.dart';

class CommunicationDialogController extends ChangeNotifier {
  CommunicationDialogController({
    required this.commController,
    required this.template,
  }) {
    customerData = commController.buildCustomerDataMap();
  }

  final CommunicationController commController;
  final dynamic template;

  late Map<String, String> customerData;

  String smsMessage = '';
  String emailSubject = '';
  String emailContent = '';

  void generateSmsPreview() {
    smsMessage = template.generateMessage(customerData);
    notifyListeners();
  }

  void generateEmailPreview() {
    final generatedEmail = template.generateEmail(customerData);
    emailSubject = generatedEmail['subject'] ?? template.subject;
    emailContent = generatedEmail['content'] ?? template.emailContent;
    notifyListeners();
  }

  void updateSmsMessage(String value) {
    smsMessage = value;
    notifyListeners();
  }

  void updateEmailSubject(String value) {
    emailSubject = value;
    notifyListeners();
  }

  void updateEmailContent(String value) {
    emailContent = value;
    notifyListeners();
  }

  int get smsCharCount => smsMessage.length;
  int get emailCharCount => emailContent.length;

  bool get isSmsValid => smsMessage.trim().isNotEmpty;
  bool get isEmailValid =>
      emailSubject.trim().isNotEmpty && emailContent.trim().isNotEmpty;

  void sendSms() {
    if (!isSmsValid) return;
    commController.sendTemplateSMS(template, smsMessage);
  }

  void sendEmail() {
    if (!isEmailValid) return;
    commController.sendTemplateEmail(template, emailSubject, emailContent);
  }
}
