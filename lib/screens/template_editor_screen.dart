// lib/screens/template_editor_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


import '../models/pdf_template.dart';
import '../services/template_service.dart';
import '../providers/app_state_provider.dart';
import 'pdf_preview_screen.dart';
import '../theme/rufko_theme.dart';

class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({
    super.key,
    this.existingTemplate,
    this.preselectedCategory, // ADD THIS
  });

  final PDFTemplate? existingTemplate;
  final String? preselectedCategory; // ADD THIS

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  PDFTemplate? _currentTemplate;
  bool _isLoading = false;
  String _loadingMessage = '';
  String? _selectedCategoryKey;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  List<Map<String, dynamic>> _detectedPdfFieldsList = [];

  int _currentPageZeroBased = 0;
  int _totalPagesInPdf = 1;

  @override
  void initState() {
    super.initState();

    if (widget.existingTemplate != null) {
      _currentTemplate = widget.existingTemplate!;
      _loadTemplateDetails();
    } else {
      // For new templates, use the preselected category
      _selectedCategoryKey = widget.preselectedCategory;
      if (kDebugMode) debugPrint('🔍 Creating new template with category: $_selectedCategoryKey');
    }

    _pdfViewerController.addListener(_viewerControllerListener);
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_viewerControllerListener);
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _viewerControllerListener() {
    if (!mounted) return;

    int controllerPageOneBased = _pdfViewerController.pageNumber;
    if (controllerPageOneBased > 0 && (controllerPageOneBased - 1) != _currentPageZeroBased) {
      setState(() {
        _currentPageZeroBased = controllerPageOneBased - 1;
      });
    }
  }

  void _loadTemplateDetails() {
    if (_currentTemplate == null) return;
    setState(() {
      _totalPagesInPdf = _currentTemplate!.totalPages;
      _selectedCategoryKey = _currentTemplate!.userCategoryKey;
      var detectedFieldsRaw = _currentTemplate!.metadata['detectedPdfFields'];
      if (detectedFieldsRaw is List) {
        _detectedPdfFieldsList = List<Map<String, dynamic>>.from(
            detectedFieldsRaw.map((e) => Map<String, dynamic>.from(e as Map))
        );
      } else {
        _detectedPdfFieldsList = [];
      }
      _currentPageZeroBased = 0;

      Future.delayed(Duration.zero, () {
        if (mounted && _totalPagesInPdf > 0) {
          if (_pdfViewerController.pageCount >= 1) {
            _pdfViewerController.jumpToPage(1);
          } else {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted && _pdfViewerController.pageCount >= 1) {
                _pdfViewerController.jumpToPage(1);
              }
            });
          }
        }
      });
    });
  }

  void _setLoading(bool isLoading, [String message = '']) {
    if (!mounted) return;
    setState(() {
      _isLoading = isLoading;
      _loadingMessage = message;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(_currentTemplate == null
            ? 'Create New Template'
            : 'Edit: ${_currentTemplate?.templateName ?? "Template"}'),
        backgroundColor: RufkoTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_currentTemplate != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTemplate,
              tooltip: 'Save Template',
            ),
          if (_currentTemplate != null)
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _previewTemplate,
              tooltip: 'Preview (with sample data)',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_loadingMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_loadingMessage)
            ]
          ],
        ),
      )
          : _currentTemplate == null
          ? _buildTemplateSelector()
          : _buildMobilePdfViewer(),
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
              Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Upload PDF to Start', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Upload a PDF form. The system will detect its fillable fields.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _uploadAndCreateTemplate,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose PDF File'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePdfViewer() {
    if (_currentTemplate == null || _currentTemplate!.pdfFilePath.isEmpty) {
      return const Center(child: Text('No PDF loaded. Upload a template to begin.'));
    }

    return Column(
      children: [
        // Compact mapping mode banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade100, Colors.orange.shade50],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'MAPPING MODE: ',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: 'Tap fields to map • Form changes not saved',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Full-screen PDF viewer
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SfPdfViewer.file(
              File(_currentTemplate!.pdfFilePath),
              controller: _pdfViewerController,
              initialZoomLevel: 0,
              enableDocumentLinkAnnotation: false,  // Try this
              enableTextSelection: false,
              onPageChanged: (details) {
                if (!mounted) return;
                setState(() {
                  _currentPageZeroBased = details.newPageNumber - 1;
                });
              },
              onTap: _handlePdfTap,
            ),
          ),
        ),

        // Page navigation for multi-page PDFs
        if (_totalPagesInPdf > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  tooltip: "First Page",
                  iconSize: 20,
                  onPressed: _currentPageZeroBased > 0
                      ? () => _pdfViewerController.jumpToPage(1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: "Previous Page",
                  iconSize: 20,
                  onPressed: _currentPageZeroBased > 0
                      ? () => _pdfViewerController.previousPage()
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Page ${_currentPageZeroBased + 1} of $_totalPagesInPdf',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: "Next Page",
                  iconSize: 20,
                  onPressed: _currentPageZeroBased < _totalPagesInPdf - 1
                      ? () => _pdfViewerController.nextPage()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  tooltip: "Last Page",
                  iconSize: 20,
                  onPressed: _currentPageZeroBased < _totalPagesInPdf - 1
                      ? () => _pdfViewerController.jumpToPage(_totalPagesInPdf)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }


  void _handlePdfTap(PdfGestureDetails details) {
    if (_currentTemplate == null || !mounted || details.pageNumber < 1) {
      return;
    }

    final int tappedPageIndexZeroBased = details.pageNumber - 1;
    final Offset tapInPdfPageCoords = details.pagePosition;

    Map<String, dynamic>? tappedFieldInfo;

    // Find which PDF field was tapped
    for (final fieldInfo in _detectedPdfFieldsList) {
      if ((fieldInfo['page'] as int? ?? -1) != tappedPageIndexZeroBased) continue;

      final List<dynamic>? pdfRectValues = fieldInfo['rect'] as List<dynamic>?;
      if (pdfRectValues == null || pdfRectValues.length != 4) continue;

      final Rect fieldPdfBounds = Rect.fromLTWH(
        (pdfRectValues[0] as num).toDouble(),
        (pdfRectValues[1] as num).toDouble(),
        (pdfRectValues[2] as num).toDouble(),
        (pdfRectValues[3] as num).toDouble(),
      );

      if (fieldPdfBounds.contains(tapInPdfPageCoords)) {
        tappedFieldInfo = fieldInfo;
        break;
      }
    }

    if (tappedFieldInfo != null) {
      _showFieldMappingDialog(tappedFieldInfo);
    }
  }

  void _showFieldMappingDialog(Map<String, dynamic> pdfFieldInfo) {
    final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';

    // Find existing mapping for this PDF field if any
    FieldMapping? currentMapping;
    try {
      currentMapping = _currentTemplate!.fieldMappings.firstWhere(
        (m) => m.pdfFormFieldName == pdfFieldName,
      );
    } catch (e) {
      currentMapping = null;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Field: $pdfFieldName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (currentMapping != null && currentMapping.pdfFormFieldName.isNotEmpty)
                          Text(
                            'Linked to: ${PDFTemplate.getFieldDisplayName(currentMapping.appDataType)}',
                            style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (currentMapping != null && currentMapping.pdfFormFieldName.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _unlinkField(currentMapping!);
                    },
                    icon: const Icon(Icons.link_off),
                    label: const Text('Unlink Field'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showFieldSelectionDialog(pdfFieldInfo);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change Mapping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFieldSelectionDialog(Map<String, dynamic> pdfFieldInfo) {
    final pdfFieldName = pdfFieldInfo['name'] as String? ?? 'Unknown Field';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Map: $pdfFieldName'),
              backgroundColor: RufkoTheme.primaryColor,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: _buildAppDataFieldsList(pdfFieldInfo),
          ),
        );
      },
    );
  }

  Widget _buildAppDataFieldsList(Map<String, dynamic> pdfFieldInfo) {
    final appState = context.read<AppStateProvider>();
    final availableProducts = appState.products;
    final customFields = appState.customAppDataFields;

    final categorizedFields = PDFTemplate.getCategorizedQuoteFieldTypesWithCustomFields(
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${categoryFields.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            initiallyExpanded: categoryName.contains('Customer') || categoryName.contains('Quote Information'),
            children: categoryFields.map((appDataType) =>
                _buildFieldSelectionItem(appDataType, pdfFieldInfo, customFields)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFieldSelectionItem(String appDataType, Map<String, dynamic> pdfFieldInfo, List<dynamic> customFields) {
    // Check if this app data type is already mapped to another PDF field
    final existingMapping = _currentTemplate!.fieldMappings
        .where((m) => m.appDataType == appDataType && m.pdfFormFieldName.isNotEmpty)
        .firstOrNull;

    final isAlreadyMapped = existingMapping != null && !existingMapping.appDataType.startsWith('unmapped_');

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAlreadyMapped ? Colors.orange.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isAlreadyMapped ? Icons.warning : Icons.radio_button_unchecked,
          size: 20,
          color: isAlreadyMapped ? Colors.orange.shade600 : Colors.green.shade600,
        ),
      ),
      title: Text(
        PDFTemplate.getFieldDisplayName(appDataType, customFields),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: isAlreadyMapped
          ? Text(
        'Already mapped to: ${existingMapping.pdfFormFieldName}',
        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
      )
          : Text(
        _getFieldHint(appDataType),
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
      trailing: Icon(
        isAlreadyMapped ? Icons.swap_horiz : Icons.add_link,
        color: isAlreadyMapped ? Colors.orange.shade600 : Colors.green.shade600,
      ),
      onTap: () {
        Navigator.pop(context);
        _confirmMapping(appDataType, pdfFieldInfo, isAlreadyMapped);
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
      iconData = categoryName.contains('Levels') ? Icons.layers : Icons.description;
      iconColor = Colors.purple.shade600;
    } else if (categoryName.contains('Products')) {
      iconData = Icons.inventory;
      iconColor = Colors.green.shade600;
    } else if (categoryName.contains('Calculations')) {
      iconData = Icons.calculate;
      iconColor = Colors.orange.shade600;
    } else if (categoryName.contains('Text')) {
      iconData = Icons.text_fields;
      iconColor = Colors.teal.shade600;
    } else {
      iconData = Icons.settings;
      iconColor = Colors.grey.shade600;
    }
    return Icon(iconData, size: 18, color: iconColor);
  }

  String _getFieldHint(String appDataType) {
    if (appDataType.contains('Name')) return 'Product name';
    if (appDataType.contains('Qty')) return 'Quantity';
    if (appDataType.contains('UnitPrice')) return 'Price per unit';
    if (appDataType.contains('Total')) return 'Line total';
    if (appDataType.contains('customer')) return 'Customer info';
    if (appDataType.contains('company')) return 'Your business info';
    if (appDataType.contains('level')) return 'Quote level data';
    return 'Tap to link with PDF field';
  }

  void _confirmMapping(String appDataType, Map<String, dynamic> pdfFieldInfo, bool isReplacing) {
    final pdfFieldName = pdfFieldInfo['name'] as String;

    if (isReplacing) {
      // Show confirmation dialog for replacing existing mapping
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Replace Existing Mapping?'),
            content: Text(
              'This will unlink "$appDataType" from its current PDF field and link it to "$pdfFieldName" instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performMapping(appDataType, pdfFieldInfo);
                },
                child: const Text('Replace'),
              ),
            ],
          );
        },
      );
    } else {
      _performMapping(appDataType, pdfFieldInfo);
    }
  }

  void _performMapping(String appDataType, Map<String, dynamic> pdfFieldInfo) {
    final String pdfFieldName = pdfFieldInfo['name'] as String;

    if (kDebugMode) debugPrint("Creating mapping: $appDataType → $pdfFieldName");

    // Remove any existing mapping for this app data type
    _currentTemplate!.fieldMappings.removeWhere((m) => m.appDataType == appDataType);

    // Remove any existing mapping for this PDF field (including unmapped placeholders)
    _currentTemplate!.fieldMappings.removeWhere((m) => m.pdfFormFieldName == pdfFieldName);

    // Create new mapping (without override functionality)
    final newMapping = FieldMapping(
      appDataType: appDataType,
      pdfFormFieldName: pdfFieldName,
      detectedPdfFieldType: PdfFormFieldType.values.firstWhere(
            (e) => e.toString() == pdfFieldInfo['type'],
        orElse: () => PdfFormFieldType. unknown,
      ),
      pageNumber: pdfFieldInfo['page'] as int,
    );

    final relRect = pdfFieldInfo['relativeRect'] as List<dynamic>?;
    if (relRect != null && relRect.length == 4) {
      newMapping.visualX = relRect[0] as double?;
      newMapping.visualY = relRect[1] as double?;
      newMapping.visualWidth = relRect[2] as double?;
      newMapping.visualHeight = relRect[3] as double?;
    }

    _currentTemplate!.addField(newMapping);
    _currentTemplate!.updatedAt = DateTime.now();
    debugPrint('🔧 Saving template with category: $_selectedCategoryKey');
    _currentTemplate!.userCategoryKey = _selectedCategoryKey; // Save selected category
    debugPrint('🔧 Template userCategoryKey after save: ${_currentTemplate!.userCategoryKey}');

    if (mounted) {
      setState(() {}); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Linked "${PDFTemplate.getFieldDisplayName(appDataType)}" to "$pdfFieldName"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _unlinkField(FieldMapping mapping) {
    if (!mounted) return;

    setState(() {
      mapping.pdfFormFieldName = '';
      mapping.detectedPdfFieldType = PdfFormFieldType. unknown;
      mapping.visualX = null;
      mapping.visualY = null;
      mapping.visualWidth = null;
      mapping.visualHeight = null;
      _currentTemplate!.updateField(mapping);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Field mapping removed."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _uploadAndCreateTemplate() async {
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppStateProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        _setLoading(true, 'Processing PDF & Detecting Fields...');

        final filePath = result.files.single.path!;
        final originalFileName = result.files.single.name;

        final templateName = await _showTemplateNameDialog(originalFileName.replaceAll('.pdf', ''));
        if (templateName == null || templateName.trim().isEmpty) {
          _setLoading(false);
          return;
        }

        final template = await TemplateService.instance.createTemplateFromPDF(filePath, templateName.trim());
        _setLoading(false);

        if (!mounted) return;
        if (template != null) {
          await appState.addExistingPDFTemplateToList(template);

          setState(() {
            _currentTemplate = template;
            _loadTemplateDetails();
          });

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Template created!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to create template.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _setLoading(false);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      if (kDebugMode) debugPrint("Error uploading/creating template: $e");
    }
  }

  void _saveTemplate() async {
    if (_currentTemplate == null) {
      if (kDebugMode) debugPrint('❌ No template to save');
      return;
    }
    if (!mounted) return;

    if (kDebugMode) {
      debugPrint('💾 Starting save for template: ${_currentTemplate!.templateName}');
      debugPrint('📍 Template ID: ${_currentTemplate!.id}');
      debugPrint('📍 Field mappings: ${_currentTemplate!.fieldMappings.length}');
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppStateProvider>();
    try {
      _currentTemplate!.updatedAt = DateTime.now();
      _currentTemplate!.userCategoryKey = _selectedCategoryKey;
      await appState.updatePDFTemplate(_currentTemplate!);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Template saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      navigator.pop();

    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving template: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _previewTemplate() async {
    if (_currentTemplate == null) return;
    _setLoading(true, 'Generating preview...');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final previewPath = await TemplateService.instance.generateTemplatePreview(_currentTemplate!);
      _setLoading(false);

      if (!mounted) return;

      // Navigate to PdfPreviewScreen like templates_screen does
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfPath: previewPath,
            suggestedFileName: 'Preview_${_currentTemplate!.templateName}.pdf',
            title: 'Template Preview: ${_currentTemplate!.templateName}',
            isPreview: true,
            templateId: _currentTemplate!.id,
          ),
        ),
      );
    } catch (e) {
      _setLoading(false);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error generating preview: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showTemplateNameDialog(String defaultName) {
    final controller = TextEditingController(text: defaultName);
    return showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Template Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter template name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Template name cannot be empty.")),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}