import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savedSettingsServiceProvider =
Provider<SavedSettings>((ref) => throw UnimplementedError());

class SavedSettings {
  SavedSettings(this._savedSettings);

  final SharedPreferences _savedSettings;

  static const databaseVersionName = 'databaseVersion';

  Future<void> clearSettings() async {
    await _savedSettings.clear();
  }

  Future<void> setDatabaseVersion(String currentDatabaseVersion) async
  {
    await _savedSettings.setString(databaseVersionName, currentDatabaseVersion);
  }

  String? getDatabaseVersion() => _savedSettings.getString(databaseVersionName);
}