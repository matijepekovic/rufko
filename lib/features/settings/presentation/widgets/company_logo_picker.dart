import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../data/models/settings/app_settings.dart';
import '../../../../data/providers/state/app_state_provider.dart';

/// Widget used to display and manage the company logo.
class CompanyLogoPicker extends StatefulWidget {
  const CompanyLogoPicker({
    super.key,
    required this.settings,
    required this.appState,
    required this.onChanged,
  });

  final AppSettings settings;
  final AppStateProvider appState;
  final VoidCallback onChanged;

  @override
  State<CompanyLogoPicker> createState() => _CompanyLogoPickerState();
}

class _CompanyLogoPickerState extends State<CompanyLogoPicker> {
  @override
  Widget build(BuildContext context) {
    final logoPath = widget.settings.companyLogoPath;
    return Column(
      children: [
        if (logoPath != null) ...[
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(logoPath),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Icon(Icons.business, color: Colors.grey[400], size: 48),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _selectLogo,
                icon: const Icon(Icons.edit),
                label: const Text('Change'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await widget.appState.removeCompanyLogo(widget.settings);
                  widget.onChanged();
                  setState(() {});
                },
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _selectLogo,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Logo'),
          ),
        ],
      ],
    );
  }

  Future<void> _selectLogo() async {
    try {
      final newPath =
          await widget.appState.pickAndSaveCompanyLogo(widget.settings);
      if (newPath != null) {
        widget.onChanged();
        setState(() {});
      }
    } catch (_) {
      // ignore errors for simplicity
    }
  }
}
