import 'package:flutter/material.dart';
import '../../../../templates/presentation/screens/templates_screen.dart';
import '../../../../../core/widgets/custom_header.dart';

class MessageTemplatesToolScreen extends StatelessWidget {
  const MessageTemplatesToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Message Templates',
        leadingIcon: Icons.message_rounded,
        showBackButton: true,
      ),
      body: const TemplatesScreen(), // Messages tab
    );
  }
}