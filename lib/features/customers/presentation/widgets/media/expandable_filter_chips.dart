import 'package:flutter/material.dart';
import '../../controllers/media_tab_controller.dart';
import '../../../../../data/models/media/project_media.dart';
import '../../../../../core/services/media/media_processing_service.dart';

class ExpandableFilterChips extends StatefulWidget {
  final MediaFilter activeFilter;
  final List<ProjectMedia> allMedia;
  final Function(MediaFilter) onFilterChanged;

  const ExpandableFilterChips({
    super.key,
    required this.activeFilter,
    required this.allMedia,
    required this.onFilterChanged,
  });

  @override
  State<ExpandableFilterChips> createState() => _ExpandableFilterChipsState();
}

class _ExpandableFilterChipsState extends State<ExpandableFilterChips>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start expanded if a category filter is active
    final isBasicFilter = [MediaFilter.all, MediaFilter.photos, MediaFilter.documents].contains(widget.activeFilter);
    if (!isBasicFilter) {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        // If collapsing and a category filter is active, reset to 'all'
        final isBasicFilter = [MediaFilter.all, MediaFilter.photos, MediaFilter.documents].contains(widget.activeFilter);
        if (!isBasicFilter) {
          widget.onFilterChanged(MediaFilter.all);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.allMedia.length;
    final photosCount = widget.allMedia.where((item) => item.isImage).length;
    final documentsCount = widget.allMedia.where((item) => !item.isImage).length;

    return Column(
      children: [
        // Main filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCompactChip(
                context: context,
                filter: MediaFilter.all,
                label: 'All',
                count: totalCount,
                isActive: widget.activeFilter == MediaFilter.all,
              ),
              const SizedBox(width: 6),
              _buildCompactChip(
                context: context,
                filter: MediaFilter.photos,
                label: 'Photos',
                count: photosCount,
                isActive: widget.activeFilter == MediaFilter.photos,
              ),
              const SizedBox(width: 6),
              _buildCompactChip(
                context: context,
                filter: MediaFilter.documents,
                label: 'Docs',
                count: documentsCount,
                isActive: widget.activeFilter == MediaFilter.documents,
              ),
              const SizedBox(width: 6),
              _buildCategoriesToggle(context),
            ],
          ),
        ),
        
        // Expandable category chips
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: _buildCategoryChips(context),
        ),
      ],
    );
  }

  Widget _buildCompactChip({
    required BuildContext context,
    required MediaFilter filter,
    required String label,
    required int count,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => widget.onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoriesToggle(BuildContext context) {
    final isBasicFilter = [MediaFilter.all, MediaFilter.photos, MediaFilter.documents].contains(widget.activeFilter);
    final isCategoryActive = !isBasicFilter;
    
    return GestureDetector(
      onTap: _toggleExpansion,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: (_isExpanded || isCategoryActive)
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            Icons.expand_more,
            size: 20,
            color: (_isExpanded || isCategoryActive) ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    // Determine which categories to show based on active filter
    List<String> categories;
    bool showGroupedSections = false;
    
    switch (widget.activeFilter) {
      case MediaFilter.photos:
        categories = MediaProcessingService.getPhotoCategories();
        break;
      case MediaFilter.documents:
        categories = MediaProcessingService.getDocumentCategories();
        break;
      case MediaFilter.all:
        categories = MediaProcessingService.getCategories();
        showGroupedSections = true;
        break;
      default:
        // For specific category filters, don't show any subcategories
        return const SizedBox.shrink();
    }
    
    final availableCategories = categories.where((category) {
      final count = widget.allMedia.where((item) => item.category == category).length;
      return count > 0;
    }).toList();

    if (availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: showGroupedSections 
          ? _buildGroupedCategoryChips(context, availableCategories)
          : _buildSimpleCategoryChips(context, availableCategories),
    );
  }
  
  Widget _buildSimpleCategoryChips(BuildContext context, List<String> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final filter = MediaTabController.categoryToFilter(category);
        if (filter == null) return const SizedBox.shrink();
        
        final count = widget.allMedia.where((item) => item.category == category).length;
        final isActive = widget.activeFilter == filter;
        final label = MediaProcessingService.getFormattedCategoryName(category);
        
        return _buildCategoryChip(
          context: context,
          filter: filter,
          label: label,
          count: count,
          isActive: isActive,
        );
      }).toList(),
    );
  }
  
  Widget _buildGroupedCategoryChips(BuildContext context, List<String> categories) {
    final photoCategories = categories.where((cat) => MediaProcessingService.isPhotoCategory(cat)).toList();
    final documentCategories = categories.where((cat) => MediaProcessingService.isDocumentCategory(cat)).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo categories section
        if (photoCategories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.photo_camera, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Photo Categories',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photoCategories.map((category) {
              final filter = MediaTabController.categoryToFilter(category);
              if (filter == null) return const SizedBox.shrink();
              
              final count = widget.allMedia.where((item) => item.category == category).length;
              final isActive = widget.activeFilter == filter;
              final label = MediaProcessingService.getFormattedCategoryName(category);
              
              return _buildCategoryChip(
                context: context,
                filter: filter,
                label: label,
                count: count,
                isActive: isActive,
              );
            }).toList(),
          ),
        ],
        
        // Separator between sections
        if (photoCategories.isNotEmpty && documentCategories.isNotEmpty)
          const SizedBox(height: 16),
        
        // Document categories section
        if (documentCategories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Document Categories',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: documentCategories.map((category) {
              final filter = MediaTabController.categoryToFilter(category);
              if (filter == null) return const SizedBox.shrink();
              
              final count = widget.allMedia.where((item) => item.category == category).length;
              final isActive = widget.activeFilter == filter;
              final label = MediaProcessingService.getFormattedCategoryName(category);
              
              return _buildCategoryChip(
                context: context,
                filter: filter,
                label: label,
                count: count,
                isActive: isActive,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required MediaFilter filter,
    required String label,
    required int count,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => widget.onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

