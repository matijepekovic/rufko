import 'package:flutter/material.dart';

class TemplatesScreenState extends ChangeNotifier {
  int currentTab = 0;
  bool isLoading = false;

  void setTab(int index) {
    currentTab = index;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
