// lib/screens/email_template_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/email_template.dart';
import '../providers/app_state_provider.dart';

class EmailTemplateEditorScreen extends StatefulWidget {
  const EmailTemplateEditorScreen({
    super.key,
    this.existingTemplate,
    this.initialCategory,
  });

  final EmailTemplate? existingTemplate;
  final String? initialCategory;

  @override
  State<EmailTemplateEditorScreen> createState() => _EmailTemplateEditorScreenState();
}

class _EmailTemplateEditorScreenState extends State<EmailTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _emailContentController = TextEditingController();

  String? _selectedCategoryKey;
  bool _isActive = true;
  bool _isHtml = false;
  List<String> _detectedPlaceholders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryKey = widget.existingTemplate?.userCategoryKey ?? widget.initialCategory;
    if (widget.existingTemplate != null) {
      _loadExistingTemplate();
    }
    _subjectController.addListener(_onContentChanged);
    _emailContentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _emailContentController.dispose();
    super.dispose();
  }

  void _loadExistingTemplate() {
    final template = widget.existingTemplate!;
    _templateNameController.text = template.templateName;
    _descriptionController.text = template.description;
    _subjectController.text = template.subject;
    _emailContentController.text = template.emailContent;
    _selectedCategoryKey = template.userCategoryKey;
    _isActive = template.isActive;
    _isHtml = template.isHtml;
    _detectedPlaceholders = List.from(template.placeholders);
    debugPrint('📝 Loaded existing email template: ${template.templateName}');
  }

  void _onContentChanged() {
    final allPlaceholders = EmailTemplate.extractAllPlaceholders(
        _subjectController.text,
        _emailContentController.text
    );

    setState(() {
      _detectedPlaceholders = allPlaceholders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTemplate != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Email Template' : 'Create Email Template'),
        backgroundColor: Colors.orange,
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
                    _buildSubjectSection(),
                    const SizedBox(height: 24),
                    _buildEmailContentSection(),
                    const SizedBox(height: 24),
                    _buildPlaceholdersSection(),
                    const SizedBox(height: 24),
                    _buildPreviewSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveTemplate,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save),
        label: Text(isEditing ? 'Update Template' : 'Create Template'),
        backgroundColor: _isLoading ? Colors.grey : Colors.orange,
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
                Icon(Icons.info_outline, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name *',
                hintText: 'e.g., Quote Ready Email',
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

            FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: context.read<AppStateProvider>().getAllTemplateCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: const LinearProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final allCategories = snapshot.data!;
                final emailCategories = allCategories['email_templates'] ?? [];

                return DropdownButtonFormField<String>(
                  value: _selectedCategoryKey,
                  decoration: const InputDecoration(
                    labelText: 'Email Category',
                    hintText: 'Select a category (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.clear, size: 18),
                          SizedBox(width: 8),
                          Text('No Category'),
                        ],
                      ),
                    ),
                    ...emailCategories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['key'] as String,
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 18),
                            SizedBox(width: 8),
                            Text(category['name'] as String),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategoryKey = newValue;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

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

            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Active Template'),
                    subtitle: const Text('Inactive templates won\'t appear in options'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    secondary: Icon(
                      _isActive ? Icons.visibility : Icons.visibility_off,
                      color: _isActive ? Colors.orange : Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('HTML Email'),
                    subtitle: const Text('Enable rich formatting'),
                    value: _isHtml,
                    onChanged: (value) {
                      setState(() {
                        _isHtml = value;
                      });
                    },
                    secondary: Icon(
                      _isHtml ? Icons.code : Icons.text_fields,
                      color: _isHtml ? Colors.orange : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.subject, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Email Subject',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showPlaceholderPicker('subject'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Placeholder'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use {placeholder_name} to insert dynamic content in the subject line',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Line *',
                hintText: 'Your quote #{quote_number} is ready - {customer_name}',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the email subject';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailContentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Email Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showPlaceholderPicker('content'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Placeholder'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isHtml
                  ? 'HTML content with {placeholder_name} for dynamic data. Basic HTML tags supported.'
                  : 'Plain text content with {placeholder_name} for dynamic data.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailContentController,
              decoration: InputDecoration(
                labelText: 'Email Content *',
                hintText: _isHtml
                    ? '<p>Dear {customer_name},</p><p>Your quote #{quote_number} for {quote_total} is ready!</p>'
                    : 'Dear {customer_name},\n\nYour quote #{quote_number} for {quote_total} is ready!\n\nBest regards,\n{company_name}',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: _isHtml ? 12 : 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the email content';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  _isHtml ? Icons.code : Icons.text_fields,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_emailContentController.text.length} characters (${_isHtml ? 'HTML' : 'Plain Text'})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                Icon(Icons.dynamic_form, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Detected Placeholders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These placeholders will be replaced with actual data when sending emails:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _detectedPlaceholders.map((placeholder) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 14, color: Colors.orange.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '{$placeholder}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
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
    if (_subjectController.text.trim().isEmpty && _emailContentController.text.trim().isEmpty) {
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
                Icon(Icons.preview, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Live Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Auto-updating',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
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
                      Icon(Icons.email, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Email Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _isHtml ? 'HTML' : 'Plain Text',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_subjectController.text.isNotEmpty) ...[
                    Text(
                      'Subject: ${_generateLivePreview()['subject']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _generateLivePreview()['content'] ?? '',
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

  Map<String, String> _generateLivePreview() {
    final appState = context.read<AppStateProvider>();
    final sampleData = _generateSampleAppData(appState);

    final template = EmailTemplate(
      templateName: 'Preview',
      description: '',
      category: _selectedCategoryKey ?? 'uncategorized',
      userCategoryKey: _selectedCategoryKey,
      subject: _subjectController.text,
      emailContent: _emailContentController.text,
      placeholders: _detectedPlaceholders,
      isHtml: _isHtml,
    );

    return template.generateEmail(sampleData);
  }

  Map<String, String> _generateSampleAppData(AppStateProvider appState) {
    final now = DateTime.now();
    final sampleData = <String, String>{};

    sampleData['customerName'] = 'John Smith';
    sampleData['customerPhone'] = '(555) 123-4567';
    sampleData['customerEmail'] = 'john.smith@email.com';
    sampleData['customerFullAddress'] = '123 Main Street, Seattle, WA 98101';

    final appSettings = appState.appSettings;
    sampleData['companyName'] = appSettings?.companyName ?? 'Your Roofing Company';
    sampleData['companyPhone'] = appSettings?.companyPhone ?? '(555) 987-6543';
    sampleData['companyEmail'] = appSettings?.companyEmail ?? 'info@yourcompany.com';

    sampleData['quoteNumber'] = 'Q-${now.year}-001';
    sampleData['quoteDate'] = '${now.month}/${now.day}/${now.year}';
    sampleData['quoteStatus'] = 'READY';
    sampleData['grandTotal'] = '\$13,508.25';

    for (final field in appState.customAppDataFields) {
      final fieldName = field.fieldName;
      final currentValue = field.currentValue;

      if (currentValue.isNotEmpty) {
        sampleData[fieldName] = currentValue;
      } else {
        sampleData[fieldName] = '[Sample $fieldName]';
      }
    }

    return sampleData;
  }

  void _showPlaceholderPicker(String targetField) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Select App Data Field'),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: _buildAppDataFieldsList(targetField),
          ),
        );
      },
    );
  }

  Widget _buildAppDataFieldsList(String targetField) {
    final appState = context.read<AppStateProvider>();
    final availableProducts = appState.products;
    final customFields = appState.customAppDataFields;

    final categorizedFields = EmailTemplate.getCategorizedAppDataFieldTypes(
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
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${categoryFields.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            initiallyExpanded: categoryName.contains('Customer') || categoryName.contains('Quote'),
            children: categoryFields.map((appDataType) =>
                _buildFieldSelectionItem(appDataType, customFields, targetField)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFieldSelectionItem(String appDataType, List<dynamic> customFields, String targetField) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.data_object,
          size: 20,
          color: Colors.orange,
        ),
      ),
      title: Text(
        EmailTemplate.getFieldDisplayName(appDataType, customFields),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _getFieldHint(appDataType),
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
      trailing: const Icon(Icons.add_link, color: Colors.orange),
      onTap: () {
        Navigator.pop(context);
        _insertPlaceholder(appDataType, targetField);
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
    } else if (categoryName.contains('Products')) {
      iconData = Icons.inventory;
      iconColor = Colors.green.shade600;
    } else if (categoryName.contains('Calculations')) {
      iconData = Icons.calculate;
      iconColor = Colors.orange.shade600;
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
    return 'Tap to add to email';
  }

  void _insertPlaceholder(String placeholder, String targetField) {
    final targetController = targetField == 'subject' ? _subjectController : _emailContentController;

    final currentPosition = targetController.selection.baseOffset;
    final currentText = targetController.text;
    final placeholderText = '{$placeholder}';

    String newText;
    int newCursorPosition;

    if (currentPosition >= 0) {
      newText = currentText.substring(0, currentPosition) +
          placeholderText +
          currentText.substring(currentPosition);
      newCursorPosition = currentPosition + placeholderText.length;
    } else {
      newText = currentText + placeholderText;
      newCursorPosition = newText.length;
    }

    targetController.text = newText;
    targetController.selection = TextSelection.fromPosition(
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
                'Placeholders are replaced with real data when sending emails:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Wrap placeholder names in curly braces: {customer_name}'),
              Text('• Use snake_case for placeholder names'),
              Text('• Placeholders are case-sensitive'),
              Text('• Unknown placeholders will remain unchanged'),
              Text('• Use placeholders in both subject and email content'),
              SizedBox(height: 16),
              Text(
                'Email Example:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Subject: Your quote #{quote_number} is ready',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 4),
              Text(
                'Dear {customer_name}, your quote for {quote_total} is attached!',
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

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppStateProvider>();

      if (widget.existingTemplate != null) {
        debugPrint('💾 Updating existing email template: ${widget.existingTemplate!.id}');

        final updatedTemplate = widget.existingTemplate!.copyWith(
          templateName: _templateNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategoryKey ?? 'uncategorized',
          userCategoryKey: _selectedCategoryKey,
          subject: _subjectController.text.trim(),
          emailContent: _emailContentController.text.trim(),
          placeholders: _detectedPlaceholders,
          isActive: _isActive,
          isHtml: _isHtml,
          updatedAt: DateTime.now(),
        );

        await appState.updateEmailTemplate(updatedTemplate);
        debugPrint('✅ Email template updated successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email template updated successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        debugPrint('🆕 Creating new email template');

        final newTemplate = EmailTemplate(
          templateName: _templateNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategoryKey ?? 'uncategorized',
          userCategoryKey: _selectedCategoryKey,
          subject: _subjectController.text.trim(),
          emailContent: _emailContentController.text.trim(),
          placeholders: _detectedPlaceholders,
          isActive: _isActive,
          isHtml: _isHtml,
        );
        await appState.addEmailTemplate(newTemplate);
        debugPrint('✅ Email template created successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email template created successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving email template: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}