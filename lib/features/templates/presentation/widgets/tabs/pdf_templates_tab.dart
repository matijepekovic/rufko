import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/templates/pdf_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../../controllers/pdf_template_actions_controller.dart';
import '../../../../../app/theme/rufko_theme.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';
import '../pdf_template/pdf_template_tile.dart';
import '../pdf_template/pdf_template_error_handler.dart';

/// Refactored PdfTemplatesTab with extracted components and controller
/// Original 607-line monolithic tab broken down into manageable components
/// All original functionality preserved with improved maintainability
class PdfTemplatesTab extends StatefulWidget {
  const PdfTemplatesTab({super.key});

  @override
  State<PdfTemplatesTab> createState() => _PdfTemplatesTabState();
}

class _PdfTemplatesTabState extends State<PdfTemplatesTab> with TemplateTabMixin {
  late PdfTemplateActionsController _actionsController;

  @override
  void initState() {
    super.initState();
    _actionsController = PdfTemplateActionsController(context: context);
  }

  @override
  void dispose() {
    _actionsController.dispose();
    super.dispose();
  }

  // Implement required mixin properties
  @override
  Color get primaryColor => RufkoTheme.primaryColor;

  @override
  String get itemTypeName => 'template';

  @override
  String get itemTypePlural => 'templates';

  @override
  IconData get tabIcon => Icons.description;

  @override
  String get searchHintText => 'Search PDF templates...';

  @override
  String get categoryType => 'pdf_templates';

  // Implement required data methods
  @override
  List<dynamic> getAllItems() {
    return context.read<AppStateProvider>().pdfTemplates;
  }

  @override
  List<dynamic> getFilteredItems() {
    var filtered = getAllItems().cast<PDFTemplate>();

    if (selectedCategory != 'all') {
      filtered = filtered.where((t) => t.userCategoryKey == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
      t.templateName.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.templateType.toLowerCase().contains(q)).toList();
    }

    return filtered..sort((a, b) => a.templateName.compareTo(b.templateName));
  }

  @override
  Future<void> deleteItemById(String id) async {
    await context.read<AppStateProvider>().deletePDFTemplate(id);
  }

  @override
  String getItemId(dynamic item) {
    return (item as PDFTemplate).id;
  }

  @override
  String getItemDisplayName(dynamic item) {
    return (item as PDFTemplate).templateName;
  }

  // Implement required UI/navigation methods
  @override
  void navigateToEditor([dynamic existingItem]) {
    _actionsController.navigateToEditor(existingItem as PDFTemplate?);
  }

  @override
  Widget buildItemTile(dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final template = item as PDFTemplate;

    return PdfTemplateTile(
      template: template,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      isSmallScreen: isSmallScreen,
      isVerySmall: isVerySmall,
      primaryColor: primaryColor,
      onTap: isSelectionMode
          ? () => toggleSelection(getItemId(template))
          : () => navigateToEditor(template),
      onLongPress: !isSelectionMode ? () => _handlePreviewTemplate(template) : null,
      onActionSelected: (action) => _handleTemplateAction(action, template),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Column(
          children: [
            // Error handler for controller errors
            ListenableBuilder(
              listenable: _actionsController,
              builder: (context, child) {
                return PdfTemplateErrorHandler(
                  error: _actionsController.error,
                  onClearError: _actionsController.clearError,
                );
              },
            ),
            
            // Main layout from mixin
            Expanded(
              child: buildMainLayout(),
            ),
          ],
        );
        // Note: No floating action button here - it's handled by templates_screen.dart
      },
    );
  }

  /// Handle template preview with controller
  Future<void> _handlePreviewTemplate(PDFTemplate template) async {
    await _actionsController.previewTemplate(template);
  }

  /// Handle template action through controller
  Future<void> _handleTemplateAction(String action, PDFTemplate template) async {
    await _actionsController.handleTemplateAction(action, template);
  }
}