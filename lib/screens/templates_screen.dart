import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/template_navigation_handler.dart';
import '../services/category_management_service.dart';
import '../services/template_creation_service.dart';
import '../widgets/templates/template_app_bar.dart';
import '../widgets/templates/floating_action_buttons/template_fab_manager.dart';
import '../widgets/templates/fields_tab.dart';
import '../widgets/templates/pdf_templates_tab.dart';
import '../widgets/templates/message_templates_tab.dart';
import '../widgets/templates/email_templates_tab.dart';
import '../widgets/common/error_snackbar.dart';
import '../state/templates_screen_state.dart';
import '../widgets/templates/dialgos/message_template_editor.dart';
import '../widgets/templates/dialgos/email_template_editor.dart';
import '../widgets/templates/dialgos/field_dialog.dart';
import '../providers/app_state_provider.dart';

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
              onCreatePdf: () =>
                  _creationService.createNewPDFTemplate(context).catchError(
                        (e) => showErrorSnackBar(context, '$e'),
                      ),
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
              onCreateField: () {
                FieldDialog.showAdd(context).then((newField) {
                  if (newField != null && mounted) {
                    final appState = context.read<AppStateProvider>();
                    appState.addCustomAppDataField(newField).catchError((e) {
                      if (mounted) {
                        showErrorSnackBar(context, '$e');
                      }
                    });
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}
