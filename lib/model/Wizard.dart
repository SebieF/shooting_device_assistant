import 'dart:collection';

import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/translations.dart';

class Wizard {
  final DeviceCategories deviceCategory;
  final Disciplines discipline;
  
  ListQueue<String> predefinedValues = ListQueue(); //NAME
  ListQueue<String> usedValues = ListQueue();

  late int numberOfValues;
  Discipline? disciplineToGenerate;


  Wizard(this.deviceCategory, this.discipline, this.disciplineToGenerate) {
    predefinedValues = ListQueue();
    usedValues = ListQueue();

    if(discipline == Disciplines.BODY) {
      addBodyMeasurements();
    } else {
      _createQueue();
    }
    numberOfValues = predefinedValues.length;
  }

  Wizard.dummy({this.deviceCategory = DeviceCategories.OTHER, this.discipline = Disciplines.REST}) {
    predefinedValues = ListQueue();
    usedValues = ListQueue();

    if(discipline == Disciplines.BODY) {
      addBodyMeasurements();
    } else {
      _createQueue();
    }
    numberOfValues = predefinedValues.length;
  }

  String next() {
    String nextValue = predefinedValues.removeFirst();
    usedValues.add(nextValue);
    return nextValue;
  }

  void back() {
    if (usedValues.length > 0) {
      String currentValue = usedValues.removeLast(); // Current Value
      //disciplineToGenerate.settings.removeLast(); //Current Value in Discipline
      predefinedValues.addFirst(currentValue); //2.

      if(usedValues.length > 0) {
        String lastValue = usedValues.removeLast(); // Last Value
        predefinedValues.addFirst(lastValue); //1.
        if (disciplineToGenerate!.settings.length > 0) {
          if(disciplineToGenerate!.settings.last.name == lastValue)
            disciplineToGenerate!.settings.removeLast(); //Last Value in Discipline
        }
      }
    }
  }

  void dummyBackForTests() {
    if (usedValues.length > 1) {
      String currentValue = usedValues.removeLast(); // Current Value
      String lastValue = usedValues.removeLast(); // Last Value
      predefinedValues.addFirst(currentValue);
      predefinedValues.addFirst(lastValue);
    }
  }

  bool isAtStartingPoint() {
    return usedValues.length <= 1;
  }

  int getPercentFinished() {
    if(predefinedValues.length != 0)
      return (((usedValues.length - 1) / numberOfValues) * 100).round();
    return 100;
  }

  static bool wizardExists(DeviceCategories deviceCategory, Disciplines discipline) {
    return Wizard.dummy(deviceCategory: deviceCategory, discipline: discipline).numberOfValues > 0;
  }

  void _createQueue() {
    switch(deviceCategory) {
      case DeviceCategories.AIR_RIFLE:
        airRifleQueue();
        break;
      case DeviceCategories.SMALLBORE_RIFLE:
        smallBoreRifleQueue();
        break;
      case DeviceCategories.STANDARD_RIFLE:
        smallBoreRifleQueue(); //TODO SPECIFY
        break;
      case DeviceCategories.AIR_PISTOL:
        pistolQueue();
        break;
      case DeviceCategories.RAPID_FIRE_PISTOL:
        pistolQueue();
        break;
      case DeviceCategories.OTHER:
        break;
    }
  }

  void airRifleQueue() {
    addRifleValues();
    predefinedValues
      ..remove(allTranslations.text("haken_laenge"))
      ..remove(allTranslations.text("haken_winkel"));
    addDisciplineSpecificValues();
    predefinedValues.add(allTranslations.text("gewichte"));
    predefinedValues.add(allTranslations.text("abzugsgewicht"));
    predefinedValues.add(allTranslations.text("total_weight"));
  }

  void smallBoreRifleQueue() {
    addRifleValues();
    addDisciplineSpecificValues();
    predefinedValues.add(allTranslations.text("gewichte"));
    predefinedValues.add(allTranslations.text("abzugsgewicht"));
    predefinedValues.add(allTranslations.text("total_weight"));
  }

  void pistolQueue() {
    predefinedValues.add(allTranslations.text("abzugsgewicht"));
    predefinedValues.add(allTranslations.text("total_weight"));
  }

  void addRifleValues() {
    predefinedValues
    ..add(allTranslations.text("kappe"))
    ..add(allTranslations.text("haken_laenge"))
    ..add(allTranslations.text("haken_winkel"))
    ..add(allTranslations.text("laenge"))
    ..add(allTranslations.text("backe_hoehe"))
    ..add(allTranslations.text("backe_seite"))
    ..add(allTranslations.text("backe_winkel"))
    ..add(allTranslations.text("diopter_helligkeit"))
    ..add(allTranslations.text("diopter_farbfilter"))
    ..add(allTranslations.text("diopter_position"))
    ..add(allTranslations.text("diopter_erhoehungen"))
    ..add(allTranslations.text("diopter_erhoehungen_position"))
    ..add(allTranslations.text("korngroesse"))
    ..add(allTranslations.text("korntunnel_position"))
    ..add(allTranslations.text("korntunnel_erhoehungen"))
    ..add(allTranslations.text("korntunnel_erhoehungen_position"));
  }

  void addBodyMeasurements() {
    predefinedValues
      ..add(allTranslations.text("weight"))
      ..add(allTranslations.text("size"))
      ..add(allTranslations.text("size_upper"))
      ..add(allTranslations.text("size_lower"))
      ..add(allTranslations.text("shoulder_cf"))
      ..add(allTranslations.text("breast_cf"))
      ..add(allTranslations.text("biceps_l_cf"))
      ..add(allTranslations.text("biceps_r_cf"))
      ..add(allTranslations.text("belly_cf"))
      ..add(allTranslations.text("hip_cf"))
      ..add(allTranslations.text("thigh_l_cf"))
      ..add(allTranslations.text("thigh_r_cf"));
  }

  void addDisciplineSpecificValues() {
    switch(discipline) {
      case Disciplines.KNEELING:
        predefinedValues
          ..add(allTranslations.text("handstopp_position"))
          ..add(allTranslations.text("handstopp_winkel"))
          ..add(allTranslations.text("riemen_laenge"))
          ..add(allTranslations.text("riemen_schraube"))
          ..add(allTranslations.text("kniendrolle_hoehe"));
        break;
      case Disciplines.PRONE:
        predefinedValues
          ..add(allTranslations.text("handstopp_position"))
          ..add(allTranslations.text("handstopp_winkel"))
          ..add(allTranslations.text("riemen_laenge"))
          ..add(allTranslations.text("riemen_schraube"));
        break;
      case Disciplines.STANDING:
        predefinedValues
          ..add(allTranslations.text("handstuetze_hoehe"))
          ..add(allTranslations.text("handstuetze_position"));
        break;
      case Disciplines.REST:
        predefinedValues
          ..add(allTranslations.text("auflage_position"));
        break;
      case Disciplines.BODY:

    }
  }

}