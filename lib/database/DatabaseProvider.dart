import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:settings_app/util/Constants.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {

  Database? _database;

  static DatabaseProvider? _instance;

  DatabaseProvider._();

  static Future<DatabaseProvider> instance() async {
    if(_instance == null) {
      _instance = DatabaseProvider._();
      await _instance!._initDatabase();
    }
    return _instance!;
  }

  Database? get database => _database;

  Future<bool> anonDatabaseExists() async {
    return databaseExists(join( await getDatabasesPath(), 'settings_database' + "Anon" + '.db'));
  }

  Future<void> openAnonDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    // The path_provider plugin gets the right directory for Android or iOS.
    // Open the database. Can also add an onUpdate callback parameter.
    _database = await openDatabase(
      join( await getDatabasesPath(), 'settings_database' + "Anon" + '.db'),
    );
  }

  Future<void> openUserDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    String uid = Constants.localUserName;

    print("DatabaseProvider UID: " + uid);
    _database = await openDatabase(
      join( await getDatabasesPath(), 'settings_database' + uid + '.db'),
      onCreate: (db, version) async
    {
      // call database script that is saved in a file in assets
      String script =  await rootBundle.loadString("assets/database/storage.sql");
      List<String> scripts = script.split(";");
      scripts.forEach((v)
      {
        if(v.isNotEmpty )
        {
          print(v.trim());
          db.execute(v.trim());
        }
      });
    },
    version: 1,
    );
  }

  Future<void> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    String suffix = Constants.localUserName;

    _database = await openDatabase(
      join( await getDatabasesPath(), 'settings_database' + suffix + '.db'),
      onCreate: (db, version) async
      {
        // call database script that is saved in a file in assets
        String script =  await rootBundle.loadString("assets/database/storage.sql");
        List<String> scripts = script.split(";");
        scripts.forEach((v)
        {
          if(v.isNotEmpty )
          {
            print(v.trim());
            db.execute(v.trim());
          }
        });
      },
      version: 1,
    );
    print(database.toString());
  }

}