import 'package:flutter/material.dart';
import '../../../../templates/presentation/screens/templates_screen.dart';
import '../../../../../core/widgets/custom_header.dart';

class CustomFieldsToolScreen extends StatelessWidget {
  const CustomFieldsToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Custom Fields',
        leadingIcon: Icons.tune_rounded,
        showBackButton: true,
      ),
      body: const TemplatesScreen(), // Fields tab
    );
  }
}