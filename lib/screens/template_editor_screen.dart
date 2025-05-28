// lib/screens/template_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/pdf_template.dart';
import '../services/template_service.dart';
import '../providers/app_state_provider.dart';

class TemplateEditorScreen extends StatefulWidget {
  final PDFTemplate? existingTemplate;

  const TemplateEditorScreen({
    Key? key,
    this.existingTemplate,
  }) : super(key: key);

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  PDFTemplate? _currentTemplate;
  FieldMapping? _selectedField;
  bool _isLoading = false;
  bool _showFieldPalette = true;
  final GlobalKey _pdfViewKey = GlobalKey();

  // Controllers for field properties
  final _fieldTypeController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _placeholderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentTemplate = widget.existingTemplate;
    if (_currentTemplate != null) {
      _loadTemplate();
    }
  }

  @override
  void dispose() {
    _fieldTypeController.dispose();
    _fontSizeController.dispose();
    _placeholderController.dispose();
    super.dispose();
  }

  void _loadTemplate() {
    // Initialize template display
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_currentTemplate == null ? 'Create Template' : 'Edit Template'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFieldPalette ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showFieldPalette = !_showFieldPalette),
            tooltip: 'Toggle field palette',
          ),
          if (_currentTemplate != null) ...[
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _previewTemplate,
              tooltip: 'Preview template',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTemplate,
              tooltip: 'Save template',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTemplate == null
          ? _buildTemplateSelector()
          : _buildTemplateEditor(),
      floatingActionButton: _currentTemplate == null
          ? FloatingActionButton.extended(
        onPressed: _uploadPDFTemplate,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload PDF'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white, // Fixed: Use foregroundColor instead of backgroundColor
      )
          : null,
    );
  }

  Widget _buildTemplateSelector() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Upload PDF Template',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a blank PDF template to start mapping fields',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _uploadPDFTemplate,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose PDF File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateEditor() {
    return Row(
      children: [
        // Field Palette
        if (_showFieldPalette) _buildFieldPalette(),

        // Main Editor Area
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Toolbar
              _buildEditorToolbar(),

              // PDF Canvas
              Expanded(
                child: _buildPDFCanvas(),
              ),
            ],
          ),
        ),

        // Properties Panel
        if (_selectedField != null) _buildPropertiesPanel(),
      ],
    );
  }

  Widget _buildFieldPalette() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                Text(
                  'Field Types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: PDFTemplate.getQuoteFieldTypes().map((fieldType) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Icon(_getFieldIcon(fieldType), size: 20),
                    title: Text(
                      PDFTemplate.getFieldDisplayName(fieldType),
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => _addFieldToCanvas(fieldType),
                    trailing: const Icon(Icons.add, size: 16),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _currentTemplate?.templateName ?? 'Untitled Template',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              // TODO: Implement zoom out
            },
          ),
          const Text('100%'),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              // TODO: Implement zoom in
            },
          ),

          const SizedBox(width: 16),

          // Grid toggle
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: () {
              // TODO: Toggle grid
            },
          ),

          // Clear all fields
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllFields,
            tooltip: 'Clear all fields',
          ),
        ],
      ),
    );
  }

  Widget _buildPDFCanvas() {
    return Container(
      key: _pdfViewKey,
      color: Colors.grey[200],
      child: Center(
        child: Container(
          width: 400, // Fixed canvas width for simplicity
          height: 500, // Fixed canvas height for simplicity
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[400]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // PDF Background (placeholder)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'PDF Template Preview\n(Upload PDF to see background)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Field overlays
              ..._currentTemplate?.fieldMappings.map((field) => _buildFieldOverlay(field)) ?? [],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldOverlay(FieldMapping field) {
    final isSelected = _selectedField?.fieldId == field.fieldId;

    return Positioned(
      left: field.x * 400, // Scale to canvas size
      top: field.y * 500,  // Scale to canvas size
      width: field.width * 400,
      height: field.height * 500,
      child: GestureDetector(
        onTap: () => _selectField(field),
        onPanUpdate: (details) => _moveField(field, details),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.orange,
              width: isSelected ? 2 : 1,
            ),
            color: (isSelected ? Colors.blue : Colors.orange).withOpacity(0.1), // Fixed: Use color instead of backgroundColor
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field label
              Container(
                padding: const EdgeInsets.all(2),
                color: isSelected ? Colors.blue : Colors.orange,
                child: Text(
                  PDFTemplate.getFieldDisplayName(field.fieldType),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Field content preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    field.placeholder ?? '[${PDFTemplate.getFieldDisplayName(field.fieldType)}]',
                    style: TextStyle(
                      fontSize: field.fontSize * 0.8, // Scale down for preview
                      fontWeight: field.isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: field.isItalic ? FontStyle.italic : FontStyle.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 8),
                const Text(
                  'Field Properties',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedField = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildFieldProperties(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldProperties() {
    if (_selectedField == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field Type (read-only)
          TextFormField(
            initialValue: PDFTemplate.getFieldDisplayName(_selectedField!.fieldType),
            decoration: const InputDecoration(
              labelText: 'Field Type',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
          ),
          const SizedBox(height: 16),

          // Font Size
          TextFormField(
            initialValue: _selectedField!.fontSize.toString(),
            decoration: const InputDecoration(
              labelText: 'Font Size',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final size = double.tryParse(value);
              if (size != null && size > 0) {
                _updateFieldProperty('fontSize', size);
              }
            },
          ),
          const SizedBox(height: 16),

          // Alignment
          DropdownButtonFormField<String>(
            value: _selectedField!.alignment,
            decoration: const InputDecoration(
              labelText: 'Text Alignment',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
              DropdownMenuItem(value: 'right', child: Text('Right')),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateFieldProperty('alignment', value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Bold/Italic toggles
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Bold'),
                  value: _selectedField!.isBold,
                  onChanged: (value) {
                    _updateFieldProperty('isBold', value ?? false);
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Italic'),
                  value: _selectedField!.isItalic,
                  onChanged: (value) {
                    _updateFieldProperty('isItalic', value ?? false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Placeholder text
          TextFormField(
            initialValue: _selectedField!.placeholder,
            decoration: const InputDecoration(
              labelText: 'Placeholder Text',
              border: OutlineInputBorder(),
              helperText: 'Preview text for this field',
            ),
            onChanged: (value) {
              _updateFieldProperty('placeholder', value);
            },
          ),
          const SizedBox(height: 24),

          // Delete field button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deleteSelectedField,
              icon: const Icon(Icons.delete),
              label: const Text('Delete Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _uploadPDFTemplate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Show name dialog
        final templateName = await _showTemplateNameDialog(fileName);
        if (templateName == null) {
          setState(() => _isLoading = false);
          return;
        }

        // Create template
        final template = await TemplateService.instance.createTemplateFromPDF(
          filePath,
          templateName,
        );

        if (template != null) {
          setState(() {
            _currentTemplate = template;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF template uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addFieldToCanvas(String fieldType) {
    if (_currentTemplate == null) return;

    final newField = FieldMapping(
      fieldType: fieldType,
      x: 0.1, // Default position
      y: 0.1,
      width: 0.3, // Default size
      height: 0.05,
      placeholder: PDFTemplate.getFieldDisplayName(fieldType),
    );

    setState(() {
      _currentTemplate!.addField(newField);
      _selectedField = newField;
    });
  }

  void _selectField(FieldMapping field) {
    setState(() {
      _selectedField = field;
    });
  }

  void _moveField(FieldMapping field, DragUpdateDetails details) {
    // Convert screen coordinates to relative coordinates
    final RenderBox? renderBox = _pdfViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final newX = (field.x * 400 + details.delta.dx) / 400;
      final newY = (field.y * 500 + details.delta.dy) / 500;

      // Clamp to canvas bounds
      final clampedX = newX.clamp(0.0, 1.0 - field.width);
      final clampedY = newY.clamp(0.0, 1.0 - field.height);

      setState(() {
        field.x = clampedX;
        field.y = clampedY;
      });

      // Update in template
      _currentTemplate?.updateField(field);
    }
  }

  void _updateFieldProperty(String property, dynamic value) {
    if (_selectedField == null) return;

    setState(() {
      switch (property) {
        case 'fontSize':
          _selectedField!.fontSize = value as double;
          break;
        case 'alignment':
          _selectedField!.alignment = value as String;
          break;
        case 'isBold':
          _selectedField!.isBold = value as bool;
          break;
        case 'isItalic':
          _selectedField!.isItalic = value as bool;
          break;
        case 'placeholder':
          _selectedField!.placeholder = value as String?;
          break;
      }
    });

    // Update in template
    _currentTemplate?.updateField(_selectedField!);
  }

  void _deleteSelectedField() {
    if (_selectedField == null || _currentTemplate == null) return;

    setState(() {
      _currentTemplate!.removeField(_selectedField!.fieldId);
      _selectedField = null;
    });
  }

  void _clearAllFields() {
    if (_currentTemplate == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Fields'),
        content: const Text('Are you sure you want to remove all fields from this template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentTemplate!.fieldMappings.clear();
                _selectedField = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _previewTemplate() async {
    if (_currentTemplate == null) return;

    setState(() => _isLoading = true);

    try {
      final previewPath = await TemplateService.instance.generateTemplatePreview(_currentTemplate!);

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preview generated: $previewPath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // TODO: Open PDF with default app
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating preview: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveTemplate() {
    if (_currentTemplate == null) return;

    // Template is automatically saved due to Hive integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Update app state
    context.read<AppStateProvider>().loadAllData();
  }

  Future<String?> _showTemplateNameDialog(String defaultName) {
    final controller = TextEditingController(text: defaultName.replaceAll('.pdf', ''));

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter template name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'customerName':
      case 'customerAddress':
      case 'customerPhone':
      case 'customerEmail':
        return Icons.person;
      case 'companyName':
      case 'companyAddress':
      case 'companyPhone':
      case 'companyEmail':
        return Icons.business;
      case 'quoteNumber':
      case 'quoteDate':
      case 'validUntil':
      case 'quoteStatus':
        return Icons.receipt;
      case 'levelName':
      case 'levelPrice':
        return Icons.layers;
      case 'itemName':
      case 'itemQuantity':
      case 'itemUnitPrice':
      case 'itemTotal':
        return Icons.inventory_2;
      case 'subtotal':
      case 'taxRate':
      case 'taxAmount':
      case 'discount':
      case 'grandTotal':
        return Icons.calculate;
      case 'notes':
      case 'terms':
        return Icons.notes;
      default:
        return Icons.text_fields;
    }
  }
}