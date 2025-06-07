import 'package:flutter/material.dart';

mixin SearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool showSearch = false;

  void toggleSearch() {
    setState(() {
      showSearch = !showSearch;
      if (!showSearch) clearSearch();
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
