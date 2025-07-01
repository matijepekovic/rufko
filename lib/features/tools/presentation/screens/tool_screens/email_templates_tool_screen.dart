import 'package:flutter/material.dart';
import '../../../../templates/presentation/screens/templates_screen.dart';
import '../../../../../core/widgets/custom_header.dart';

class EmailTemplatesToolScreen extends StatelessWidget {
  const EmailTemplatesToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Email Templates',
        leadingIcon: Icons.email_rounded,
        showBackButton: true,
      ),
      body: const TemplatesScreen(), // Email tab
    );
  }
}