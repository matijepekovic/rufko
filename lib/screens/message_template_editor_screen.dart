// lib/screens/message_template_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/message_template.dart';
import '../providers/app_state_provider.dart';


class MessageTemplateEditorScreen extends StatefulWidget {
  const MessageTemplateEditorScreen({
    super.key,
    this.existingTemplate,
    this.initialCategory,
  });

  final MessageTemplate? existingTemplate;
  final String? initialCategory;

  @override
  State<MessageTemplateEditorScreen> createState() => _MessageTemplateEditorScreenState();
}

class _MessageTemplateEditorScreenState extends State<MessageTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _messageContentController = TextEditingController();

  String _selectedCategory = 'quote_notifications';
  bool _isActive = true;
  List<String> _detectedPlaceholders = [];

  final List<String> _categories = [
    'quote_notifications',
    'appointment_reminders',
    'job_status_updates',
    'payment_reminders',
    'follow_ups',
    'emergency_urgent',
  ];

  final Map<String, String> _categoryNames = {
    'quote_notifications': 'Quote Notifications',
    'appointment_reminders': 'Appointment Reminders',
    'job_status_updates': 'Job Status Updates',
    'payment_reminders': 'Payment Reminders',
    'follow_ups': 'Follow-ups',
    'emergency_urgent': 'Emergency/Urgent',
  };

  final Map<String, IconData> _categoryIcons = {
    'quote_notifications': Icons.notifications,
    'appointment_reminders': Icons.schedule,
    'job_status_updates': Icons.construction,
    'payment_reminders': Icons.payment,
    'follow_ups': Icons.chat,
    'emergency_urgent': Icons.warning,
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      _loadExistingTemplate();
    } else if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _messageContentController.addListener(_onMessageContentChanged);
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _descriptionController.dispose();
    _messageContentController.dispose();
    super.dispose();
  }

  void _loadExistingTemplate() {
    final template = widget.existingTemplate!;
    _templateNameController.text = template.templateName;
    _descriptionController.text = template.description;
    _messageContentController.text = template.messageContent;
    _selectedCategory = template.category;
    _isActive = template.isActive;
    _detectedPlaceholders = List.from(template.placeholders);
  }

  void _onMessageContentChanged() {
    final newPlaceholders = MessageTemplate.extractPlaceholders(_messageContentController.text);

    // Always trigger setState to refresh preview, even if placeholders haven't changed
    setState(() {
      _detectedPlaceholders = newPlaceholders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTemplate != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Message Template' : 'Create Message Template'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPlaceholderHelp,
            tooltip: 'Placeholder Help',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildMessageContentSection(),
                    const SizedBox(height: 24),
                    _buildPlaceholdersSection(),
                    const SizedBox(height: 24),
                    _buildPreviewSection(),
                    const SizedBox(height: 100), // Extra space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTemplate,
        icon: const Icon(Icons.save),
        label: Text(isEditing ? 'Update Template' : 'Create Template'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Template Name
            TextFormField(
              controller: _templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name *',
                hintText: 'e.g., Quote Ready Notification',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a template name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(_categoryIcons[category], size: 18),
                      const SizedBox(width: 8),
                      Text(_categoryNames[category] ?? category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              validator: (value) => value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of when to use this template',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Active toggle
            SwitchListTile(
              title: const Text('Active Template'),
              subtitle: const Text('Inactive templates won\'t appear in quick send options'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              secondary: Icon(
                _isActive ? Icons.visibility : Icons.visibility_off,
                color: _isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Message Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showPlaceholderPicker,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Placeholder'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use {placeholder_name} to insert dynamic content. Example: Hello {customer_name}, your quote is ready!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _messageContentController,
              decoration: const InputDecoration(
                labelText: 'Message Text *',
                hintText: 'Hello {customer_name}, your quote #{quote_number} is ready for review. Total: {quote_total}. Please let us know if you have any questions!',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the message content';
                }
                if (value.length > 1600) {
                  return 'Message is too long. SMS messages should be under 1600 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Character count
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _messageContentController.text.length > 160
                      ? Colors.orange
                      : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_messageContentController.text.length} characters',
                  style: TextStyle(
                    fontSize: 12,
                    color: _messageContentController.text.length > 160
                        ? Colors.orange
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                if (_messageContentController.text.length > 160)
                  Text(
                    '(Multiple SMS messages)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholdersSection() {
    if (_detectedPlaceholders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dynamic_form, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Detected Placeholders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These placeholders will be replaced with actual data when sending messages:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _detectedPlaceholders.map((placeholder) {
                final description = MessageTemplate.getPlaceholderDescriptions()[placeholder];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '{$placeholder}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: description,
                          child: Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.green.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_messageContentController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Live Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Auto-updating',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This preview updates automatically as you type:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'SMS Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_messageContentController.text.length} chars',
                        style: TextStyle(
                          fontSize: 10,
                          color: _messageContentController.text.length > 160
                              ? Colors.orange.shade600
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generateLivePreview(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateLivePreview() {
    final appState = context.read<AppStateProvider>();

    // Generate comprehensive sample data using same logic as PDF templates
    final sampleData = _generateSampleAppData(appState);

    // Create temporary template to generate preview
    final template = MessageTemplate(
      templateName: 'Preview',
      description: '',
      category: _selectedCategory,
      messageContent: _messageContentController.text,
      placeholders: _detectedPlaceholders,
    );

    return template.generateMessage(sampleData);
  }

  Map<String, String> _generateSampleAppData(AppStateProvider appState) {
    final now = DateTime.now();
    final sampleData = <String, String>{};

    // Customer sample data
    sampleData['customerName'] = 'John Smith';
    sampleData['customerStreetAddress'] = '123 Main Street';
    sampleData['customerCity'] = 'Seattle';
    sampleData['customerState'] = 'WA';
    sampleData['customerZipCode'] = '98101';
    sampleData['customerFullAddress'] = '123 Main Street, Seattle, WA 98101';
    sampleData['customerPhone'] = '(555) 123-4567';
    sampleData['customerEmail'] = 'john.smith@email.com';

    // Company data from app settings
    final appSettings = appState.appSettings;
    sampleData['companyName'] = appSettings?.companyName ?? 'Your Roofing Company';
    sampleData['companyAddress'] = appSettings?.companyAddress ?? '456 Business Ave, Seattle, WA 98102';
    sampleData['companyPhone'] = appSettings?.companyPhone ?? '(555) 987-6543';
    sampleData['companyEmail'] = appSettings?.companyEmail ?? 'info@yourcompany.com';

    // Quote sample data
    sampleData['quoteNumber'] = 'Q-${now.year}-001';
    sampleData['quoteDate'] = '${now.month}/${now.day}/${now.year}';
    sampleData['validUntil'] = '${now.add(const Duration(days: 30)).month}/${now.add(const Duration(days: 30)).day}/${now.add(const Duration(days: 30)).year}';
    sampleData['quoteStatus'] = 'DRAFT';
    sampleData['todaysDate'] = '${now.month}/${now.day}/${now.year}';
    sampleData['subtotal'] = '\$12,450.00';
    sampleData['taxRate'] = '8.5%';
    sampleData['taxAmount'] = '\$1,058.25';
    sampleData['grandTotal'] = '\$13,508.25';

    // Custom app data fields
    for (final field in appState.customAppDataFields) {
      final fieldName = field.fieldName;
      final currentValue = field.currentValue;

      if (currentValue.isNotEmpty) {
        sampleData[fieldName] = currentValue;
      } else {
        // Generate sample value based on field type/name
        sampleData[fieldName] = _generateSampleValueForField(fieldName);
      }
    }

    return sampleData;
  }

  String _generateSampleValueForField(String fieldName) {
    final lowerFieldName = fieldName.toLowerCase();

    if (lowerFieldName.contains('name')) return 'Sample Name';
    if (lowerFieldName.contains('phone')) return '(555) 123-4567';
    if (lowerFieldName.contains('email')) return 'sample@email.com';
    if (lowerFieldName.contains('address')) return '123 Sample Street';
    if (lowerFieldName.contains('date')) return '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}';
    if (lowerFieldName.contains('amount') || lowerFieldName.contains('price')) return '\$1,250.00';
    if (lowerFieldName.contains('percent') || lowerFieldName.contains('rate')) return '8.5%';

    return '[Sample $fieldName]';
  }

  void _showPlaceholderPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Select App Data Field'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: _buildAppDataFieldsList(),
          ),
        );
      },
    );
  }

  Widget _buildAppDataFieldsList() {
    final appState = context.read<AppStateProvider>();
    final availableProducts = appState.products;
    final customFields = appState.customAppDataFields;

    final categorizedFields = MessageTemplate.getCategorizedAppDataFieldTypes(
      availableProducts,
      customFields,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categorizedFields.length,
      itemBuilder: (context, categoryIndex) {
        final categoryName = categorizedFields.keys.elementAt(categoryIndex);
        final categoryFields = categorizedFields[categoryName]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Row(
              children: [
                _getCategoryIcon(categoryName),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${categoryFields.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            initiallyExpanded: categoryName.contains('Customer') || categoryName.contains('Quote'),
            children: categoryFields.map((appDataType) =>
                _buildFieldSelectionItem(appDataType, customFields)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFieldSelectionItem(String appDataType, List<dynamic> customFields) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.data_object,
          size: 20,
          color: Colors.green,
        ),
      ),
      title: Text(
        MessageTemplate.getFieldDisplayName(appDataType, customFields),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _getFieldHint(appDataType),
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
      trailing: const Icon(Icons.add_link, color: Colors.green),
      onTap: () {
        Navigator.pop(context);
        _insertPlaceholder(appDataType);
      },
    );
  }

  Widget _getCategoryIcon(String categoryName) {
    IconData iconData;
    Color iconColor;

    if (categoryName.contains('Customer')) {
      iconData = Icons.person;
      iconColor = Colors.blue.shade600;
    } else if (categoryName.contains('Company')) {
      iconData = Icons.business;
      iconColor = Colors.indigo.shade600;
    } else if (categoryName.contains('Quote')) {
      iconData = Icons.description;
      iconColor = Colors.purple.shade600;
    } else {
      iconData = Icons.settings;
      iconColor = Colors.grey.shade600;
    }
    return Icon(iconData, size: 18, color: iconColor);
  }

  String _getFieldHint(String appDataType) {
    if (appDataType.contains('Name')) return 'Name field';
    if (appDataType.contains('Phone')) return 'Phone number';
    if (appDataType.contains('Email')) return 'Email address';
    if (appDataType.contains('Address')) return 'Address information';
    if (appDataType.contains('company')) return 'Your business info';
    if (appDataType.contains('customer')) return 'Customer info';
    if (appDataType.contains('quote')) return 'Quote data';
    return 'Tap to add to message';
  }

  void _insertPlaceholder(String placeholder) {
    final currentPosition = _messageContentController.selection.baseOffset;
    final currentText = _messageContentController.text;
    final placeholderText = '{$placeholder}';

    String newText;
    int newCursorPosition;

    if (currentPosition >= 0) {
      // Insert at cursor position
      newText = currentText.substring(0, currentPosition) +
          placeholderText +
          currentText.substring(currentPosition);
      newCursorPosition = currentPosition + placeholderText.length;
    } else {
      // Append to end
      newText = currentText + placeholderText;
      newCursorPosition = newText.length;
    }

    _messageContentController.text = newText;
    _messageContentController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPosition),
    );
  }

  void _showPlaceholderHelp() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
      title: const Text('Placeholder Help'),
      content: const SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
      Text(
      'Placeholders are replaced with real data when sending messages:',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 12),
    Text('• Wrap placeholder names in curly braces: {customer_name}'),
    Text('• Use snake_case for placeholder names'),
    Text('• Placeholders are case-sensitive'),
    Text('• Unknown placeholders will remain'),
        Text('• Unknown placeholders will remain unchanged in the message'),
        SizedBox(height: 16),
        Text(
          'Available Placeholders:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('• {customer_name} - Full customer name'),
        Text('• {customer_phone} - Customer phone number'),
        Text('• {quote_number} - Quote reference number'),
        Text('• {quote_total} - Total quote amount'),
        Text('• {appointment_date} - Scheduled appointment date'),
        Text('• {company_name} - Your company name'),
        Text('• {current_date} - Today\'s date'),
        SizedBox(height: 12),
        Text(
          'Example:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Hello {customer_name}, your quote #{quote_number} for {quote_total} is ready!',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
      ),
      ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
    );
  }

  void _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final appState = context.read<AppStateProvider>();

      if (widget.existingTemplate != null) {
        // Update existing template
        final updatedTemplate = widget.existingTemplate!.copyWith(
          templateName: _templateNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          messageContent: _messageContentController.text.trim(),
          placeholders: _detectedPlaceholders,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );

        await appState.updateMessageTemplate(updatedTemplate);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message template updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new template
        final newTemplate = MessageTemplate(
          templateName: _templateNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          messageContent: _messageContentController.text.trim(),
          placeholders: _detectedPlaceholders,
          isActive: _isActive,
        );

        await appState.addMessageTemplate(newTemplate);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message template created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}