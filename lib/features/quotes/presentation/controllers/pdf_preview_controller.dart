import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/providers/state/app_state_provider.dart';
import '../../../../core/services/pdf/pdf_field_mapping_service.dart';

class PdfPreviewController {
  PdfPreviewController(this.context);

  final BuildContext context;

  List<String> loadEditableFields(String templateId) {
    final appState = context.read<AppStateProvider>();
    return PdfFieldMappingService.instance.getEditableFields(templateId, appState);
  }
}
