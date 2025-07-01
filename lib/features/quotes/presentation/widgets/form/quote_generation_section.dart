// lib/widgets/quote_form/quote_generation_section.dart

import 'package:flutter/material.dart';

import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../data/models/business/simplified_quote.dart';
import '../../../../../shared/widgets/buttons/rufko_buttons.dart';

class QuoteGenerationSection extends StatelessWidget
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin {
  final bool isEditMode;
  final String quoteType;
  final List<QuoteLevel> quoteLevels;
  final bool permitsSatisfied;
  final bool hasChanges;
  final VoidCallback onGenerate;

  const QuoteGenerationSection({
    super.key,
    required this.isEditMode,
    required this.quoteType,
    required this.quoteLevels,
    required this.permitsSatisfied,
    required this.hasChanges,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (quoteLevels.isEmpty) return const SizedBox.shrink();

    String buttonText = isEditMode
        ? (quoteType == 'single-tier'
            ? 'Update Quote'
            : 'Update Quote')
        : (quoteType == 'single-tier'
            ? 'Generate Quote'
            : 'Generate Quote');

    return Column(
      children: [
        if (!permitsSatisfied) ...[
          Container(
            padding: EdgeInsets.all(spacingSM(context) * 3),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                SizedBox(width: spacingSM(context) * 2),
                Expanded(
                  child: Text(
                    'Permits required: Please add permits or check "No permits required"',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacingXL(context)),
        ],
        if (isEditMode && !hasChanges) ...[
          Container(
            padding: EdgeInsets.all(spacingSM(context) * 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600),
                SizedBox(width: spacingSM(context) * 2),
                Expanded(
                  child: Text(
                    'No changes detected. Make changes to enable updating.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacingXL(context)),
        ],
        const Divider(),
        SizedBox(height: spacingMD(context)),
        RufkoPrimaryButton(
          onPressed: (permitsSatisfied && (!isEditMode || hasChanges)) ? onGenerate : null,
          icon: isEditMode ? Icons.save : Icons.description,
          isFullWidth: true,
          size: ButtonSize.large,
          child: Text(buttonText),
        ),
      ],
    );
  }
}
