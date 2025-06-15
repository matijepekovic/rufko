import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/common/error_snackbar.dart';
import '../../../../data/providers/state/app_state_provider.dart';
import '../widgets/dialogs/field_dialog.dart';

class TemplatesScreenController {
  TemplatesScreenController(this.context);

  final BuildContext context;

  AppStateProvider get _appState => context.read<AppStateProvider>();

  Future<void> addCustomField() async {
    final newField = await FieldDialog.showAdd(context);
    if (newField != null) {
      try {
        await _appState.addCustomAppDataField(newField);
      } catch (e) {
        if (context.mounted) {
          showErrorSnackBar(context, '$e');
        }
      }
    }
  }
}
