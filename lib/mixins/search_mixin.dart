import 'package:flutter/material.dart';

mixin SearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool _showSearch = false;

  // Use a getter to ensure it always returns a bool
  bool get showSearch => _showSearch;

  void toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) clearSearch();
    });
  }

  void clearSearch() {
    searchController.clear();
    setState(() => searchQuery = '');
  }

  @mustCallSuper
  void disposeSearch() {
    searchController.dispose();
  }
}