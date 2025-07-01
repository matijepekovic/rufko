// lib/services/pdf_interaction_service.dart

import 'dart:ui';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfInteractionService {
  PdfInteractionService._internal();
  static final PdfInteractionService instance = PdfInteractionService._internal();

  /// Determine which detected PDF field was tapped, if any.
  Map<String, dynamic>? getTappedField(
    List<Map<String, dynamic>> detectedFields,
    int pageIndex,
    Offset tapPosition,
  ) {
    for (final field in detectedFields) {
      if ((field['page'] as int? ?? -1) != pageIndex) continue;
      final rectValues = field['rect'] as List<dynamic>?;
      if (rectValues == null || rectValues.length != 4) continue;
      final rect = Rect.fromLTWH(
        (rectValues[0] as num).toDouble(),
        (rectValues[1] as num).toDouble(),
        (rectValues[2] as num).toDouble(),
        (rectValues[3] as num).toDouble(),
      );
      if (rect.contains(tapPosition)) return field;
    }
    return null;
  }

  /// Keep [_currentPage] in sync with [controller] page changes.
  void attachPageListener(
    PdfViewerController controller,
    void Function(int pageIndex) onPageChanged,
  ) {
    controller.addListener(() {
      final page = controller.pageNumber;
      if (page > 0) {
        onPageChanged(page - 1);
      }
    });
  }
}
