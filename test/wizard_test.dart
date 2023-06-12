import 'package:flutter_test/flutter_test.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/model/Wizard.dart';

void main() {
  group('Wizard', () {
    test('Basic Initialization', () {
      Wizard wizard = Wizard.dummy(
          deviceCategory: DeviceCategories.STANDARD_RIFLE,
          discipline: Disciplines.STANDING);

      expect(wizard.usedValues.length, 0);
      expect(wizard.predefinedValues.length, 21);

      for (String value in wizard.predefinedValues) {
        print(value);
      }
    });

    test('Go through whole Wizard', () {
      Wizard wizard = Wizard.dummy(
          deviceCategory: DeviceCategories.STANDARD_RIFLE,
          discipline: Disciplines.STANDING);
      while (wizard.predefinedValues.length != 0) {
        print(wizard.next());
      }
      expect(wizard.usedValues.length, 21);
      expect(wizard.predefinedValues.length, 0);
    });

    test('Go through whole Wizard, then go back, then go through it again', () {
      Wizard wizard = Wizard.dummy(
          deviceCategory: DeviceCategories.STANDARD_RIFLE,
          discipline: Disciplines.STANDING);
      while (wizard.predefinedValues.length != 0) {
        print(wizard.next());
      }

      expect(wizard.usedValues.length, 21);
      expect(wizard.predefinedValues.length, 0);
      /*
      while(wizard.usedValues.length != 0) {
        print(wizard.dummyBackForTests());
      }

      expect(wizard.usedValues.length, 0);
      expect(wizard.predefinedValues.length, 21);
      */
    });

    test('Manual test', () {
      Wizard wizard = Wizard.dummy(
          deviceCategory: DeviceCategories.STANDARD_RIFLE,
          discipline: Disciplines.STANDING);

      print(wizard.next());
      printWizard(wizard);
      print("\n");
      print(wizard.next());
      printWizard(wizard);
      print("\n");
      wizard.dummyBackForTests();
      printWizard(wizard);
    });
  });
}

void printWizard(Wizard wizard) {
  print("*** PREDEFINED VALUES");
  print("LENGTH: " + wizard.predefinedValues.length.toString());
  for (String predefValue in wizard.predefinedValues) {
    print(predefValue);
  }

  print("*** USED VALUES");
  print("LENGTH: " + wizard.usedValues.length.toString());
  for (String predefValue in wizard.usedValues) {
    print(predefValue);
  }
}
