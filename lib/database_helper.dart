import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:historical_context/model/events.dart';

class DatabaseHelper {
  static const _databaseName = "historical_events_database.db";
  static const _databaseVersion = 1;
  late Database _db;
  bool initialized = false;

  @override
  DatabaseHelper(String currentDatabaseVersion){
    init(currentDatabaseVersion);
  }

  Future<bool> openSqlDatabase()async{
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String databasePath = join(appDocDir.path, _databaseName);
    this._db = await openDatabase(databasePath);
    initialized = true;
    return true;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<void> init(String currentDatabaseVersion) async {
    print('Enter try to get database');
    // Construct a file path to copy database to
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    print('path ${path}');

    //update this to do something with the database version so that I update the the database
    //it will reload the db from the assets folder TODO
    // Only copy if the database doesn't exist
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound){
      print('file not found');
      // Load database from asset and copy
      ByteData data = await rootBundle.load(join('asset', _databaseName));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      print('data.lengthInBytes ${data.lengthInBytes}');

      // Save copied asset to documents
      await new File(path).writeAsBytes(bytes);
    }else{
      print('The file exists');
      //check to see if the database version has changes and replace
      if(_databaseVersion > (int.parse(currentDatabaseVersion)??1)){
        //delete the old database
        await deleteDatabase(path);

        // Load database from asset and copy
        ByteData data = await rootBundle.load(join('asset', _databaseName));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        print('data.lengthInBytes ${data.lengthInBytes}');

        // Save copied asset to documents
        await new File(path).writeAsBytes(bytes);
      }
    }
    this._db = await openDatabase(path);
    initialized = true;
  }

  // Helper methods

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<HistoricalEvent>> queryAllRows() async {
    List<Map<String, dynamic>> tempList = await _db.query('historical_event_table');
    return tempList.map((e) => HistoricalEvent.fromMap(e)).toList();
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM historical_event_table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<List<HistoricalEvent>> getAll() async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT * FROM historical_event_table''';
    var list = await this._db.rawQuery(query);
    return list.map((e) {
      return HistoricalEvent.fromMap(e);
    }).toList();
  }

  Future<List<HistoricalEvent>> findByImportance( int searchImportance) async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT * FROM historical_event_table where importance LIKE ?''';
    var list = await this._db.rawQuery(query, [searchImportance]);
    return list.map((e) => HistoricalEvent.fromMap(e)).toList();
  }

  Future<List<HistoricalEvent>> findByCountry( String searchCountry) async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT * FROM historical_event_table where location_country LIKE ?''';
    var list = await this._db.rawQuery(query,[searchCountry]);
    return list.map((e) => HistoricalEvent.fromMap(e)).toList();
  }

  Future<List<HistoricalEvent>> findByCity( String searchCity) async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT * FROM historical_event_table where location_city LIKE ?''';
    var list = await this._db.rawQuery(query,[searchCity]);
    return list.map((e) => HistoricalEvent.fromMap(e)).toList();
  }

  Future<List<HistoricalEvent>> findByYear( int searchYear) async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT * FROM historical_event_table where year LIKE ?''';
    var list = await this._db.rawQuery(query,[searchYear]);
    return list.map((e) => HistoricalEvent.fromMap(e)).toList();
  }

  Future<List<HistoricalEvent>> findByEvent( String searchEvent) async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT * FROM historical_event_table where 
      ' ' || summary || ' ' LIKE  '% ' || ? || ' %' OR
      ' ' || full_summary || ' ' LIKE  '% ' || ? || ' %'
      ''';
    var list = await this._db.rawQuery(query,[searchEvent, searchEvent]);
    return list.map((e) => HistoricalEvent.fromMap(e)).toList();
  }

  Future<Set<String>> getAllCountries() async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT location_country FROM historical_event_table where location_country is not null''';
    var list = await this._db.rawQuery(query);
    return list.map((e) => e['location_country'].toString()).toSet();
  }

  Future<Set<String>> getAllCities() async {
    if (!initialized) await this.openSqlDatabase();
    String query = '''
      SELECT location_city FROM historical_event_table where location_city is not null''';
    var list = await this._db.rawQuery(query);
    return list.map((e) => e['location_city'].toString()).toSet();
  }

}