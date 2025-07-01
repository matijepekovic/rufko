import 'package:flutter/material.dart';
import 'tool_screens/pdf_templates_tool_screen.dart';
import 'tool_screens/message_templates_tool_screen.dart';
import 'tool_screens/email_templates_tool_screen.dart';
import 'tool_screens/custom_fields_tool_screen.dart';
import 'calculator_tool_screen.dart';
import '../../../../shared/widgets/buttons/rufko_buttons.dart';

class ToolsListScreen extends StatelessWidget {
  const ToolsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildToolCard(
            context,
            icon: Icons.picture_as_pdf,
            title: 'PDF Templates',
            subtitle: 'Manage PDF templates',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PdfTemplatesToolScreen()),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.message,
            title: 'Message Templates',
            subtitle: 'SMS & text templates',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessageTemplatesToolScreen()),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.email,
            title: 'Email Templates',
            subtitle: 'Email templates',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmailTemplatesToolScreen()),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.tune,
            title: 'Custom Fields',
            subtitle: 'Field configuration',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomFieldsToolScreen()),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.calculate,
            title: 'Calculator',
            subtitle: 'Formula editor & calculator',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalculatorToolScreen()),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.account_balance,
            title: 'Tax Service',
            subtitle: 'TODO: Implement',
            color: Colors.teal,
            onTap: () => _showTodoDialog(context, 'Tax Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodoDialog(BuildContext context, String toolName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(toolName),
        content: Text('$toolName feature is not yet implemented.'),
        actions: [
          RufkoTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}