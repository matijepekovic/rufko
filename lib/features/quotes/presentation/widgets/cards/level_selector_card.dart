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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No levels configured.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Quote Level:',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
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
            ),
          ],
        ),
      ),
    );
  }
}
