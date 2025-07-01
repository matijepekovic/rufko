// lib/widgets/quote_type_selector.dart

import 'package:flutter/material.dart';
import '../../../../app/theme/rufko_theme.dart';

class QuoteTypeSelector extends StatelessWidget {
  final String quoteType;
  final Function(String) onQuoteTypeChanged;

  const QuoteTypeSelector({
    super.key,
    required this.quoteType,
    required this.onQuoteTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RufkoTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dashboard_customize,
                    color: RufkoTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Quote Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: RufkoTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onQuoteTypeChanged('multi-level'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: quoteType == 'multi-level'
                            ? RufkoTheme.primaryColor
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: quoteType == 'multi-level'
                              ? RufkoTheme.primaryColor
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.layers,
                            color: quoteType == 'multi-level'
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tiered Quote',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: quoteType == 'multi-level'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Builder/Homeowner/Platinum',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: quoteType == 'multi-level'
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onQuoteTypeChanged('single-tier'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: quoteType == 'single-tier'
                            ? RufkoTheme.primaryColor
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: quoteType == 'single-tier'
                              ? RufkoTheme.primaryColor
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description,
                            color: quoteType == 'single-tier'
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Single Quote',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: quoteType == 'single-tier'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'One price level',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: quoteType == 'single-tier'
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
