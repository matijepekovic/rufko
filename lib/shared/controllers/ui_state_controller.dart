import 'package:flutter/material.dart';

import '../../data/providers/state/app_state_provider.dart';
import '../../app/theme/rufko_theme.dart';

class UIStateController {
  UIStateController({required TickerProvider vsync, required this.onUpdate, int initialIndex = 0})
      : tabController = TabController(length: 5, vsync: vsync, initialIndex: initialIndex);

  final TabController tabController;
  final VoidCallback onUpdate;

  bool isProcessingMedia = false;

  void dispose() {
    tabController.dispose();
  }

  void setProcessingState(bool processing) {
    isProcessingMedia = processing;
    onUpdate();
  }

  Widget buildFloatingActionButton({
    required bool isSelectionMode,
    required Set<String> selectedMediaIds,
    required VoidCallback deleteSelectedMedia,
    required VoidCallback exitSelectionMode,
    required VoidCallback navigateToCreateQuoteScreen,
    required VoidCallback showMediaOptions,
  }) {
    final currentTab = tabController.index;

    if (currentTab == 4 && isSelectionMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (selectedMediaIds.isNotEmpty)
            FloatingActionButton(
              heroTag: 'delete_selected_media_fab',
              onPressed: deleteSelectedMedia,
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete),
            ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'cancel_media_selection_fab',
            onPressed: exitSelectionMode,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.close),
          ),
        ],
      );
    }

    switch (currentTab) {
      case 0:
        return FloatingActionButton.extended(
          heroTag: 'info_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('New Quote'),
          backgroundColor: Colors.blue,
        );
      case 1:
        return FloatingActionButton.extended(
          heroTag: 'communications_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.message),
          label: const Text('New Message'),
          backgroundColor: Colors.purple,
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'quotes_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('New Quote'),
          backgroundColor: Colors.blue,
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'inspection_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add_task),
          label: const Text('New Quote'),
          backgroundColor: Colors.green,
        );
      case 4:
        return FloatingActionButton.extended(
          heroTag: 'media_fab',
          onPressed: showMediaOptions,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add Media'),
          backgroundColor: Colors.teal,
        );
      default:
        return FloatingActionButton.extended(
          heroTag: 'default_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('New Quote'),
          backgroundColor: Colors.blue,
        );
    }
  }

  SliverAppBar buildModernSliverAppBar(
    AppStateProvider appState, {
    required bool isSelectionMode,
    required VoidCallback enterSelectionMode,
    required VoidCallback navigateToCreateQuoteScreen,
    required VoidCallback editCustomer,
    required VoidCallback deleteCustomer,
    required VoidCallback showQuickActions,
    required Set<String> selectedMediaIds,
  }) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: RufkoTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RufkoTheme.primaryColor,
                RufkoTheme.primaryDarkColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!isSelectionMode)
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: showQuickActions,
            tooltip: 'Quick Actions',
          ),
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        isScrollable: true,
        tabs: [
          Tab(
            text: isSelectionMode && tabController.index == 4
                ? '${selectedMediaIds.length} selected'
                : 'Info',
          ),
          const Tab(text: 'Communications'),
          const Tab(text: 'Quotes'),
          const Tab(text: 'Inspection'),
          const Tab(text: 'Media'),
        ],
      ),
    );
  }
}
