import 'package:flutter/material.dart';

mixin SearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool _searchVisible = false;

  // Use a getter to ensure it always returns a bool
  bool get searchVisible => _searchVisible;

  void toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) clearSearch();
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