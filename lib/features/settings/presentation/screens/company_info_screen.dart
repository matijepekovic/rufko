import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/company_logo_picker.dart';

/// Screen to edit company information.
class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  late AppSettings _settings;
  late AppStateProvider _appState;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppStateProvider>();
    _settings = _appState.appSettings ?? AppSettings();
    _nameController = TextEditingController(text: _settings.companyName ?? '');
    _addressController =
        TextEditingController(text: _settings.companyAddress ?? '');
    _phoneController =
        TextEditingController(text: _settings.companyPhone ?? '');
    _emailController =
        TextEditingController(text: _settings.companyEmail ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CompanyLogoPicker(
              settings: _settings,
              appState: _appState,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 20),
            _buildField(_nameController, 'Company Name', Icons.business),
            const SizedBox(height: 16),
            _buildField(_addressController, 'Address', Icons.location_on,
                maxLines: 2),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'Phone', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField(_emailController, 'Email', Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  void _save() {
    _settings.updateCompanyInfo(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );
    _appState.updateAppSettings(_settings);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company information updated!')),
    );
  }
}
