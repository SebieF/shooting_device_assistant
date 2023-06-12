import 'package:observable/observable.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/translations.dart';

import 'AppState.dart';
import 'ID.dart';
import 'Setting.dart';
import 'SettingEntry.dart';
import 'Device.dart';

class Discipline implements ID{
  int id; // PRIMARY KEY
  Disciplines name; //z.B.: Liegend
  int deviceID; //FOREIGN KEY
  late ObservableList<Setting> settings;
  SettingEntry? generalEntryForImage = null;
  bool isConfiguration = false;
  int _orderedConfigPosition;

  String configurationName = allTranslations.text("default_configuration_name");

  late Device belongingDevice;

  Discipline(this.id, this.name, this.deviceID, this._orderedConfigPosition) {
    settings = ObservableList();
    settings.listChanges.listen((changes) {
      changes.forEach((change) => print("Disciplines " + change.toString()));
      DatabaseConverter databaseConverter = DatabaseConverter();
      //ADD:
      changes.forEach((change) => change.added.toList().forEach((setting) => {
        if(AppState.appState != AppStates.LOADING)
          databaseConverter.insertSetting(setting)
      }));
      //REMOVE:
      changes.forEach((change) => change.removed.toList().forEach((setting) => {
        if(AppState.appState != AppStates.LOADING)
          databaseConverter.deleteSetting(setting.id)
      }));
    });
  }

  void addNewSetting(Setting setting) {
    settings.add(setting);
  }

  Future<void> addGeneralSettingImage(SettingEntry settingEntry) async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    if(generalEntryForImage != null) {
      deleteCurrentSettingImage();
    }
    generalEntryForImage = settingEntry;
    if(AppState.appState != AppStates.LOADING)
      await databaseConverter.insertSettingEntry(settingEntry);
  }

  Future<void> deleteCurrentSettingImage() async {
    if(generalEntryForImage != null) {
      if (AppState.appState != AppStates.LOADING) {
        DatabaseConverter databaseConverter = DatabaseConverter();
        await databaseConverter.deleteSettingEntry(generalEntryForImage!.id);
        generalEntryForImage = null;
      }
    }
  }

  void deleteLatestSetting() {
    if(settings.length > 0)
      settings.removeLast();
  }

  int compareTo(Discipline compare) {
    if(name.index < compare.name.index) {
      return -1;
    } else {
      return 1;
    }
  }

  String formatDisciplineName() {
    switch(name) {
      case Disciplines.KNEELING:
        return allTranslations.text("kneeling");
      case Disciplines.PRONE:
        return allTranslations.text("prone");
      case Disciplines.STANDING:
        return allTranslations.text("standing");
      case Disciplines.REST:
        return allTranslations.text("rest");
      case Disciplines.BODY:
        return allTranslations.text("body");
    }
  }

  String assetImageName() {
    String assetName = "assets/disciplines/";
    switch(name) {
      case Disciplines.KNEELING:
        return assetName += "kneeling.png";
      case Disciplines.PRONE:
        return assetName += "prone.png";
      case Disciplines.STANDING:
        return assetName += "standing.png";
      case Disciplines.REST:
        return assetName += "rest.png";
      case Disciplines.BODY:
        return assetName += "body.png";
    }
  }

  static List<Discipline> getAllPredefinedDisciplines() {
    return [
      Discipline(-1, Disciplines.KNEELING, -1, 0), // ID IS SET ON ADDING
      Discipline(-1, Disciplines.PRONE, -1, 0),
      Discipline(-1, Disciplines.STANDING, -1, 0),
      Discipline(-1, Disciplines.REST, -1, 0),
      Discipline(-1, Disciplines.BODY, -1, 0)
    ];
  }

  static Disciplines? getDisciplineFromDatabaseString(String discipline) {
    for(Disciplines disciplines in Disciplines.values) {
      if(disciplines.toString() == discipline) {
        return disciplines;
      }
    }
    return null; //ERROR
  }

  int get orderedConfigPosition => _orderedConfigPosition;

  Future<void> updatePosition(int newPosition) async {
    if(newPosition != _orderedConfigPosition) {
      this._orderedConfigPosition = newPosition;
      DatabaseConverter databaseConverter = DatabaseConverter();
      await databaseConverter.updateDiscipline(this);
    }
  }

  @override
  String toString() {
    return 'Discipline{id: $id, name: $name, deviceID: $deviceID, settings: $settings}';
  }

  String printComplete() {
    String result = 'Discipline{id: $id, name: $name, deviceID: $deviceID,';
    result += '\n settings: ';
    for(Setting setting in settings) {
      result += '\n';
      result += setting.printComplete();
    }
    result += '}';
    return result;
  }

  @override
  int getID() {
    return id;
  }
}

enum Disciplines {
  KNEELING,
  PRONE,
  STANDING,
  REST, //AUFLAGE
  BODY
}