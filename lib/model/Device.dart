import 'package:flutter/material.dart';
import 'package:observable/observable.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/translations.dart';

import 'AppState.dart';
import 'Discipline.dart';
import 'ID.dart';

class Device implements ID {
  int id; //PRIMARY KEY
  String name; //z.B.: Anschütz 9015
  DeviceCategories deviceCategory;
  String customCategoryName = "";
  String stockKind;
  Image? image;

  ObservableList<Discipline> disciplines = ObservableList();
  bool sorting = false;

  Device(this.id, this.name, this.deviceCategory, this.stockKind, this.image) {
    disciplines = ObservableList();
    disciplines.listChanges.listen((changes) {
      changes.forEach((change) => print(change));
      DatabaseConverter databaseConverter = DatabaseConverter();
      //ADD:
      changes
          .forEach((change) => change.added.toList().forEach((discipline) => {
                if (AppState.appState != AppStates.LOADING)
                  databaseConverter.insertDiscipline(discipline)
              }));
      //REMOVE:
      changes
          .forEach((change) => change.removed.toList().forEach((discipline) => {
                if (AppState.appState != AppStates.LOADING && !sorting)
                  databaseConverter.deleteDiscipline(discipline.id)
              }));
    });
  }

  void sortDisciplines() {
    sorting = true;
    disciplines.sort((first, second) => first.compareTo(second));
  }

  String formatDeviceCategory() {
    switch (deviceCategory) {
      case DeviceCategories.AIR_RIFLE:
        return allTranslations.text("air_rifle");
      case DeviceCategories.SMALLBORE_RIFLE:
        return allTranslations.text("smallbore_rifle");
      case DeviceCategories.STANDARD_RIFLE:
        return allTranslations.text("standard_rifle");
      case DeviceCategories.AIR_PISTOL:
        return allTranslations.text("air_pistol");
      case DeviceCategories.RAPID_FIRE_PISTOL:
        return allTranslations.text("rapid_fire_pistol");
      case DeviceCategories.OTHER:
        return customCategoryName;
    }
  }

  List<Discipline> getAllConfigurations(Discipline discipline) {
    List<Discipline> result = [];
    for (Discipline disc in disciplines) {
      if (disc.name == discipline.name && disc.isConfiguration) {
        result.add(disc);
      }
    }
    return result;
  }

  String formatStockKind() {
    String stock = allTranslations.text("stock") + ": ";
    /* TODO LATER
    switch(stockKind) {
      case StockKinds.ANSCHUETZ_ALU:
        result += "ALU";
        break;
      case StockKinds.ANSCHUETZ_ONE:
        result += "ONE";
        break;
      case StockKinds.WALTHER_MONOTEC:
        result += "MONOTEC";
        break;
    } */
    return stockKind != "" ? stock + stockKind : "";
  }

  /* TODO ADD WHEN DeviceS ARE PREDEFINED
  static List<Device> getAllPredefinedDevices() {
    List<Device> allDevices = List();
    return allDevices
            ..add(Device("Anschütz 9015", DeviceCategories.AIR_RIFLE,
                "ALU", Image.asset("assets/devices/generic_rifle.png")))
            ..add(Device("Walther LG400", DeviceCategories.AIR_RIFLE,
                "Monotec", Image.asset("assets/devices/generic_rifle.png")));
  }
  */

  static List<Device> getAllDeviceForDeviceCategories() {
    return [
      Device(-1, allTranslations.text("air_rifle"), DeviceCategories.AIR_RIFLE,
          "", null),
      Device(-1, allTranslations.text("smallbore_rifle"),
          DeviceCategories.SMALLBORE_RIFLE, "", null),
      Device(-1, allTranslations.text("standard_rifle"),
          DeviceCategories.STANDARD_RIFLE, "", null),
      Device(-1, allTranslations.text("air_pistol"),
          DeviceCategories.AIR_PISTOL, "", null),
      Device(-1, allTranslations.text("rapid_fire_pistol"),
          DeviceCategories.RAPID_FIRE_PISTOL, "", null),
      Device(-1, allTranslations.text("add_category"), DeviceCategories.OTHER,
          "", null)
    ];
  }

  bool isRifle() {
    return deviceCategory == DeviceCategories.AIR_RIFLE ||
        deviceCategory == DeviceCategories.SMALLBORE_RIFLE ||
        deviceCategory == DeviceCategories.STANDARD_RIFLE;
  }

  bool isPistol() {
    return deviceCategory == DeviceCategories.AIR_PISTOL ||
        deviceCategory == DeviceCategories.RAPID_FIRE_PISTOL;
  }

  static DeviceCategories? getDeviceCategoryFromDatabaseString(String category) {
    for (DeviceCategories categories in DeviceCategories.values) {
      if (categories.toString() == category) return categories;
    }
    return null; //ERROR
  }

  @override
  String toString() {
    return 'Device{id: $id, name: $name, deviceCategory: $deviceCategory, customCategoryName: $customCategoryName, stockKind: $stockKind, image: $image, disciplines: $disciplines}';
  }

  @override
  int getID() {
    return id;
  }

  String printComplete() {
    String result =
        'Device{id: $id, name: $name, deviceCategory: $deviceCategory, customCategoryName: $customCategoryName, stockKind: $stockKind, image: $image';
    result += '\n disciplines:';
    for (Discipline discipline in disciplines) {
      result += '\n';
      result += discipline.printComplete();
    }
    result += '}';
    return result;
  }
}

enum DeviceCategories {
  AIR_RIFLE,
  SMALLBORE_RIFLE,
  STANDARD_RIFLE,
  AIR_PISTOL,
  RAPID_FIRE_PISTOL,
  OTHER
}
