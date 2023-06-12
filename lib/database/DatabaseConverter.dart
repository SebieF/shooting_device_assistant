import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:settings_app/database/DatabaseProvider.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/ID.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/model/SettingEntry.dart';
import 'package:settings_app/model/SettingImage.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/util/Tuple.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseConverter {
  final String devicesTable = "devices";
  final String disciplinesTable = "disciplines";
  final String settingsTable = "settings";
  final String settingEntriesTable = "settingEntries";
  final String imagesTable = "images";

  Database? _database;
  bool readOnly = false;

  static final DatabaseConverter _instance = DatabaseConverter._();

  DatabaseConverter._();

  factory DatabaseConverter() {
    return _instance;
  }

  Future<List<Map<String, dynamic>>> queryDatabase(String query) async {
    if (_database == null) {
      DatabaseProvider databaseProvider = await DatabaseProvider.instance();
      _database = databaseProvider.database;
    }
    return _database!.query(query);
  }

  // SPECIFIC DATABASE FUNCTIONS
  // *** DeviceS ***
  Map<String, dynamic> deviceToMap(Device device) {
    return {
      'id': device.id,
      'name': device.name,
      'deviceCategory': device.deviceCategory.toString(),
      'customCategoryName': device.customCategoryName,
      'stockKind': device.stockKind
    };
  }

  Future<void> insertDevice(Device device) async {
    if (!readOnly) {
      await _database!.insert(
        'devices',
        deviceToMap(device),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteDevice(int id) async {
    if (!readOnly) {
      // Get a reference to the database.
      final db = _database;
      // REMOVE ALL ASSOCIATED DISCIPLINES:
      List<Discipline> disciplines = await readAllDisciplines();
      disciplines.forEach((discipline) => {
            if (discipline.deviceID == id) {deleteDiscipline(discipline.id)}
          });
      // Remove the Device from the database.
      await db!.delete(
        devicesTable,
        // Use a `where` clause to delete a specific device.
        where: "id = ?",
        // Pass the Device's id as a whereArg to prevent SQL injection.
        whereArgs: [id],
      );
    }
  }

  Future<List<Device>> readAllDevices() async {
    final List<Map<String, dynamic>> maps = await queryDatabase(devicesTable);

    // Convert the List<Map<String, dynamic> into a List<Device>.
    return List.generate(maps.length, (i) {
      int id = maps[i]['id'];
      String name = maps[i]['name'];
      String deviceCategory = maps[i]['deviceCategory'];
      DeviceCategories category =
          Device.getDeviceCategoryFromDatabaseString(deviceCategory)!;
      String customCategoryName = maps[i]['customCategoryName'];
      String stockKind = maps[i]['stockKind'];
      Device result = Device(id, name, category, stockKind, null);
      if (result.isRifle())
        result.image = Image.asset("assets/devices/generic_rifle.png");
      if (result.isPistol())
        result.image = Image.asset("assets/devices/generic_pistol.png");
      if (category == DeviceCategories.OTHER)
        result.customCategoryName = customCategoryName;
      return result;
    });
  }

  // *** DISCIPLINES ***
  Map<String, dynamic> disciplineToMap(Discipline discipline) {
    return {
      'id': discipline.id,
      'name': discipline.name.toString(),
      'deviceID': discipline.deviceID,
      'isConfiguration': discipline.isConfiguration ? "True" : "False",
      'configurationName': discipline.configurationName,
      'orderedConfigPosition': discipline.orderedConfigPosition
    };
  }

  Future<void> insertDiscipline(Discipline discipline) async {
    if (!readOnly) {
      await _database!.insert(
        disciplinesTable,
        disciplineToMap(discipline),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Configuration Name
  Future<void> updateDiscipline(Discipline discipline) async {
    if (!readOnly) {
      await _database!.update(
        disciplinesTable,
        disciplineToMap(discipline),
        // Ensure that the SettingEntry has a matching id.
        where: "id = ?",
        // Pass the Entry's id as a whereArg to prevent SQL injection.
        whereArgs: [discipline.id],
      );
    }
  }

  Future<void> deleteDiscipline(int id) async {
    if (!readOnly) {
      final db = _database;

      List<Setting> settings = await readAllSettings();
      settings.forEach((setting) => {
            if (setting.disciplineID == id) {deleteSetting(setting.id)}
          });

      await db!.delete(
        disciplinesTable,
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  Future<List<Discipline>> readAllDisciplines() async {
    final List<Map<String, dynamic>> maps =
        await queryDatabase(disciplinesTable);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      int id = maps[i]['id'];
      String name = maps[i]['name'];
      Disciplines disciplines =
          Discipline.getDisciplineFromDatabaseString(name)!;
      int deviceID = maps[i]['deviceID'];
      int orderedConfigPosition = maps[i]['orderedConfigPosition'];
      Discipline discipline =
          Discipline(id, disciplines, deviceID, orderedConfigPosition);
      bool isConfiguration = maps[i]['isConfiguration'] == "True";
      String configurationName = maps[i]['configurationName'] ?? '';
      discipline.isConfiguration = isConfiguration;
      discipline.configurationName = configurationName;
      return discipline;
    });
  }

  // *** SETTINGS ***
  Map<String, dynamic> settingToMap(Setting setting) {
    return {
      'id': setting.id,
      'name': setting.name,
      'orderedPosition': setting.orderedPosition,
      'disciplineID': setting.disciplineID,
    };
  }

  Future<void> insertSetting(Setting setting) async {
    if (!readOnly) {
      await _database!.insert(
        settingsTable,
        settingToMap(setting),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ORDERED POSITION
  Future<void> updateSetting(Setting setting) async {
    if (!readOnly) {
      await _database!.update(
        settingsTable,
        settingToMap(setting),
        // Ensure that the SettingEntry has a matching id.
        where: "id = ?",
        // Pass the Entry's id as a whereArg to prevent SQL injection.
        whereArgs: [setting.id],
      );
    }
  }

  Future<void> deleteSetting(int id) async {
    if (!readOnly) {
      final db = _database;

      List<SettingEntry> settingEntries = await readAllSettingEntries();
      settingEntries.forEach((settingEntry) => {
            if (settingEntry.settingID == id)
              {deleteSettingEntry(settingEntry.id)}
          });

      await db!.delete(
        settingsTable,
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  Future<List<Setting>> readAllSettings() async {
    final List<Map<String, dynamic>> maps = await queryDatabase(settingsTable);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      int id = maps[i]['id'];
      String name = maps[i]['name'];
      int orderedPosition = maps[i]['orderedPosition'];
      int disciplineID = maps[i]['disciplineID'];
      return Setting(id, name, orderedPosition, null,
          disciplineID); //DISCIPLINE: NULL, MUST BE SET LATER
    });
  }

  //***SETTING ENTRY***
  Map<String, dynamic> settingEntryToMap(SettingEntry settingEntry) {
    return {
      'id': settingEntry.id,
      'date': settingEntry.dateAndValue.getLeft.toIso8601String(),
      'value': settingEntry.dateAndValue.getRight?.toString() ?? '',
      'lengthMeasure': settingEntry.lengthMeasure.toString(),
      'notes': settingEntry.notes,
      'settingID': settingEntry.settingID,
      'isGeneralImage': settingEntry.isGeneralImage ? "True" : "False",
    };
  }

  Future<void> insertSettingEntry(SettingEntry settingEntry) async {
    if (!readOnly) {
      await _database!.insert(
        settingEntriesTable,
        settingEntryToMap(settingEntry),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  //LENGTH MEASURE CHANGE, NOTES CHANGE
  Future<void> updateSettingEntry(SettingEntry settingEntry) async {
    if (!readOnly) {
      await _database!.update(
        settingEntriesTable,
        settingEntryToMap(settingEntry),
        // Ensure that the SettingEntry has a matching id.
        where: "id = ?",
        // Pass the Entry's id as a whereArg to prevent SQL injection.
        whereArgs: [settingEntry.id],
      );
    }
  }

  Future<void> deleteSettingEntry(int id) async {
    if (!readOnly) {
      final db = _database;
      List<SettingImage> settingImages = await readAllImages();
      settingImages.forEach((settingImage) => {
            if (settingImage.settingEntryID == id)
              {deleteImage(settingImage.id)}
          });

      await db!.delete(
        settingEntriesTable,
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  Future<List<SettingEntry>> readAllSettingEntries() async {
    final List<Map<String, dynamic>> maps =
        await queryDatabase(settingEntriesTable);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      int id = maps[i]['id'];
      String date = maps[i]['date'];
      DateTime dateTime = DateTime.parse(date);
      String value = maps[i]['value'];
      String lengthMeasureString = maps[i]['lengthMeasure'] ?? '';
      LengthMeasures? lengthMeasures =
          Setting.getLengthMeasureFromDatabaseString(lengthMeasureString);
      String notes = maps[i]['notes'];
      int settingID = maps[i]['settingID'];
      bool isGeneralImage = maps[i]['isGeneralImage'] == "True";
      Tuple<DateTime, dynamic> dateAndValue = Tuple(dateTime, value);
      return SettingEntry(id, dateAndValue, null, lengthMeasures, settingID,
          notes, isGeneralImage); //Setting: NULL, MUST BE SET LATER
    });
  }

  // IMAGES:
  Map<String, dynamic> imageToMap(SettingImage image) {
    return {
      'id': image.id,
      'path': image.fileImage.file.path,
      'rotation': image.rotation,
      'settingEntryID': image.settingEntryID,
    };
  }

  Future<void> insertImage(SettingImage image) async {
    if (!readOnly) {
      await _database!.insert(
        imagesTable,
        imageToMap(image),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  //FOR ROTATION
  Future<void> updateImage(SettingImage image) async {
    if (!readOnly) {
      await _database!.update(
        imagesTable,
        imageToMap(image),
        // Ensure that the SettingEntry has a matching id.
        where: "id = ?",
        // Pass the Entry's id as a whereArg to prevent SQL injection.
        whereArgs: [image.id],
      );
    }
  }

  Future<void> deleteImage(int id) async {
    if (!readOnly) {
      final db = _database;

      await db!.delete(
        imagesTable,
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  Future<List<SettingImage>> readAllImages() async {
    final List<Map<String, dynamic>> maps = await queryDatabase(imagesTable);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      int id = maps[i]['id'];
      String path = maps[i]['path'];
      FileImage image = FileImage(File(path));
      int rotation = maps[i]['rotation'];
      int settingEntryID = maps[i]['settingEntryID'];
      return SettingImage(id, image, settingEntryID, rotation);
    });
  }

  // *** READ ALL:***
  Future<List<Device>> readAllValuesFromDatabase() async {
    List<Device> devices = await readAllDevices();
    List<Discipline> disciplines = await readAllDisciplines();
    List<Setting> settings = await readAllSettings();
    List<SettingEntry> settingEntries = await readAllSettingEntries();
    List<SettingImage> images = await readAllImages();

    // ASSOCIATE MATCHING IDS:
    //LOW TO HIGH:
    for (SettingEntry settingEntry in settingEntries) {
      for (SettingImage image in images) {
        if (image.settingEntryID == settingEntry.id)
          settingEntry.images.add(image);
      }
    }
    List<SettingEntry> generalImages = [];
    for (Setting setting in settings) {
      for (SettingEntry settingEntry in settingEntries) {
        if (settingEntry.settingID == setting.id &&
            !settingEntry.isGeneralImage) {
          setting.values.add(settingEntry);
          settingEntry.belongingSetting = setting;
        } else if (settingEntry.isGeneralImage) {
          generalImages.add(settingEntry);
        }
      }
      // CONVERT IF POSSIBLE:
      if (setting.checkIfAllValuesCanBeConvertedToDouble())
        setting.changeAllValuesToDouble();

      setting.sortSettingEntriesByDate();
    }

    for (Discipline discipline in disciplines) {
      for (Setting setting in settings) {
        if (setting.disciplineID == discipline.id) {
          discipline.settings.add(setting);
          setting.belongingDiscipline = discipline;
        }
      }
      for (SettingEntry generalImage in generalImages) {
        if (generalImage.settingID == discipline.id) {
          await discipline.addGeneralSettingImage(generalImage);
        }
      }
    }
    for (Device device in devices) {
      for (Discipline discipline in disciplines) {
        if (discipline.deviceID == device.id) {
          device.disciplines.add(discipline);
          discipline.belongingDevice = device;
        }
      }
    }

    //Reset sorting:
    for (Setting setting in settings) {
      setting.sorting = false;
    }

    return devices;
  }

  // *** SAVE ALL
  Future<void> saveAllToLocalDatabase(List<Device> devices) async {
    // SAVE COMPLETE HIERARCHY
    for (Device device in devices) {
      await insertDevice(device);
      for (Discipline discipline in device.disciplines) {
        await insertDiscipline(discipline);
        for (Setting setting in discipline.settings) {
          await insertSetting(setting);
          for (SettingEntry settingEntry in setting.values) {
            await insertSettingEntry(settingEntry);
            for (SettingImage image in settingEntry.images) {
              await insertImage(image);
            }
          }
        }
      }
    }
  }

  // *** GET NEXT IDS ***

  Future<int> getNextDeviceID() async {
    List<Device> devices = await readAllDevices();
    if (devices.length == 0) return 1;
    return (getMaxID(devices) + 1);
  }

  Future<int> getNextDisciplineID() async {
    List<Discipline> disciplines = await readAllDisciplines();
    if (disciplines.length == 0) return 1;
    return (getMaxID(disciplines) + 1);
  }

  Future<int> getNextSettingID() async {
    List<Setting> settings = await readAllSettings();
    if (settings.length == 0) return 1;

    return (getMaxID(settings) + 1);
  }

  Future<int> getNextSettingEntryID() async {
    List<SettingEntry> settingEntries = await readAllSettingEntries();
    if (settingEntries.length == 0) return 1;

    return (getMaxID(settingEntries) + 1);
  }

  Future<int> getNextImageID() async {
    List<SettingImage> settingImages = await readAllImages();
    if (settingImages.length == 0) return 1;

    return (getMaxID(settingImages) + 1);
  }

  int getMaxID(List<ID> ids) {
    int max = -1000;
    for (ID id in ids) {
      if (id.getID() > max) {
        max = id.getID();
      }
    }
    return max;
  }
}
