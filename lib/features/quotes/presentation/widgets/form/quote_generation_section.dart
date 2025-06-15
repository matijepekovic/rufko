// lib/widgets/quote_form/quote_generation_section.dart

import 'package:flutter/material.dart';

import '../../../../../core/mixins/ui/responsive_breakpoints_mixin.dart';
import '../../../../../core/mixins/ui/responsive_spacing_mixin.dart';
import '../../../../../data/models/business/simplified_quote.dart';

class QuoteGenerationSection extends StatelessWidget
    with ResponsiveBreakpointsMixin, ResponsiveSpacingMixin {
  final bool isEditMode;
  final String quoteType;
  final List<QuoteLevel> quoteLevels;
  final bool permitsSatisfied;
  final VoidCallback onGenerate;

  const QuoteGenerationSection({
    super.key,
    required this.isEditMode,
    required this.quoteType,
    required this.quoteLevels,
    required this.permitsSatisfied,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (quoteLevels.isEmpty) return const SizedBox.shrink();

    String buttonText = isEditMode
        ? (quoteType == 'single-tier'
            ? 'Update Single-Tier Quote'
            : 'Update Multi-Level Quote')
        : (quoteType == 'single-tier'
            ? 'Generate Single-Tier Quote'
            : 'Generate Multi-Level Quote');

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
        ElevatedButton.icon(
          onPressed: permitsSatisfied ? onGenerate : null,
          icon: Icon(isEditMode ? Icons.save : Icons.rocket_launch),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: permitsSatisfied
                ? (quoteType == 'single-tier'
                    ? Colors.green.shade600
                    : Theme.of(context).primaryColor)
                : Colors.grey,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: spacingXL(context)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
