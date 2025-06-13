import 'package:flutter/material.dart';

import '../../data/providers/state/app_state_provider.dart';
import '../../app/theme/rufko_theme.dart';

class UIStateController {
  UIStateController({required TickerProvider vsync, required this.onUpdate})
      : tabController = TabController(length: 4, vsync: vsync);

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
          heroTag: 'quotes_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('New Quote'),
          backgroundColor: Colors.blue,
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'inspection_fab',
          onPressed: navigateToCreateQuoteScreen,
          icon: const Icon(Icons.add_task),
          label: const Text('New Quote'),
          backgroundColor: Colors.green,
        );
      case 3:
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
        if (tabController.index == 3 && !isSelectionMode)
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: enterSelectionMode,
            tooltip: 'Select files',
            color: Colors.white,
          ),
        if (!isSelectionMode)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: editCustomer,
            color: Colors.white,
          ),
        if (!isSelectionMode)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'new_quote':
                  navigateToCreateQuoteScreen();
                  break;
                case 'edit_customer':
                  editCustomer();
                  break;
                case 'delete_customer':
                  deleteCustomer();
                  break;
                case 'quick_actions':
                  showQuickActions();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_quote',
                child: Row(
                  children: [
                    Icon(Icons.add_box, size: 18),
                    SizedBox(width: 8),
                    Text('New Quote'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_customer',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Customer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_customer',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Customer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quick_actions',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Quick Actions'),
                  ],
                ),
              ),
            ],
          ),
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(
            icon: Icon(isSelectionMode && tabController.index == 3
                ? Icons.checklist
                : Icons.info_outline),
            text: isSelectionMode && tabController.index == 3
                ? '${selectedMediaIds.length} selected'
                : 'Info',
          ),
          const Tab(icon: Icon(Icons.description), text: 'Quotes'),
          const Tab(icon: Icon(Icons.assignment), text: 'Inspection'),
          const Tab(icon: Icon(Icons.photo_library), text: 'Media'),
        ],
      ),
    );
  }
}
