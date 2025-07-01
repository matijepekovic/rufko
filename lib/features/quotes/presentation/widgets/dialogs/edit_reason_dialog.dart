import 'package:flutter/material.dart';
import '../../../../../data/models/business/quote_edit_history.dart';

/// Result object for edit reason dialog
class EditReasonResult {
  final QuoteEditReason reason;
  final String? description;

  EditReasonResult(this.reason, this.description);
}

/// Pure UI widget for selecting edit reason when creating new quote version
/// Follows clean architecture - only presentation logic, no business logic
class EditReasonDialog extends StatefulWidget {
  final Function(EditReasonResult) onReasonSelected;
  final String? title;
  final String? subtitle;

  const EditReasonDialog({
    super.key,
    required this.onReasonSelected,
    this.title,
    this.subtitle,
  });

  @override
  State<EditReasonDialog> createState() => _EditReasonDialogState();
}

class _EditReasonDialogState extends State<EditReasonDialog> {
  QuoteEditReason? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCustomDescriptionRequired = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onReasonSelected(QuoteEditReason reason) {
    setState(() {
      _selectedReason = reason;
      _isCustomDescriptionRequired = reason == QuoteEditReason.other;
      
      // Clear description if switching from 'other' to preset reason
      if (!_isCustomDescriptionRequired) {
        _descriptionController.clear();
      }
    });
  }

  void _onSubmit() {
    if (_selectedReason == null) return;

    final description = _isCustomDescriptionRequired 
        ? _descriptionController.text.trim()
        : null;

    // Validate custom description for 'other' reason
    if (_isCustomDescriptionRequired && (description == null || description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a description for the changes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onReasonSelected(EditReasonResult(_selectedReason!, description));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? 'Why are you editing this quote?'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Reason selection buttons
            ...QuoteEditReason.values.map((reason) => _buildReasonTile(reason)),
            
            // Custom description field (shown when 'Other' is selected)
            if (_isCustomDescriptionRequired) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Describe the changes',
                  hintText: 'e.g., Updated materials, added features...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null ? _onSubmit : null,
          child: const Text('Create New Version'),
        ),
      ],
    );
  }

  Widget _buildReasonTile(QuoteEditReason reason) {
    final isSelected = _selectedReason == reason;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300],
          child: Text(
            reason.icon,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          reason.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(_getReasonDescription(reason)),
        trailing: Radio<QuoteEditReason>(
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            if (value != null) _onReasonSelected(value);
          },
        ),
        onTap: () => _onReasonSelected(reason),
      ),
    );
  }

  String _getReasonDescription(QuoteEditReason reason) {
    switch (reason) {
      case QuoteEditReason.customerRequest:
        return 'Customer asked for changes to the quote';
      case QuoteEditReason.priceCorrection:
        return 'Correcting pricing or calculation errors';
      case QuoteEditReason.materialChange:
        return 'Updating materials or specifications';
      case QuoteEditReason.other:
        return 'Other reason (please specify)';
    }
  }
}