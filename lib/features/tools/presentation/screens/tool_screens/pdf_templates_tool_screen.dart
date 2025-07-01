import 'package:flutter/material.dart';
import '../../../../templates/presentation/screens/templates_screen.dart';
import '../../../../../core/widgets/custom_header.dart';

class PdfTemplatesToolScreen extends StatelessWidget {
  const PdfTemplatesToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'PDF Templates',
        leadingIcon: Icons.picture_as_pdf_rounded,
        showBackButton: true,
      ),
      body: const TemplatesScreen(), // PDF tab
    );
  }
}