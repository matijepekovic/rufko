import 'package:flutter/material.dart';

class CategorySelectionState extends ChangeNotifier {
  String? selectedCategory;
  bool isCreating = false;

  void select(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setCreating(bool creating) {
    isCreating = creating;
    notifyListeners();
  }
}
