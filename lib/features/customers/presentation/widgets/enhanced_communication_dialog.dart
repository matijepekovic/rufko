import 'package:flutter/material.dart';
import '../../../../data/models/business/customer.dart';
import '../controllers/communication_entry_controller.dart';

class EnhancedCommunicationDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback? onCommunicationAdded;

  const EnhancedCommunicationDialog({
    required this.customer,
    this.onCommunicationAdded,
    super.key,
  });

  @override
  State<EnhancedCommunicationDialog> createState() => _EnhancedCommunicationDialogState();
}

class _EnhancedCommunicationDialogState extends State<EnhancedCommunicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _subjectController = TextEditingController();

  late CommunicationEntryController _controller;

  String _selectedType = 'call';
  bool _isUrgent = false;

  final Map<String, Map<String, dynamic>> _communicationTypes = {
    'call': {'label': '📞 Phone Call', 'hint': 'What was discussed on the call?'},
    'email': {'label': '📧 Email', 'hint': 'Summary of email content...'},
    'text': {'label': '💬 Text Message', 'hint': 'Text message content...'},
  };

  @override
  void initState() {
    super.initState();
    _controller = CommunicationEntryController(
      context: context,
      customer: widget.customer,
      onCommunicationAdded: widget.onCommunicationAdded,
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_comment, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Communication',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Communication Type',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _communicationTypes.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value['label'] as String),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedType = value ?? 'note'),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedType == 'email' || _selectedType == 'meeting') ...[
                        Text('Subject',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.subject),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text('Content',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: _communicationTypes[_selectedType]!['hint'] as String,
                          prefixIcon: const Icon(Icons.notes),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter communication content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Mark as Urgent'),
                        subtitle: const Text('High priority communication'),
                        value: _isUrgent,
                        onChanged: (value) => setState(() => _isUrgent = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveCommunication,
                    child: const Text('Add Communication'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCommunication() {
    if (!_formKey.currentState!.validate()) return;
    _controller.saveCommunication(
      typeLabel: _communicationTypes[_selectedType]!['label'] as String,
      isUrgent: _isUrgent,
      subject: _subjectController.text,
      content: _contentController.text,
    );
    Navigator.pop(context);
  }
}
