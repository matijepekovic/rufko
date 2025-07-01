// lib/screens/email_template_editor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/models/templates/email_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';

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

  Future<void> _showCreateCategoryDialog() async {
    final TextEditingController categoryController = TextEditingController();

    final newCategoryKey = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Email Category',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter a name for your new email template category:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Quotes, Follow-up, Invoices',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final categoryName = categoryController.text.trim();
                          if (categoryName.isNotEmpty) {
                            try {
                              final appState = context.read<AppStateProvider>();
                              final categoryKey = categoryName.toLowerCase().replaceAll(' ', '_');

                              await appState.addTemplateCategory('email_templates', categoryKey, categoryName);

                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                Navigator.of(context).pop(categoryKey);
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Created category: $categoryName'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating category: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newCategoryKey != null && mounted) {
      setState(() {
        _selectedCategoryKey = newCategoryKey;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTemplate != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Email' : 'New Email',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: _showPlaceholderHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 16),
                    _buildSubjectSection(),
                    const SizedBox(height: 16),
                    _buildEmailContentSection(),
                    if (_detectedPlaceholders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPlaceholdersSection(),
                    ],
                    if (_emailContentController.text.trim().isNotEmpty || _subjectController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPreviewSection(),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _saveTemplate,
        backgroundColor: _isLoading ? Colors.grey : Colors.orange,
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save, size: 20),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'Quote Ready Email',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title, size: 18),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter template name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: context.read<AppStateProvider>().getAllTemplateCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 2,
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
                    labelText: 'Category *',
                    hintText: 'Select or create category',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category, size: 18),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  items: [
                    // Regular categories
                    ...emailCategories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['key'] as String,
                        child: Row(
                          children: [
                            const Icon(Icons.email, size: 16),
                            const SizedBox(width: 6),
                            Text(category['name'] as String, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }),
                    // Create new category option
                    const DropdownMenuItem<String>(
                      value: '__create_new__',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text('Create New Category', style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue == '__create_new__') {
                      _showCreateCategoryDialog();
                    } else {
                      setState(() {
                        _selectedCategoryKey = newValue;
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'When to use this template',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description, size: 18),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('Active', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Switch(
                        value: _isHtml,
                        onChanged: (value) {
                          setState(() {
                            _isHtml = value;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('HTML', style: TextStyle(fontSize: 13)),
                      ),
                    ],
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.subject, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Email Subject',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showPlaceholderPicker('subject'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject Line',
                hintText: 'Your quote #{quote_number} is ready',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject, size: 18),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter email subject';
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Email Content',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showPlaceholderPicker('content'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _emailContentController,
              decoration: InputDecoration(
                labelText: 'Email Content',
                hintText: _isHtml
                    ? '<p>Dear {customer_name}, your quote is ready!</p>'
                    : 'Dear {customer_name},\n\nYour quote is ready!',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: _isHtml ? 10 : 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter email content';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Icon(
                  _isHtml ? Icons.code : Icons.text_fields,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_emailContentController.text.length} chars (${_isHtml ? 'HTML' : 'Text'})',
                  style: TextStyle(
                    fontSize: 11,
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dynamic_form, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Placeholders (${_detectedPlaceholders.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _detectedPlaceholders.map((placeholder) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 12, color: Colors.orange.shade600),
                      const SizedBox(width: 2),
                      Text(
                        '{$placeholder}',
                        style: TextStyle(
                          fontSize: 11,
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_subjectController.text.isNotEmpty) ...[
                    Text(
                      'Subject: ${_generateLivePreview()['subject']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    _generateLivePreview()['content'] ?? '',
                    style: const TextStyle(fontSize: 13),
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
    sampleData['customerFirstName'] = 'John';
    sampleData['customerLastName'] = 'Smith';
    sampleData['customerPhone'] = '(555) 123-4567';
    sampleData['customerEmail'] = 'john.smith@email.com';
    sampleData['customerFullAddress'] = '123 Main St, Seattle, WA 98101';

    final appSettings = appState.appSettings;
    sampleData['companyName'] = appSettings?.companyName ?? 'Your Roofing Co';
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

  // NEW: Fullscreen placeholder picker instead of draggable bottom sheet
  void _showPlaceholderPicker(String targetField) {
    Navigator.of(context).push(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (context) => _EmailPlaceholderPickerScreen(
          targetField: targetField,
          onPlaceholderSelected: (placeholder) {
            Navigator.pop(context);
            _insertPlaceholder(placeholder, targetField);
          },
        ),
      ),
    );
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
        title: const Text('Placeholder Help', style: TextStyle(fontSize: 16)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Placeholders are replaced with real data:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Wrap names in braces: {customer_name}', style: TextStyle(fontSize: 13)),
              Text('• Use snake_case format', style: TextStyle(fontSize: 13)),
              Text('• Case-sensitive placeholders', style: TextStyle(fontSize: 13)),
              Text('• Unknown ones stay unchanged', style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text(
                'Example:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Subject: Quote #{quote_number} ready',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              SizedBox(height: 2),
              Text(
                'Dear {customer_name}, your quote for {quote_total} is attached!',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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
              content: Text('Email template updated!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
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
              content: Text('Email template created!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving email template: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

// NEW: Separate fullscreen placeholder picker widget for email templates
class _EmailPlaceholderPickerScreen extends StatefulWidget {
  const _EmailPlaceholderPickerScreen({
    required this.targetField,
    required this.onPlaceholderSelected,
  });

  final String targetField;
  final Function(String) onPlaceholderSelected;

  @override
  State<_EmailPlaceholderPickerScreen> createState() => _EmailPlaceholderPickerScreenState();
}

class _EmailPlaceholderPickerScreenState extends State<_EmailPlaceholderPickerScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Select Data Field - ${widget.targetField == 'subject' ? 'Subject' : 'Content'}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search fields...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Categories list
          Expanded(
            child: _buildAppDataFieldsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDataFieldsList() {
    final appState = context.read<AppStateProvider>();
    final availableProducts = appState.products;
    final customFields = appState.customAppDataFields;

    final categorizedFields = EmailTemplate.getCategorizedAppDataFieldTypes(
      availableProducts,
      customFields,
    );

    // Filter fields based on search query
    final filteredCategories = <String, List<String>>{};

    for (final entry in categorizedFields.entries) {
      final categoryName = entry.key;
      final fields = entry.value;

      final filteredFields = fields.where((field) {
        if (_searchQuery.isEmpty) return true;

        final fieldDisplayName = EmailTemplate.getFieldDisplayName(field, customFields);
        return fieldDisplayName.toLowerCase().contains(_searchQuery) ||
            field.toLowerCase().contains(_searchQuery) ||
            categoryName.toLowerCase().contains(_searchQuery);
      }).toList();

      if (filteredFields.isNotEmpty) {
        filteredCategories[categoryName] = filteredFields;
      }
    }

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No fields found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, categoryIndex) {
        final categoryName = filteredCategories.keys.elementAt(categoryIndex);
        final categoryFields = filteredCategories[categoryName]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Row(
              children: [
                _getCategoryIcon(categoryName),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${categoryFields.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            initiallyExpanded: _searchQuery.isNotEmpty ||
                categoryName.contains('Customer') ||
                categoryName.contains('Quote'),
            children: categoryFields.map((appDataType) =>
                _buildFieldSelectionItem(appDataType, customFields)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFieldSelectionItem(String appDataType, List<dynamic> customFields) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.data_object,
          size: 18,
          color: Colors.orange,
        ),
      ),
      title: Text(
        EmailTemplate.getFieldDisplayName(appDataType, customFields),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        _getFieldHint(appDataType),
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Icon(Icons.add, color: Colors.orange, size: 16),
      ),
      onTap: () => widget.onPlaceholderSelected(appDataType),
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
    if (appDataType.contains('Address')) return 'Address info';
    if (appDataType.contains('company')) return 'Business info';
    if (appDataType.contains('customer')) return 'Customer info';
    if (appDataType.contains('quote')) return 'Quote data';
    return 'Add to email';
  }
}