
import 'package:observable/observable.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/util/Tuple.dart';

import 'AppState.dart';
import 'ID.dart';
import 'SettingImage.dart';

class SettingEntry implements ID{
  int id; //PRIMARY KEY
  Tuple<DateTime, dynamic>? _dateAndValue;
  String _notes = "";
  LengthMeasures? _lengthMeasure;

  int settingID; //FOREIGN KEY
  bool isGeneralImage = false;
  ObservableList<SettingImage> _images = ObservableList();

  Setting? belongingSetting;

  SettingEntry(this.id, this._dateAndValue, this.belongingSetting,
      this._lengthMeasure, this.settingID, this._notes, this.isGeneralImage) {
    _images = ObservableList();
    _images.listChanges.listen((changes) {
      changes.forEach((change) => print(change));
      DatabaseConverter databaseConverter = DatabaseConverter();
      //ADD:
      changes.forEach((change) => change.added.toList().forEach((image) => {
        if(AppState.appState != AppStates.LOADING)
            databaseConverter.insertImage(image)
      }));
      //REMOVE:
      changes.forEach((change) => change.removed.toList().forEach((image) => {
        if(AppState.appState != AppStates.LOADING)
          databaseConverter.deleteImage(image.id)
      }));
    }); 
  }

  Future<void> updateDatabase() async {
    if(AppState.appState != AppStates.LOADING) {
      DatabaseConverter databaseConverter = DatabaseConverter();
      await databaseConverter.updateSettingEntry(this);
    }
}

  void updateNotes(String newNotes) {
    this._notes = newNotes;
    updateDatabase();
  }

  void updateLengthMeasure(LengthMeasures newLengthMeasure) {
    this._lengthMeasure = newLengthMeasure;
    updateDatabase();
  }

  void updateTuple(Tuple<DateTime, dynamic> newTuple) {
    this._dateAndValue = newTuple;
    updateDatabase();
  }

  void convertValueByLengthMeasure(LengthMeasures newMeasure) {
    double factor = 1;
    switch(_lengthMeasure) {
      case LengthMeasures.MM:
        if(newMeasure == LengthMeasures.CM)
          factor = 0.1;
        else if(newMeasure == LengthMeasures.M)
          factor = 0.001;
        break;
      case LengthMeasures.CM:
        if(newMeasure == LengthMeasures.MM)
          factor = 10;
        else if(newMeasure == LengthMeasures.M)
          factor = 0.01;
        break;
      case LengthMeasures.M:
        if(newMeasure == LengthMeasures.MM)
          factor = 1000;
        else if(newMeasure == LengthMeasures.CM)
          factor = 100;
        break;
      case null:
          factor = 1;
        break;
    }
    _lengthMeasure = newMeasure;
    var value = _dateAndValue!.getRight as double;
    var factorValue = value * factor;
    _dateAndValue = Tuple(_dateAndValue!.getLeft, factorValue);
    updateDatabase();
  }

  Tuple<DateTime, dynamic> get dateAndValue => _dateAndValue!;

  LengthMeasures? get lengthMeasure => _lengthMeasure;

  List<SettingImage> get images => _images;

  String get notes => _notes;

  @override
  String toString() {
    return 'SettingEntry{id: $id, _dateAndValue: $_dateAndValue, _notes: $_notes, _lengthMeasure: $_lengthMeasure, settingID: $settingID, _images: $_images';
  }

  @override
  int getID() {
    return id;
  }

  String printComplete() {
    String result = 'SettingEntry{id: $id, _dateAndValue: $_dateAndValue, _notes: $_notes, _lengthMeasure: $_lengthMeasure, settingID: $settingID,';
    result += '\n images: ';
    for(SettingImage settingImage in images) {
      result += '\n';
      result += settingImage.toString();
    }
    result += '}';
    return result;
  }
}