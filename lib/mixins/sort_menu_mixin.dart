import 'package:flutter/material.dart';

mixin SortMenuMixin<T extends StatefulWidget> on State<T> {
  PopupMenuItem<String> buildSortMenuItem({
    required String label,
    required IconData icon,
    required String value,
    required String currentSortBy,
    required bool sortAscending,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
          if (currentSortBy == value) ...[
            const Spacer(),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}
