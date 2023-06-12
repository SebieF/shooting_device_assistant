import 'package:flutter/material.dart';
import 'package:observable/observable.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/SettingEntry.dart';
import 'package:settings_app/util/Tuple.dart';

import 'AppState.dart';
import 'Discipline.dart';
import 'ID.dart';

class Setting implements ID {
  int id; //PRIMARY KEY
  String name; //z.B. Backe
  late Key key;
  int disciplineID; //FOREIGN KEY
  int _orderedPosition;
  ObservableList<SettingEntry> values = ObservableList();

  bool sorting = false;

  Discipline? belongingDiscipline;

  Setting(this.id, this.name, this._orderedPosition, this.belongingDiscipline,
      this.disciplineID) {
    values = ObservableList();
    values.listChanges.listen((changes) {
      changes.forEach((change) => print(change));
      DatabaseConverter databaseConverter = DatabaseConverter();
      //ADD:
      changes
          .forEach((change) => change.added.toList().forEach((settingEntry) => {
                if (AppState.appState != AppStates.LOADING && !sorting)
                  databaseConverter.insertSettingEntry(settingEntry)
              }));
      //REMOVE:
      changes.forEach(
          (change) => change.removed.toList().forEach((settingEntry) => {
                if (AppState.appState != AppStates.LOADING && !sorting)
                  databaseConverter.deleteSettingEntry(settingEntry.id)
              }));
    });
  }

  int get orderedPosition => _orderedPosition;

  Future<void> updatePosition(int newPosition) async {
    if (newPosition != _orderedPosition) {
      this._orderedPosition = newPosition;
      DatabaseConverter databaseConverter = DatabaseConverter();
      databaseConverter.updateSetting(this);
    }
  }

  Future<void> updateName(String newName) async {
    if (newName != name) {
      this.name = newName;
      DatabaseConverter databaseConverter = DatabaseConverter();
      databaseConverter.updateSetting(this);
    }
  }

  void sortSettingEntriesByDate() {
    sorting = true;
    values.sort((entry1, entry2) =>
        entry1.dateAndValue.getLeft.isBefore(entry2.dateAndValue.getLeft)
            ? -1
            : 1);
  }

  String preformatValue(dynamic value) {
    bool isNumeric(string) => num.tryParse(string) != null;
    String formatted = value.toString().trim();
    //Replace , with . between numbers
    int commaPosition = formatted.indexOf(","); //Only first occurrence
    int left = commaPosition - 1;
    int right = commaPosition + 1;
    if (left >= 0 && right < formatted.length) {
      if (isNumeric(
          formatted.substring(left, right + 1).replaceAll(",", "."))) {
        formatted = formatted.replaceFirst(",", ".");
      }
    }
    return formatted;
  }

  Future<void> addValue(dynamic value) async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    int settingEntryID = await databaseConverter.getNextSettingEntryID();

    String formattedValue = preformatValue(value);
    var doubleIfParsable = double.tryParse(formattedValue);
    if (doubleIfParsable != null) {
      //DOUBLE
      Tuple<DateTime, double> valueTuple =
          Tuple(DateTime.now(), doubleIfParsable);
      SettingEntry settingEntry = SettingEntry(
          settingEntryID, valueTuple, this, null, this.id, "", false);
      values.add(settingEntry);
      return;
    } else {
      //STRING
      //STRING WITH MEASURES CM/MM/M:
      if (values.length == 0 || isLatestValueDouble()) {
        Tuple<double, LengthMeasures>? patternDouble =
            detectLengthMeasures(formattedValue);
        if (patternDouble != null) {
          Tuple<DateTime, double> valueTuple =
              Tuple(DateTime.now(), patternDouble.getLeft);
          SettingEntry doubleEntry = SettingEntry(settingEntryID, valueTuple,
              this, patternDouble.getRight, this.id, "", false);
          values.add(doubleEntry);
          return;
        }
      }
      // USUAL STRING:
      changeAllValuesToString();
      Tuple<DateTime, String> valueTuple =
          Tuple(DateTime.now(), value.toString());
      SettingEntry settingEntry = SettingEntry(
          settingEntryID, valueTuple, this, null, this.id, "", false);
      values.add(settingEntry);
    }
  }

  Tuple<double, LengthMeasures>? detectLengthMeasures(String value) {
    String valueLow = value.toLowerCase();
    for (LengthMeasures newLengthMeasure in LengthMeasures.values) {
      // 1. CONTAINS LENGTH MEASURE?
      String lengthString =
          newLengthMeasure.toString().split(".")[1].toLowerCase();
      if (valueLow.contains(lengthString)) {
        //2. HAS VALID PATTERN? X.XX cm / Y.Ymm
        int index = valueLow.indexOf(lengthString);

        double? parsable =
            double.tryParse(value.substring(0, index).replaceAll(' ', ''));
        if (parsable != null) {
          if (getCurrentLengthMeasure() != newLengthMeasure)
            convertAllLengthMeasures(newLengthMeasure);

          return Tuple(parsable, newLengthMeasure);
        }
      }
    }
    return null;
  }

  void convertAllLengthMeasures(LengthMeasures newMeasure) {
    if (isLatestValueDouble()) {
      for (SettingEntry settingEntry in values) {
        settingEntry.convertValueByLengthMeasure(newMeasure);
      }
    }
  }

  void changeAllValuesToString() {
    for (SettingEntry settingEntry in values) {
      Tuple<DateTime, String> stringTuple = Tuple(
          settingEntry.dateAndValue.getLeft,
          settingEntry.dateAndValue.getRight.toString());
      settingEntry.updateTuple(stringTuple);
    }
  }

  void changeAllValuesToDouble() {
    for (SettingEntry settingEntry in values) {
      Tuple<DateTime, double> doubleTuple = Tuple(
          settingEntry.dateAndValue.getLeft,
          double.parse(settingEntry.dateAndValue.getRight.toString()));
      settingEntry.updateTuple(doubleTuple);
    }
  }

  bool checkIfAllValuesCanBeConvertedToDouble() {
    for (SettingEntry settingEntry in values) {
      if (double.tryParse(settingEntry.dateAndValue.getRight.toString()) ==
          null) return false;
    }
    return true;
  }

  double getNumberOfStringOccurrences(SettingEntry settingEntry) {
    int result = 0;
    for (SettingEntry comp in values) {
      if (comp.dateAndValue.getRight.toString().toLowerCase() ==
          settingEntry.dateAndValue.getRight.toString().toLowerCase()) result++;
    }
    return result.toDouble();
  }

  dynamic get getLatestValue {
    if (values.isEmpty)
      return null;
    else
      return values.last.dateAndValue.getRight;
  }

  bool isLatestValueDouble() {
    return (double.tryParse(getLatestValue.toString()) != null);
  }

  DateTime? get getLatestDate {
    if (values.isEmpty) return null;
    return values.last.dateAndValue.getLeft;
  }

  static LengthMeasures? getLengthMeasureFromDatabaseString(String measure) {
    for (LengthMeasures lengthMeasures in LengthMeasures.values) {
      if (lengthMeasures.toString() == measure) return lengthMeasures;
    }
    return null; //NO MATCH
  }

  LengthMeasures? getCurrentLengthMeasure() {
    if (values.isNotEmpty) return values.first.lengthMeasure;

    return null;
  }

  @override
  String toString() {
    return 'Setting{id: $id, name: $name, orderedPosition: $orderedPosition, disciplineID: $disciplineID, values: $values';
  }

  String printComplete() {
    String result = 'Setting{id: $id, name: $name, disciplineID: $disciplineID';
    result += '\n settingEntries: ';
    for (SettingEntry settingEntry in values) {
      result += '\n';
      result += settingEntry.printComplete();
    }
    result += '}';
    return result;
  }

  @override
  int getID() {
    return id;
  }
}

enum LengthMeasures { MM, CM, M }
