// lib/screens/message_template_editor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/message_template.dart';
import '../../../providers/app_state_provider.dart';

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

  bool _isActive = true;
  List<String> _detectedPlaceholders = [];
  String? _selectedCategoryKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryKey = widget.existingTemplate?.userCategoryKey ?? widget.initialCategory;
    if (widget.existingTemplate != null) {
      _loadExistingTemplate();
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
    _isActive = template.isActive;
    _detectedPlaceholders = List.from(template.placeholders);
    debugPrint('📝 Loaded existing message template: ${template.templateName}');
  }

  void _onMessageContentChanged() {
    final newPlaceholders = MessageTemplate.extractPlaceholders(_messageContentController.text);
    setState(() {
      _detectedPlaceholders = newPlaceholders;
    });
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
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
        final messageCategories = allCategories['message_templates'] ?? [];

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
            ...messageCategories.map<DropdownMenuItem<String>>((category) {
              return DropdownMenuItem<String>(
                value: category['key'] as String,
                child: Row(
                  children: [
                    const Icon(Icons.sms, size: 16),
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
                  Icon(Icons.add_circle, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text('Create New Category', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500)),
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
    );
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
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Message Category',
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
                        'Enter a name for your new message template category:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Follow-up, Estimates, Confirmations',
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

                              await appState.addTemplateCategory('message_templates', categoryKey, categoryName);

                              if (mounted) {
                                Navigator.of(context).pop(categoryKey);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Created category: $categoryName'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
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
                          backgroundColor: Colors.green,
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
          isEditing ? 'Edit Message' : 'New Message',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.green,
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
                    _buildMessageContentSection(),
                    if (_detectedPlaceholders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPlaceholdersSection(),
                    ],
                    if (_messageContentController.text.trim().isNotEmpty) ...[
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
        backgroundColor: _isLoading ? Colors.grey : Colors.green,
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
                Icon(Icons.info_outline, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _templateNameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'Quote Ready Notification',
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

            _buildCategoryDropdown(),
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
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Active Template', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContentSection() {
    final charCount = _messageContentController.text.length;
    final isLong = charCount > 160;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Message Content',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showPlaceholderPicker,
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
              controller: _messageContentController,
              decoration: const InputDecoration(
                labelText: 'Message Text',
                hintText: 'Hello {customer_name}, your quote #{quote_number} is ready!',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter message content';
                }
                if (value.length > 1600) {
                  return 'Message too long (max 1600 chars)';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isLong ? Colors.orange : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '$charCount characters',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLong ? Colors.orange : Colors.grey[600],
                  ),
                ),
                if (isLong) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(Multiple SMS)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
                Icon(Icons.dynamic_form, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Placeholders (${_detectedPlaceholders.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _detectedPlaceholders.map((placeholder) {
                final description = MessageTemplate.getPlaceholderDescriptions()[placeholder];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 2),
                      Text(
                        '{$placeholder}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(width: 2),
                        Tooltip(
                          message: description,
                          child: Icon(
                            Icons.help_outline,
                            size: 10,
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
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
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'SMS Preview',
                        style: TextStyle(
                          fontSize: 11,
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
                  const SizedBox(height: 6),
                  Text(
                    _generateLivePreview(),
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

  String _generateLivePreview() {
    final appState = context.read<AppStateProvider>();
    final sampleData = _generateSampleAppData(appState);

    final template = MessageTemplate(
      templateName: 'Preview',
      description: '',
      category: _selectedCategoryKey ?? 'uncategorized',
      userCategoryKey: _selectedCategoryKey,
      messageContent: _messageContentController.text,
      placeholders: _detectedPlaceholders,
    );

    return template.generateMessage(sampleData);
  }

  Map<String, String> _generateSampleAppData(AppStateProvider appState) {
    final now = DateTime.now();
    final sampleData = <String, String>{};

    sampleData['customerName'] = 'John Smith';
    sampleData['customerFirstName'] = 'John';
    sampleData['customerLastName'] = 'Smith';
    sampleData['customerStreetAddress'] = '123 Main St';
    sampleData['customerCity'] = 'Seattle';
    sampleData['customerState'] = 'WA';
    sampleData['customerZipCode'] = '98101';
    sampleData['customerFullAddress'] = '123 Main St, Seattle, WA 98101';
    sampleData['customerPhone'] = '(555) 123-4567';
    sampleData['customerEmail'] = 'john.smith@email.com';

    final appSettings = appState.appSettings;
    sampleData['companyName'] = appSettings?.companyName ?? 'Your Roofing Co';
    sampleData['companyAddress'] = appSettings?.companyAddress ?? '456 Business Ave, Seattle, WA 98102';
    sampleData['companyPhone'] = appSettings?.companyPhone ?? '(555) 987-6543';
    sampleData['companyEmail'] = appSettings?.companyEmail ?? 'info@yourcompany.com';

    sampleData['quoteNumber'] = 'Q-${now.year}-001';
    sampleData['quoteDate'] = '${now.month}/${now.day}/${now.year}';
    sampleData['validUntil'] = '${now.add(const Duration(days: 30)).month}/${now.add(const Duration(days: 30)).day}/${now.add(const Duration(days: 30)).year}';
    sampleData['quoteStatus'] = 'DRAFT';
    sampleData['todaysDate'] = '${now.month}/${now.day}/${now.year}';
    sampleData['subtotal'] = '\$12,450.00';
    sampleData['taxRate'] = '8.5%';
    sampleData['taxAmount'] = '\$1,058.25';
    sampleData['grandTotal'] = '\$13,508.25';

    for (final field in appState.customAppDataFields) {
      final fieldName = field.fieldName;
      final currentValue = field.currentValue;

      if (currentValue.isNotEmpty) {
        sampleData[fieldName] = currentValue;
      } else {
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
    if (lowerFieldName.contains('address')) return '123 Sample St';
    if (lowerFieldName.contains('date')) return '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}';
    if (lowerFieldName.contains('amount') || lowerFieldName.contains('price')) return '\$1,250.00';
    if (lowerFieldName.contains('percent') || lowerFieldName.contains('rate')) return '8.5%';

    return '[Sample $fieldName]';
  }

  // NEW: Fullscreen placeholder picker instead of draggable bottom sheet
  void _showPlaceholderPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (context) => _PlaceholderPickerScreen(
          onPlaceholderSelected: (placeholder) {
            Navigator.pop(context);
            _insertPlaceholder(placeholder);
          },
        ),
      ),
    );
  }

  void _insertPlaceholder(String placeholder) {
    final currentPosition = _messageContentController.selection.baseOffset;
    final currentText = _messageContentController.text;
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

    _messageContentController.text = newText;
    _messageContentController.selection = TextSelection.fromPosition(
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
                'Available Placeholders:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text('• {customer_name} - Full customer name', style: TextStyle(fontSize: 12)),
              Text('• {customer_phone} - Customer phone', style: TextStyle(fontSize: 12)),
              Text('• {quote_number} - Quote reference', style: TextStyle(fontSize: 12)),
              Text('• {quote_total} - Total quote amount', style: TextStyle(fontSize: 12)),
              Text('• {company_name} - Your company name', style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              Text(
                'Example:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Hello {customer_name}, your quote #{quote_number} for {quote_total} is ready!',
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
        debugPrint('💾 Updating existing message template: ${widget.existingTemplate!.id}');

        final updatedTemplate = widget.existingTemplate!.copyWith(
          templateName: _templateNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategoryKey ?? 'uncategorized',
          userCategoryKey: _selectedCategoryKey,
          messageContent: _messageContentController.text.trim(),
          placeholders: _detectedPlaceholders,
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );

        await appState.updateMessageTemplate(updatedTemplate);
        debugPrint('✅ Message template updated successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message template updated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        debugPrint('🆕 Creating new message template');

        final newTemplate = MessageTemplate(
          templateName: _templateNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategoryKey ?? 'uncategorized',
          userCategoryKey: _selectedCategoryKey,
          messageContent: _messageContentController.text.trim(),
          placeholders: _detectedPlaceholders,
          isActive: _isActive,
        );

        await appState.addMessageTemplate(newTemplate);
        debugPrint('✅ Message template created successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message template created!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving message template: $e');

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

// NEW: Separate fullscreen placeholder picker widget
class _PlaceholderPickerScreen extends StatefulWidget {
  const _PlaceholderPickerScreen({
    required this.onPlaceholderSelected,
  });

  final Function(String) onPlaceholderSelected;

  @override
  State<_PlaceholderPickerScreen> createState() => _PlaceholderPickerScreenState();
}

class _PlaceholderPickerScreenState extends State<_PlaceholderPickerScreen> {
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
        title: const Text('Select Data Field'),
        backgroundColor: Colors.green,
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
                  color: Colors.grey.withOpacity(0.1),
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

    final categorizedFields = MessageTemplate.getCategorizedAppDataFieldTypes(
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

        final fieldDisplayName = MessageTemplate.getFieldDisplayName(field, customFields);
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${categoryFields.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
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
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.data_object,
          size: 18,
          color: Colors.green,
        ),
      ),
      title: Text(
        MessageTemplate.getFieldDisplayName(appDataType, customFields),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        _getFieldHint(appDataType),
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Icon(Icons.add, color: Colors.green, size: 16),
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
    return 'Add to message';
  }
}