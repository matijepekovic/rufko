import 'package:flutter/material.dart';
import '../../app/theme/rufko_theme.dart';

/// UI-only search bar component with always-visible search field and action buttons
/// Contains ZERO filtering logic - only handles visual presentation
class AlwaysVisibleSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final List<Widget>? actionButtons;
  final bool showBottomBorder;

  const AlwaysVisibleSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.actionButtons,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: showBottomBorder 
            ? const Border(bottom: BorderSide(color: RufkoTheme.strokeColor))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: RufkoTheme.strokeColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: RufkoTheme.strokeColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: onChanged,
            ),
          ),
          if (actionButtons != null) ...[
            const SizedBox(width: 12),
            ...actionButtons!,
          ],
        ],
      ),
    );
  }
}

/// UI-only chip filter row component
/// Contains ZERO filtering logic - only handles visual presentation and selection callbacks
class ChipFilterRow extends StatefulWidget {
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const ChipFilterRow({
    super.key,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  State<ChipFilterRow> createState() => _ChipFilterRowState();
}

class _ChipFilterRowState extends State<ChipFilterRow> {
  late ScrollController _scrollController;
  final List<GlobalKey> _chipKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _chipKeys.addAll(widget.filterOptions.map((_) => GlobalKey()));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedChip(String selectedFilter) {
    final selectedIndex = widget.filterOptions.indexOf(selectedFilter);
    if (selectedIndex == -1 || selectedIndex >= _chipKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _chipKeys[selectedIndex].currentContext;
      if (keyContext != null) {
        final RenderBox renderBox = keyContext.findRenderObject() as RenderBox;
        final chipPosition = renderBox.localToGlobal(Offset.zero);
        final chipWidth = renderBox.size.width;
        
        final scrollViewWidth = _scrollController.position.viewportDimension;
        final currentScrollOffset = _scrollController.offset;
        
        // Calculate position to center the chip
        final targetScrollOffset = (chipPosition.dx + chipWidth / 2) - (scrollViewWidth / 2) + currentScrollOffset;
        
        _scrollController.animateTo(
          targetScrollOffset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: RufkoTheme.strokeColor)),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: widget.filterOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final filter = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: _chipKeys[index],
                label: Text(filter),
                selected: widget.selectedFilter == filter,
                onSelected: (selected) {
                  if (selected) {
                    widget.onFilterSelected(filter);
                    _scrollToSelectedChip(filter);
                  }
                },
                backgroundColor: Colors.grey[100],
                selectedColor: RufkoTheme.primaryColor.withValues(alpha: 0.1),
                checkmarkColor: RufkoTheme.primaryColor,
                labelStyle: TextStyle(
                  color: widget.selectedFilter == filter 
                      ? RufkoTheme.primaryColor 
                      : Colors.grey[700],
                  fontWeight: widget.selectedFilter == filter 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
                side: BorderSide(
                  color: widget.selectedFilter == filter 
                      ? RufkoTheme.primaryColor 
                      : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}