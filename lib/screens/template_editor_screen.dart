// lib/screens/template_editor_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_filex/open_filex.dart';

import '../models/pdf_template.dart';
import '../services/template_service.dart';
import '../providers/app_state_provider.dart';

class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({
    super.key,
    this.existingTemplate,
  });

  final PDFTemplate? existingTemplate;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  PDFTemplate? _currentTemplate;
  FieldMapping? _currentlySelectedAppFieldMapping;
  Map<String, dynamic>? _visuallySelectedPdfFieldInfo;

  bool _isLoading = false;
  String _loadingMessage = '';

  final PdfViewerController _pdfViewerController = PdfViewerController();
  List<Map<String, dynamic>> _detectedPdfFieldsList = [];

  int _currentPageZeroBased = 0;
  int _totalPagesInPdf = 1;

  double _currentViewerZoomLevel = 1.0;
  Offset _currentViewerScrollOffset = Offset.zero;

  final GlobalKey _pdfViewerContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.existingTemplate != null) {
      _currentTemplate = widget.existingTemplate!;
      _loadTemplateDetails();
    } else {
      if (kDebugMode) print('🔍 NO EXISTING TEMPLATE - Creating new');
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
    bool needsRebuild = false;
    if (_pdfViewerController.zoomLevel != _currentViewerZoomLevel) {
      _currentViewerZoomLevel = _pdfViewerController.zoomLevel;
      needsRebuild = true;
    }
    if (_pdfViewerController.scrollOffset != _currentViewerScrollOffset) {
      _currentViewerScrollOffset = _pdfViewerController.scrollOffset;
      needsRebuild = true;
    }
    int controllerPageOneBased = _pdfViewerController.pageNumber;
    if (controllerPageOneBased > 0 && (controllerPageOneBased -1) != _currentPageZeroBased) {
      _currentPageZeroBased = controllerPageOneBased -1;
      if (_visuallySelectedPdfFieldInfo != null &&
          (_visuallySelectedPdfFieldInfo!['page'] as int? ?? -1) != _currentPageZeroBased) {
        _visuallySelectedPdfFieldInfo = null;
      }
      needsRebuild = true;
    }
    if (needsRebuild) {
      setState(() {});
    }
  }

  void _loadTemplateDetails() {
    if (_currentTemplate == null) return;
    setState(() {
      _totalPagesInPdf = _currentTemplate!.totalPages;
      var detectedFieldsRaw = _currentTemplate!.metadata['detectedPdfFields'];
      if (detectedFieldsRaw is List) {
        _detectedPdfFieldsList = List<Map<String, dynamic>>.from(
            detectedFieldsRaw.map((e) => Map<String, dynamic>.from(e as Map))
        );
      } else {
        _detectedPdfFieldsList = [];
      }
      _currentPageZeroBased = 0;
      _clearAllSelections();

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

  void _clearAllSelections(){
    if (!mounted) return;
    setState(() {
      _currentlySelectedAppFieldMapping = null;
      _visuallySelectedPdfFieldInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(_currentTemplate == null ? 'Create New Template' : 'Edit: ${_currentTemplate?.templateName ?? "Template"}'),
        backgroundColor: const Color(0xFF2E86AB),
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
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), if(_loadingMessage.isNotEmpty) ...[const SizedBox(height: 10), Text(_loadingMessage)]]))
          : _currentTemplate == null
          ? _buildTemplateSelector()
          : _buildEditorLayout(),
      floatingActionButton: _currentTemplate == null
          ? FloatingActionButton.extended(
        onPressed: _uploadAndCreateTemplate,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload PDF Template'),
        backgroundColor: const Color(0xFF2E86AB),
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
              Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Upload PDF to Start', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Upload a PDF form. The system will try to detect its fillable fields.',
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

  Widget _buildEditorLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftPanel(),
        Expanded(
          flex: 2,
          child: _buildPdfViewerWithOverlays(),
        ),
        _buildRightPropertiesPanel(),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(children: [
              const Icon(Icons.data_object_rounded, color: Color(0xFF2E86AB)),
              const SizedBox(width: 8),
              Text('1. Select App Data', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(child: _buildAppDataFieldsList()),
        ],
      ),
    );
  }

  Widget _buildAppDataFieldsList() {
    final appState = context.read<AppStateProvider>();
    final availableProducts = appState.products;
    final customFields = appState.customAppDataFields; // Get custom fields

    // Use the enhanced method that includes custom fields
    final categorizedFields = PDFTemplate.getCategorizedQuoteFieldTypesWithCustomFields(
      availableProducts,
      customFields,
    );

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: categorizedFields.length,
      itemBuilder: (context, categoryIndex) {
        final categoryName = categorizedFields.keys.elementAt(categoryIndex);
        final categoryFields = categorizedFields[categoryName]!;
        return _buildCategorySection(categoryName, categoryFields);
      },
    );
  }

  Widget _buildCategorySection(String categoryName, List<String> fields) {
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${fields.length}',
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
        children: fields.map((appDataType) => _buildFieldListItem(appDataType)).toList(),
      ),
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

  Widget _buildPdfViewerWithOverlays() {
    if (_currentTemplate == null || _currentTemplate!.pdfFilePath.isEmpty) {
      return const Center(child: Text('No PDF loaded. Upload a template to begin.'));
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            key: _pdfViewerContainerKey,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.1 * 255).round()), blurRadius: 5, offset: const Offset(0,2))]
            ),
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints stackConstraints) {
                  final viewerWidth = stackConstraints.maxWidth;
                  final viewerHeight = stackConstraints.maxHeight;

                  List<Widget> stackChildren = [
                    SfPdfViewer.file(
                      File(_currentTemplate!.pdfFilePath),
                      controller: _pdfViewerController,
                      initialZoomLevel: 0,
                      onPageChanged: (details) {
                        if (!mounted) return;
                        setState(() {
                          _currentPageZeroBased = details.newPageNumber - 1;
                          if (_visuallySelectedPdfFieldInfo != null &&
                              (_visuallySelectedPdfFieldInfo!['page'] as int? ?? -1) != _currentPageZeroBased) {
                            _visuallySelectedPdfFieldInfo = null;
                          }
                        });
                      },
                      onTap: _handlePdfTap,
                    ),
                  ];

                  if (_visuallySelectedPdfFieldInfo != null &&
                      _currentTemplate != null &&
                      (_visuallySelectedPdfFieldInfo!['page'] as int? ?? -1) == _currentPageZeroBased) {

                    final pdfPageNativeWidth = _currentTemplate!.pageWidth;
                    final pdfPageNativeHeight = _currentTemplate!.pageHeight;

                    if (pdfPageNativeWidth > 0 && pdfPageNativeHeight > 0 && viewerWidth > 0 && viewerHeight > 0) {
                      double scaleToFitWidth = viewerWidth / pdfPageNativeWidth;
                      double scaleToFitHeight = viewerHeight / pdfPageNativeHeight;
                      double initialFitScale = scaleToFitWidth < scaleToFitHeight ? scaleToFitWidth : scaleToFitHeight;
                      final double effectiveScale = initialFitScale * _currentViewerZoomLevel;
                      final double displayedPdfWidth = pdfPageNativeWidth * effectiveScale;
                      final double displayedPdfHeight = pdfPageNativeHeight * effectiveScale;
                      final double pageRenderOffsetX = ((viewerWidth - displayedPdfWidth) / 2) - _currentViewerScrollOffset.dx;
                      final double pageRenderOffsetY = ((viewerHeight - displayedPdfHeight) / 2) - _currentViewerScrollOffset.dy;

                      final fieldInfo = _visuallySelectedPdfFieldInfo!;
                      final pdfRectValues = fieldInfo['rect'] as List<dynamic>?;
                      if (pdfRectValues != null && pdfRectValues.length == 4) {
                        final pdfFieldLeftOnPage = (pdfRectValues[0] as num).toDouble();
                        final pdfFieldTopOnPage = (pdfRectValues[1] as num).toDouble();
                        final pdfFieldWidthOnPage = (pdfRectValues[2] as num).toDouble();
                        final pdfFieldHeightOnPage = (pdfRectValues[3] as num).toDouble();

                        final screenLeft = pageRenderOffsetX + (pdfFieldLeftOnPage * effectiveScale);
                        final screenTop = pageRenderOffsetY + (pdfFieldTopOnPage * effectiveScale);
                        final screenWidth = pdfFieldWidthOnPage * effectiveScale;
                        final screenHeight = pdfFieldHeightOnPage * effectiveScale;

                        final double finalScreenWidth = screenWidth.isFinite && screenWidth > 0 ? screenWidth : 1.0;
                        final double finalScreenHeight = screenHeight.isFinite && screenHeight > 0 ? screenHeight : 1.0;

                        stackChildren.add(
                            Positioned(
                              left: screenLeft,
                              top: screenTop,
                              width: finalScreenWidth,
                              height: finalScreenHeight,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.redAccent.shade400, width: 2.0),
                                    color: Colors.redAccent.withAlpha((0.20 * 255).round()),
                                  ),
                                ),
                              ),
                            )
                        );
                      }
                    }
                  }
                  return Stack(children: stackChildren);
                }
            ),
          ),
        ),
        if (_totalPagesInPdf > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.first_page),tooltip: "First Page", iconSize: 20, onPressed: _currentPageZeroBased > 0 ? () => _pdfViewerController.jumpToPage(1) : null),
                IconButton(icon: const Icon(Icons.chevron_left),tooltip: "Previous Page", iconSize: 20, onPressed: _currentPageZeroBased > 0 ? () => _pdfViewerController.previousPage() : null),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Page ${_currentPageZeroBased + 1} of $_totalPagesInPdf', style: const TextStyle(fontSize: 13)),
                ),
                IconButton(icon: const Icon(Icons.chevron_right),tooltip: "Next Page", iconSize: 20, onPressed: _currentPageZeroBased < _totalPagesInPdf - 1 ? () => _pdfViewerController.nextPage() : null),
                IconButton(icon: const Icon(Icons.last_page),tooltip: "Last Page", iconSize: 20, onPressed: _currentPageZeroBased < _totalPagesInPdf - 1 ? () => _pdfViewerController.jumpToPage(_totalPagesInPdf) : null),
              ],
            ),
          )
      ],
    );
  }

  String _getMappedFieldSubtitle(FieldMapping mapping) {
    String baseText = 'Linked: ${mapping.pdfFormFieldName}';
    if (mapping.overrideValueEnabled && mapping.defaultValue != null && mapping.defaultValue!.isNotEmpty) {
      // Using a visually distinct separator like " | " might be better than \n if space is tight.
      // For now, \n is fine.
      return '$baseText\nOverride: "${mapping.defaultValue}"';
    }
    return baseText;
  }

  Widget _buildFieldListItem(String appDataType) {
    final appState = context.read<AppStateProvider>();
    FieldMapping existingMapping;
    try {
      existingMapping = _currentTemplate!.fieldMappings.firstWhere((m) => m.appDataType == appDataType);
    } catch (e) {
      existingMapping = FieldMapping(appDataType: appDataType, pdfFormFieldName: '', overrideValueEnabled: false);
    }

    final bool isMapped = existingMapping.pdfFormFieldName.isNotEmpty;
    final bool isCurrentlySelectedForMapping = _currentlySelectedAppFieldMapping?.appDataType == appDataType;

    bool hasOverrideInfo = isMapped &&
        existingMapping.overrideValueEnabled &&
        existingMapping.defaultValue != null &&
        existingMapping.defaultValue!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: isCurrentlySelectedForMapping ? 2 : 0,
        color: isCurrentlySelectedForMapping
            ? Colors.blue.shade50
            : (isMapped ? Colors.teal.withOpacity(0.05) : Colors.white),
        shape: isCurrentlySelectedForMapping
            ? RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(4)
        )
            : null,
        child: ListTile(
          dense: true,
          isThreeLine: hasOverrideInfo, // Adjust for potentially longer subtitle
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isMapped ? Colors.teal.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isMapped ? Icons.link : Icons.radio_button_unchecked,
              size: 16,
              color: isMapped ? Colors.teal.shade600 : Colors.grey.shade600,
            ),
          ),
          title: Text(
            PDFTemplate.getFieldDisplayName(appDataType, appState.customAppDataFields),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrentlySelectedForMapping ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: isMapped
              ? Text(
            _getMappedFieldSubtitle(existingMapping), // Use helper
            style: TextStyle(fontSize: 10, color: Colors.teal.shade700),
            maxLines: hasOverrideInfo ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          )
              : Text(
            _getFieldHint(appDataType),
            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Colors.grey[400],
          ),
          onTap: () => _handleAppDataFieldSelection(appDataType),
        ),
      ),
    );
  }


  void _handlePdfTap(PdfGestureDetails details) {
    if (_currentTemplate == null || !mounted || details.pageNumber < 1) {
      if (kDebugMode) print("PDF Tap: Pre-conditions not met.");
      return;
    }

    final int tappedPageIndexZeroBased = details.pageNumber - 1;
    final Offset tapInPdfPageCoords = details.pagePosition;

    if (kDebugMode) {
      print("PDF Tap Received: Page ${tappedPageIndexZeroBased + 1}, PDF Coords: $tapInPdfPageCoords, Screen Coords: ${details.position}");
    }

    Map<String, dynamic>? tappedFieldInfoFromLoop;

    for (final fieldInfo in _detectedPdfFieldsList) {
      if ((fieldInfo['page'] as int? ?? -1) != tappedPageIndexZeroBased) continue;

      final List<dynamic>? pdfRectValues = fieldInfo['rect'] as List<dynamic>?;
      if (pdfRectValues == null || pdfRectValues.length != 4) {
        if (kDebugMode) print("Skipping field ${(fieldInfo['name'] as String?) ?? 'Unnamed'} due to invalid 'rect' data.");
        continue;
      }

      final Rect fieldPdfBounds = Rect.fromLTWH(
        (pdfRectValues[0] as num).toDouble(), (pdfRectValues[1] as num).toDouble(),
        (pdfRectValues[2] as num).toDouble(), (pdfRectValues[3] as num).toDouble(),
      );

      if (fieldPdfBounds.contains(tapInPdfPageCoords)) {
        tappedFieldInfoFromLoop = fieldInfo;
        if (kDebugMode) print("PDF Tap HIT on field: ${(tappedFieldInfoFromLoop['name'] as String?) ?? 'Unnamed'} with bounds: $fieldPdfBounds");
        break;
      }
    }

    if (!mounted) return;

    if (tappedFieldInfoFromLoop != null) {
      final Map<String, dynamic> finalTappedFieldInfo = tappedFieldInfoFromLoop;
      final String tappedFieldName = (finalTappedFieldInfo['name'] as String?) ?? 'UnknownField';

      if (kDebugMode) print("Setting _visuallySelectedPdfFieldInfo to: $tappedFieldName");

      setState(() {
        _visuallySelectedPdfFieldInfo = finalTappedFieldInfo;

        if (_currentlySelectedAppFieldMapping != null) {
          if (kDebugMode) print("App Data '${_currentlySelectedAppFieldMapping!.appDataType}' was primed. Right panel should offer to link with '$tappedFieldName'.");
        } else {
          try {
            _currentlySelectedAppFieldMapping = _currentTemplate!.fieldMappings.firstWhere(
                    (m) => m.pdfFormFieldName == tappedFieldName
            );
            if (kDebugMode) print("Tapped PDF field '$tappedFieldName' is already mapped to App Data '${_currentlySelectedAppFieldMapping?.appDataType}'.");
          } catch (e) {
            _currentlySelectedAppFieldMapping = null;
            if (kDebugMode) print("Tapped PDF field '$tappedFieldName' is not currently mapped to any App Data.");
          }
        }
      });
    } else {
      if (kDebugMode) print("PDF Tap MISS on page ${tappedPageIndexZeroBased +1}. Clearing visual selection.");
      setState(() {
        _visuallySelectedPdfFieldInfo = null;
      });
    }
  }

  Widget _buildRightPropertiesPanel() {
    String title = "Field Linking & Properties";
    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.ads_click_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("How to Map:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("1. Select an 'App Data' field from the list on the left.", textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text("2. Then, TAP on a field area in the PDF preview to link them.", textAlign: TextAlign.center),
        ],
      ),
    );

    FieldMapping? mappingToDisplay;

    if (_currentlySelectedAppFieldMapping != null) {
      mappingToDisplay = _currentlySelectedAppFieldMapping;
      title = "Map: ${PDFTemplate.getFieldDisplayName(mappingToDisplay!.appDataType)}";
    } else if (_visuallySelectedPdfFieldInfo != null) {
      title = "Selected PDF Field: ${_visuallySelectedPdfFieldInfo!['name']}";
      try {
        mappingToDisplay = _currentTemplate!.fieldMappings.firstWhere(
                (m) => m.pdfFormFieldName == _visuallySelectedPdfFieldInfo!['name']
        );
        if (_currentlySelectedAppFieldMapping?.appDataType != mappingToDisplay.appDataType) {
          Future.microtask(() => setState(() => _currentlySelectedAppFieldMapping = mappingToDisplay));
        }
      } catch (e) {
        content = _buildSelectedPdfFieldInfoPanelContent();
      }
    }

    if (mappingToDisplay != null) {
      content = _buildMappingPropertiesPanelContent(mappingToDisplay);
    }

    return Container(
      width: 320,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: Colors.grey.shade300))
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tune, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.clear, size: 20), tooltip: "Clear Selections", onPressed: _clearAllSelections)
          ]),
          const Divider(),
          Expanded(child: SingleChildScrollView(child: content)),
        ],
      ),
    );
  }

  Widget _buildSelectedPdfFieldInfoPanelContent() {
    if (_visuallySelectedPdfFieldInfo == null) return const SizedBox.shrink();
    final pdfFieldInfo = _visuallySelectedPdfFieldInfo!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PDF Field Name:", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(pdfFieldInfo['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Detected Type:", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text((pdfFieldInfo['type'] as String).split('.').last, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text("On Page:", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text("${(pdfFieldInfo['page'] as int) + 1}", style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          Card(
            elevation: 0, color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("This PDF field is not currently linked. Select an 'App Data' field from the left panel, then click this PDF field again on the preview (or its highlight) to confirm the link.", style: TextStyle(color: Colors.blue.shade900)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMappingPropertiesPanelContent(FieldMapping mapping) {
    final bool isFullyMapped = mapping.pdfFormFieldName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("App Data Source: ${PDFTemplate.getFieldDisplayName(mapping.appDataType)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),

          if (isFullyMapped)
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Linked to PDF Field:", style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                    Text(mapping.pdfFormFieldName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 15)),
                    Text("PDF Field Type: ${mapping.detectedPdfFieldType.toString().split('.').last}", style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                    Text("On Page: ${mapping.pageNumber + 1}", style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                  ],
                ),
              ),
            )
          else if (_visuallySelectedPdfFieldInfo != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ready to link with PDF Field:", style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                Text(
                    (_visuallySelectedPdfFieldInfo!['name'] as String?) ?? 'Unknown PDF Field',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 15)
                ),
                Text(
                    "Type: ${((_visuallySelectedPdfFieldInfo!['type'] as String?) ?? 'Unknown').split('.').last}, Page: ${((_visuallySelectedPdfFieldInfo!['page'] as int?) ?? 0) + 1}",
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700)
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Confirm Link Now'),
                    onPressed: _confirmAndCreateMapping,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            )
          else
            Card(
              elevation:0, color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text("Now, tap on a field in the PDF preview to link it with '${PDFTemplate.getFieldDisplayName(mapping.appDataType)}'.", style: TextStyle(color: Colors.amber.shade900)),
              ),
            ),

          const SizedBox(height: 24),
          Text("Override Value Settings", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable Override Value'),
            value: mapping.overrideValueEnabled,
            onChanged: (bool value) {
              if (!mounted) return;
              setState(() {
                mapping.overrideValueEnabled = value;
                _currentTemplate?.updateField(mapping);
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('${mapping.fieldId}_overrideValue'), // Changed key
            initialValue: mapping.defaultValue ?? '', // Internal field name is still defaultValue
            decoration: const InputDecoration(
              labelText: 'Override Value (for App Data)', // UI Label changed
              border: OutlineInputBorder(),
              hintText: 'This value will be used if override is enabled',
              prefixIcon: Icon(Icons.drive_file_rename_outline),
            ),
            // enabled: mapping.overrideValueEnabled, // Optional: only enable if switch is on
            onChanged: (value) {
              if (!mounted) return;
              mapping.defaultValue = value.isEmpty ? null : value;
              _currentTemplate?.updateField(mapping);
            },
          ),
          const SizedBox(height: 20),

          if (isFullyMapped)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _unlinkField(mapping),
                icon: const Icon(Icons.link_off),
                label: const Text('Unlink This Mapping'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade700, side: BorderSide(color: Colors.orange.shade300)),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmAndCreateMapping() {
    if (_currentlySelectedAppFieldMapping == null || _visuallySelectedPdfFieldInfo == null || _currentTemplate == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select App Data and tap a PDF field to link.")));
      return;
    }

    final FieldMapping appDataMappingInProgress = _currentlySelectedAppFieldMapping!;
    final String appDataTypeToMap = appDataMappingInProgress.appDataType;
    final Map<String, dynamic> pdfFieldToMapInfo = _visuallySelectedPdfFieldInfo!;
    final String targetPdfFieldName = pdfFieldToMapInfo['name'] as String;

    if (kDebugMode) print("Attempting to link App Data '$appDataTypeToMap' to PDF Field '$targetPdfFieldName'");

    FieldMapping? existingMappingForTargetPdfField;
    for (int i = 0; i < _currentTemplate!.fieldMappings.length; i++) {
      if (_currentTemplate!.fieldMappings[i].pdfFormFieldName == targetPdfFieldName) {
        existingMappingForTargetPdfField = _currentTemplate!.fieldMappings[i];
        break;
      }
    }

    if (existingMappingForTargetPdfField != null && existingMappingForTargetPdfField.appDataType != appDataTypeToMap) {
      if (existingMappingForTargetPdfField.appDataType.startsWith('unmapped_')) {
        if (kDebugMode) print("Target PDF field '$targetPdfFieldName' was a placeholder. Overwriting.");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("PDF field '$targetPdfFieldName' is already linked to App Data: '${PDFTemplate.getFieldDisplayName(existingMappingForTargetPdfField.appDataType)}'. Unlink it first."),
            backgroundColor: Colors.orange, duration: const Duration(seconds: 5),
          ));
        }
        return;
      }
    }

    if (appDataMappingInProgress.pdfFormFieldName.isNotEmpty && appDataMappingInProgress.pdfFormFieldName != targetPdfFieldName) {
      if (kDebugMode) print("App Data '$appDataTypeToMap' was previously linked to '${appDataMappingInProgress.pdfFormFieldName}'. Relinking to '$targetPdfFieldName'.");
    }

    if (!mounted) return;
    setState(() {
      appDataMappingInProgress.pdfFormFieldName = targetPdfFieldName;
      appDataMappingInProgress.detectedPdfFieldType = PdfFormFieldType.values.firstWhere(
              (e) => e.toString() == pdfFieldToMapInfo['type'], orElse: () => PdfFormFieldType.UNKNOWN);
      appDataMappingInProgress.pageNumber = pdfFieldToMapInfo['page'] as int;

      final relRect = pdfFieldToMapInfo['relativeRect'] as List<dynamic>?;
      if (relRect != null && relRect.length == 4) {
        appDataMappingInProgress.visualX = relRect[0] as double?;
        appDataMappingInProgress.visualY = relRect[1] as double?;
        appDataMappingInProgress.visualWidth = relRect[2] as double?;
        appDataMappingInProgress.visualHeight = relRect[3] as double?;
      }

      final int currentIndex = _currentTemplate!.fieldMappings.indexWhere((fm) => fm.appDataType == appDataTypeToMap);
      if (currentIndex != -1) {
        _currentTemplate!.fieldMappings[currentIndex] = appDataMappingInProgress;
      } else {
        _currentTemplate!.addField(appDataMappingInProgress);
      }

      if (existingMappingForTargetPdfField != null &&
          existingMappingForTargetPdfField.appDataType.startsWith('unmapped_') &&
          existingMappingForTargetPdfField.appDataType != appDataTypeToMap) {
        final String fieldIdToRemove = existingMappingForTargetPdfField.fieldId;
        _currentTemplate!.fieldMappings.removeWhere((fm) => fm.fieldId == fieldIdToRemove);
        if (kDebugMode) print("Removed placeholder mapping for PDF field '$targetPdfFieldName'.");
      }

      _currentTemplate!.updatedAt = DateTime.now();
      _currentlySelectedAppFieldMapping = appDataMappingInProgress;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Linked App Data '${PDFTemplate.getFieldDisplayName(appDataTypeToMap)}' to PDF Field '$targetPdfFieldName'"),
      backgroundColor: Colors.green,
    ));
  }

  void _handleAppDataFieldSelection(String appDataType) {
    if (_currentTemplate == null) return;
    FieldMapping mapping;
    final existingMappingIndex = _currentTemplate!.fieldMappings.indexWhere((m) => m.appDataType == appDataType);

    if (existingMappingIndex != -1) {
      mapping = _currentTemplate!.fieldMappings[existingMappingIndex];
    } else {
      mapping = FieldMapping(
        appDataType: appDataType,
        pdfFormFieldName: '',
        detectedPdfFieldType: PdfFormFieldType.UNKNOWN,
        pageNumber: _currentPageZeroBased,
        overrideValueEnabled: false, // Ensure new mappings have this default
      );
      _currentTemplate!.addField(mapping);
    }

    if (!mounted) return;
    setState(() {
      _currentlySelectedAppFieldMapping = mapping;

      if (mapping.pdfFormFieldName.isNotEmpty) {
        final detectedInfo = _detectedPdfFieldsList.firstWhere(
                (info) => info['name'] == mapping.pdfFormFieldName,
            orElse: () => <String,dynamic>{}
        );
        if(detectedInfo.isNotEmpty) {
          _visuallySelectedPdfFieldInfo = detectedInfo;
          if (mounted && (detectedInfo['page'] as int? ?? 0) != _currentPageZeroBased) {
            _pdfViewerController.jumpToPage((detectedInfo['page'] as int? ?? 0) + 1);
          }
        } else {
          _visuallySelectedPdfFieldInfo = null;
        }
      } else {
        _visuallySelectedPdfFieldInfo = null;
      }
    });
  }

  void _unlinkField(FieldMapping mapping) {
    if (!mounted) return;
    final unlinkedPdfFieldName = mapping.pdfFormFieldName;
    setState(() {
      mapping.pdfFormFieldName = '';
      mapping.detectedPdfFieldType = PdfFormFieldType.UNKNOWN;
      mapping.visualX = null;
      mapping.visualY = null;
      mapping.visualWidth = null;
      mapping.visualHeight = null;
      // Keep mapping.defaultValue and mapping.overrideValueEnabled as they are app-data specific, not PDF-link specific
      _currentTemplate!.updateField(mapping);
      _currentlySelectedAppFieldMapping = mapping; // Keep it selected to see its override settings
      if (_visuallySelectedPdfFieldInfo != null && _visuallySelectedPdfFieldInfo!['name'] == unlinkedPdfFieldName) {
        _visuallySelectedPdfFieldInfo = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Field mapping removed. Override settings (if any) are preserved for this App Data type."),
      backgroundColor: Colors.orange,
    ));
  }

  Future<void> _uploadAndCreateTemplate() async {
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
          final appState = context.read<AppStateProvider>();
          await appState.addExistingPDFTemplateToList(template); // This adds to memory, not DB again

          setState(() {
            _currentTemplate = template; // Use the instance returned by createTemplateFromPDF
            _loadTemplateDetails();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Template created!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2)
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to create template.'),
                backgroundColor: Colors.red
            ),
          );
        }
      }
    } catch (e) {
      _setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red
        ),
      );
      if (kDebugMode) print("Error uploading/creating template: $e");
    }
  }


  void _saveTemplate() async {
    if (_currentTemplate == null) {
      if (kDebugMode) print('❌ No template to save');
      return;
    }
    if (!mounted) return;

    if (kDebugMode) {
      print('💾 Starting save for template: ${_currentTemplate!.templateName}');
      print('📍 Template ID: ${_currentTemplate!.id}');
      print('📍 Field mappings: ${_currentTemplate!.fieldMappings.length}');
      for(var fm in _currentTemplate!.fieldMappings) {
        print('   - ${fm.appDataType}: PDF=${fm.pdfFormFieldName}, OverrideEnabled=${fm.overrideValueEnabled}, OverrideVal=${fm.defaultValue}');
      }
    }


    try {
      _currentTemplate!.updatedAt = DateTime.now();
      final appState = context.read<AppStateProvider>();
      await appState.updatePDFTemplate(_currentTemplate!); // This saves to DB

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      if (kDebugMode) print('❌ Error saving template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _previewTemplate() async {
    if (_currentTemplate == null) return;
    _setLoading(true, 'Generating preview...');
    try {
      final previewPath = await TemplateService.instance.generateTemplatePreview(_currentTemplate!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preview PDF generated: ${previewPath.split('/').last}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'Open', onPressed: () => OpenFilex.open(previewPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating preview: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      _setLoading(false);
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
                    const SnackBar(content: Text("Template name cannot be empty."))
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