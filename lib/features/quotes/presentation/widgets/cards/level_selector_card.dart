import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../data/models/business/simplified_quote.dart';

class LevelSelectorCard extends StatelessWidget {
  final List<QuoteLevel> levels;
  final String? selectedLevelId;
  final Function(String) onLevelSelected;
  final NumberFormat currencyFormat;
  final double Function(String) getTotalForLevel;

  const LevelSelectorCard({
    super.key,
    required this.levels,
    required this.selectedLevelId,
    required this.onLevelSelected,
    required this.currencyFormat,
    required this.getTotalForLevel,
  });

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.layers_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Quote Levels Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This quote doesn\'t have any configured levels.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectorHeader(context),
            const SizedBox(height: 16),
            _buildLevelChips(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.layers,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quote Levels (Preview)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Select a level to preview pricing • Use "Extract" to create final quote',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final isSelected = selectedLevelId == level.id;
        final total = getTotalForLevel(level.id);

        return ChoiceChip(
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(level.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(currencyFormat.format(total),
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : null)),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onLevelSelected(level.id);
            }
          },
          selectedColor: Theme.of(context).primaryColor,
          labelStyle:
              TextStyle(color: isSelected ? Colors.white : null),
        );
      }).toList(),
    );
  }
}
