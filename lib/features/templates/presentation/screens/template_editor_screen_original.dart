// lib/screens/template_editor_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/editor/field_mapping_bottom_sheet.dart';
import '../widgets/editor/field_selection_dialog.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../shared/widgets/common/loading_overlay.dart';
import '../widgets/editor/mapping_mode_banner.dart';
import '../widgets/editor/pdf_viewer_widget.dart';
import '../widgets/editor/template_upload_widget.dart';

import '../../../../data/models/templates/pdf_template.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../../../quotes/presentation/screens/pdf_preview_screen.dart';
import '../../../../app/theme/rufko_theme.dart';
import "../../../../core/services/template_management_service.dart";
import "../../../../core/services/pdf/pdf_field_mapping_service.dart";
import "../../../../core/services/pdf/pdf_interaction_service.dart";

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
      if (kDebugMode) {
        debugPrint(
            '🔍 Creating new template with category: $_selectedCategoryKey');
      }
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
    if (controllerPageOneBased > 0 &&
        (controllerPageOneBased - 1) != _currentPageZeroBased) {
      setState(() {
        _currentPageZeroBased = controllerPageOneBased - 1;
      });
    }
  }

  // In your template_editor_screen.dart, replace the _loadTemplateDetails method with this:

  void _loadTemplateDetails() {
    if (_currentTemplate == null) return;
    setState(() {
      _totalPagesInPdf = _currentTemplate!.totalPages;

      // Only update category if we don't already have a preselected one (for new templates)
      // This preserves the category selected in the dialog
      _selectedCategoryKey ??= _currentTemplate!.userCategoryKey;

      var detectedFieldsRaw = _currentTemplate!.metadata['detectedPdfFields'];
      if (detectedFieldsRaw is List) {
        _detectedPdfFieldsList = List<Map<String, dynamic>>.from(
            detectedFieldsRaw.map((e) => Map<String, dynamic>.from(e as Map)));
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
          ? LoadingOverlay(message: _loadingMessage)
          : _currentTemplate == null
              ? TemplateUploadWidget(onUpload: _uploadAndCreateTemplate)
              : _buildMobilePdfViewer(),
    );
  }

  Widget _buildMobilePdfViewer() {
    if (_currentTemplate == null || _currentTemplate!.pdfFilePath.isEmpty) {
      return const Center(
          child: Text('No PDF loaded. Upload a template to begin.'));
    }
    return Column(
      children: [
        const MappingModeBanner(),
        Expanded(
          child: PdfViewerWidget(
            pdfFile: File(_currentTemplate!.pdfFilePath),
            controller: _pdfViewerController,
            onTap: _handlePdfTap,
            onPageChanged: (page) {
              if (!mounted) return;
              setState(() {
                _currentPageZeroBased = page;
                _totalPagesInPdf = _pdfViewerController.pageCount;
              });
            },
          ),
        ),
      ],
    );
  }

  void _handlePdfTap(PdfGestureDetails details) {
    if (_currentTemplate == null || !mounted || details.pageNumber < 1) {
      return;
    }

    final tappedFieldInfo = PdfInteractionService.instance.getTappedField(
      _detectedPdfFieldsList,
      details.pageNumber - 1,
      details.pagePosition,
    );

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
      builder: (context) {
        return FieldMappingBottomSheet(
          pdfFieldName: pdfFieldName,
          currentMapping: currentMapping,
          onUnlink: currentMapping != null
              ? () {
                  Navigator.pop(context);
                  _unlinkField(currentMapping!);
                }
              : null,
          onChangeMapping: () {
            Navigator.pop(context);
            _showFieldSelectionDialog(pdfFieldInfo);
          },
        );
      },
    );
  }

  void _showFieldSelectionDialog(Map<String, dynamic> pdfFieldInfo) {
    final pdfFieldName = pdfFieldInfo['name'] as String? ?? "Unknown Field";
    final appState = context.read<AppStateProvider>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FieldSelectionDialog(
        pdfFieldName: pdfFieldName,
        template: _currentTemplate!,
        products: appState.products,
        customFields: appState.customAppDataFields,
        onSelect: (field) {
          _confirmMapping(field, pdfFieldInfo, false);
        },
      ),
    );
  }

  void _confirmMapping(
      String appDataType, Map<String, dynamic> pdfFieldInfo, bool isReplacing) {
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
    if (_currentTemplate == null) return;

    PdfFieldMappingService.instance
        .performMapping(_currentTemplate!, appDataType, pdfFieldInfo);

    _currentTemplate!.updatedAt = DateTime.now();
    _currentTemplate!.userCategoryKey = _selectedCategoryKey;

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Linked "${PDFTemplate.getFieldDisplayName(appDataType)}" to "${pdfFieldInfo['name']}"',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _unlinkField(FieldMapping mapping) {
    if (!mounted || _currentTemplate == null) return;

    PdfFieldMappingService.instance.unlinkField(_currentTemplate!, mapping);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Field mapping removed.'),
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

        final templateName = await _showTemplateNameDialog(
            originalFileName.replaceAll('.pdf', ''));
        if (templateName == null || templateName.trim().isEmpty) {
          _setLoading(false);
          return;
        }

        final template = await TemplateManagementService.instance
            .uploadAndCreateTemplate(filePath, templateName.trim(), appState);
        _setLoading(false);

        if (!mounted) return;
        if (template != null) {
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
      if (kDebugMode) debugPrint('Error uploading/creating template: $e');
    }
  }

  void _saveTemplate() async {
    if (_currentTemplate == null) {
      if (kDebugMode) debugPrint('❌ No template to save');
      return;
    }
    if (!mounted) return;

    if (kDebugMode) {
      debugPrint(
          '💾 Starting save for template: ${_currentTemplate!.templateName}');
      debugPrint('📍 Template ID: ${_currentTemplate!.id}');
      debugPrint(
          '📍 Field mappings: ${_currentTemplate!.fieldMappings.length}');
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppStateProvider>();
    try {
      _currentTemplate!.userCategoryKey = _selectedCategoryKey;
      await TemplateManagementService.instance
          .saveTemplate(_currentTemplate!, appState);

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
          SnackBar(
              content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _previewTemplate() async {
    if (_currentTemplate == null) return;
    _setLoading(true, 'Generating preview...');
    final appState = context.read<AppStateProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final previewPath = await TemplateManagementService.instance
          .generateTemplatePreview(_currentTemplate!, appState);
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
        SnackBar(
            content: Text('Error generating preview: $e'),
            backgroundColor: Colors.red),
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
                  const SnackBar(
                      content: Text("Template name cannot be empty.")),
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