import 'package:flutter_riverpod/all.dart';
import 'package:historical_context/saved_settings.dart';
import 'database_helper.dart';

final sqlDatabaseProvider = Provider<DatabaseHelper>((ref) {
  print('Starting sql database');
  final currentDatabaseVersion = ref.watch(databaseVersionProvider).state;
  return DatabaseHelper(currentDatabaseVersion);
});

final databaseVersionProvider = StateProvider<String>((ref) {
  final savedSettings = ref.watch(savedSettingsServiceProvider);
  final savedDatabaseVersion = savedSettings.getDatabaseVersion();

  print('We are in database version provider and ${savedDatabaseVersion}');

  if (savedDatabaseVersion != null) {
    return savedDatabaseVersion;
  }
  //Return the default
  return '1';
});