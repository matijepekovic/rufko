import 'package:open_filex/open_filex.dart';

import '../../data/providers/state/app_state_provider.dart';

/// Handles data import and export logic for the settings screen.
class SettingsDataService {
  const SettingsDataService(this.appState);

  final AppStateProvider appState;

  Future<String> exportData() async {
    final filePath = await appState.exportAllDataToFile();
    return filePath;
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await appState.importAllDataFromFile(data);
  }

  void openFile(String path) {
    OpenFilex.open(path);
  }
}
