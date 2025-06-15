import 'package:flutter/material.dart';

class SelectionState {
  bool isSelectionMode = false;
  Set<String> selectedIds = <String>{};
}

mixin SelectionMixin<T extends StatefulWidget> on State<T> {
  void enterSelectionMode(SelectionState state) {
    setState(() {
      state.isSelectionMode = true;
      state.selectedIds.clear();
    });
  }

  void exitSelectionMode(SelectionState state) {
    setState(() {
      state.isSelectionMode = false;
      state.selectedIds.clear();
    });
  }

  void toggleSelection(SelectionState state, String id) {
    setState(() {
      if (state.selectedIds.contains(id)) {
        state.selectedIds.remove(id);
      } else {
        state.selectedIds.add(id);
      }
    });
  }

  void selectAll(SelectionState state, Iterable<String> ids) {
    setState(() {
      if (state.selectedIds.length == ids.length) {
        state.selectedIds.clear();
      } else {
        state.selectedIds = ids.toSet();
      }
    });
  }
}
