import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/models/templates/email_template.dart';
import '../../../../../data/providers/state/app_state_provider.dart';
import '../dialogs/email_template_editor.dart';
import '../../../../../core/mixins/template_tab_mixin.dart';
import '../../controllers/email_template_operations_controller.dart';
import '../email_template_components/email_template_tile.dart';

/// Refactored EmailTemplatesTab with extracted controllers and components
/// Original 504-line monolithic widget broken down into manageable components
/// All original functionality preserved with improved maintainability
class EmailTemplatesTab extends StatefulWidget {
  const EmailTemplatesTab({super.key});

  @override
  State<EmailTemplatesTab> createState() => _EmailTemplatesTabState();
}

class _EmailTemplatesTabState extends State<EmailTemplatesTab> with TemplateTabMixin {
  late EmailTemplateOperationsController _operationsController;

  @override
  void initState() {
    super.initState();
    _operationsController = EmailTemplateOperationsController(context);
  }

  // Implement required mixin properties
  @override
  Color get primaryColor => Colors.orange;

  @override
  String get itemTypeName => 'template';

  @override
  String get itemTypePlural => 'templates';

  @override
  IconData get tabIcon => Icons.email;

  @override
  String get searchHintText => 'Search email templates...';

  @override
  String get categoryType => 'email_templates';



  // Implement required data methods
  @override
  List<dynamic> getAllItems() {
    return context.read<AppStateProvider>().emailTemplates;
  }

  @override
  List<dynamic> getFilteredItems() {
    var filtered = getAllItems().cast<EmailTemplate>();

    // Always exclude templates without valid categories
    filtered = filtered.where((t) =>
    t.userCategoryKey != null &&
        t.userCategoryKey!.isNotEmpty
    ).toList();

    // Then filter by selected category if not 'all'
    if (selectedCategory != 'all') {
      filtered = filtered.where((t) => t.userCategoryKey == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
      t.templateName.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q) ||
          t.emailContent.toLowerCase().contains(q)).toList();
    }

    // Sort by sortOrder if available, otherwise by name
    return filtered..sort((a, b) {
      try {
        return a.sortOrder.compareTo(b.sortOrder);
      } catch (e) {
        return a.templateName.compareTo(b.templateName);
      }
    });
  }

  @override
  Future<void> deleteItemById(String id) async {
    await context.read<AppStateProvider>().deleteEmailTemplate(id);
  }

  @override
  String getItemId(dynamic item) {
    return (item as EmailTemplate).id;
  }

  @override
  String getItemDisplayName(dynamic item) {
    return (item as EmailTemplate).templateName;
  }

  // Implement required UI/navigation methods
  @override
  void navigateToEditor([dynamic existingItem]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailTemplateEditorScreen(
          existingTemplate: existingItem as EmailTemplate?,
        ),
      ),
    );
  }

  @override
  Widget buildItemTile(dynamic item, bool isSelected, bool isSmallScreen, bool isVerySmall) {
    final template = item as EmailTemplate;

    return EmailTemplateTile(
      template: template,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      isVerySmall: isVerySmall,
      primaryColor: primaryColor,
      tabIcon: tabIcon,
      onTap: isSelectionMode
          ? () => toggleSelection(getItemId(template))
          : () => navigateToEditor(template),
      onAction: (action, template) => _operationsController.handleTemplateAction(
        action,
        template,
        onEdit: () => navigateToEditor(template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return buildMainLayout(); // This comes from the mixin!
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}