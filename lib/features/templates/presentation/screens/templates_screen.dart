import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/navigation/template_navigation_handler.dart';
import '../../../../core/services/category_management_service.dart';
import '../../../../core/services/template_creation_service.dart';
import '../widgets/tabs/template_app_bar.dart';
import '../widgets/template_fab_manager.dart';
import '../widgets/tabs/fields_tab.dart';
import '../widgets/tabs/pdf_templates_tab.dart';
import '../widgets/tabs/message_templates_tab.dart';
import '../widgets/tabs/email_templates_tab.dart';
import '../../../../shared/widgets/common/error_snackbar.dart';
import '../../../../shared/state/templates_screen_state.dart';
import '../widgets/dialogs/message_template_editor.dart';
import '../widgets/dialogs/email_template_editor.dart';
import '../widgets/dialogs/field_dialog.dart';
import '../../../../data/providers/state/app_state_provider.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final TemplateCreationService _creationService;
  late final TemplateNavigationHandler _navigationHandler;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _navigationHandler = TemplateNavigationHandler();
    _creationService = TemplateCreationService(
      navigationHandler: _navigationHandler,
      categoryService: CategoryManagementService(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TemplatesScreenState(),
      child: Consumer<TemplatesScreenState>(
        builder: (context, state, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: NestedScrollView(
              headerSliverBuilder: (context, inner) => [
                TemplateAppBar(
                  controller: _tabController,
                  onSettings: () =>
                      _navigationHandler.openCategoryManagement(context),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: const [
                  PdfTemplatesTab(),
                  MessageTemplatesTab(),
                  EmailTemplatesTab(),
                  FieldsTab(),
                ],
              ),
            ),
            floatingActionButton: TemplateFabManager(
              controller: _tabController,
              onCreatePdf: () async {
                try {
                  await _creationService.createNewPDFTemplate(context);
                } catch (e) {
                  if (mounted) {
                    showErrorSnackBar(context, '$e');
                  }
                }
              },
              onCreateMessage: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessageTemplateEditorScreen(),
                ),
              ),
              onCreateEmail: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmailTemplateEditorScreen(),
                ),
              ),
              onCreateField: () async {
                final newField = await FieldDialog.showAdd(context);
                if (newField != null && mounted) {
                  final appState = context.read<AppStateProvider>();
                  try {
                    await appState.addCustomAppDataField(newField);
                  } catch (e) {
                    if (mounted) {
                      showErrorSnackBar(context, '$e');
                    }
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
