import 'package:flutter/material.dart';

/// Reusable field selection indicator widget
/// Shows selection state with checkbox-style indicator
class FieldSelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final bool isVerySmall;
  final Color primaryColor;

  const FieldSelectionIndicator({
    super.key,
    required this.isSelected,
    required this.isVerySmall,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isVerySmall ? 20 : 24,
      height: isVerySmall ? 20 : 24,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              color: Colors.white,
              size: isVerySmall ? 12 : 14,
            )
          : null,
    );
  }
}