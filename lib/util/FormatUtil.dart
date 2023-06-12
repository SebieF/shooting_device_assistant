import 'package:flutter/material.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/translations.dart';

class FormatUtil {

  static String noValueString() {
    return allTranslations.text("set_value");
  }

  static String formatValue(dynamic n, LengthMeasures? lengthMeasure) {
    if(n == null)
      return noValueString(); //NO VALUE

    if(double.tryParse(n.toString()) != null) {
      double nD = double.parse(n.toString());
      String doublePart = nD.toStringAsFixed(nD.truncateToDouble() == nD ? 1 : 2);
      String lengthPart = formatLengthMeasure(lengthMeasure);
      return doublePart + " " + lengthPart;
    }
    else return n.toString();
  }

  static String formatLengthMeasure(LengthMeasures? lengthMeasure) {
    switch(lengthMeasure) {
      case LengthMeasures.MM:
        return "mm";
      case LengthMeasures.CM:
        return "cm";
      case LengthMeasures.M:
        return "m";
      case null:
        return "";
    }
  }

  static Color? formatColorInput(String colorInput) {
    String formattedColorInput = colorInput.trim().toLowerCase();
    String Function(String) tl = (String jsonName) => allTranslations.text(jsonName);
    Map<String, Color> colorMap = {
      tl("yellow"): Colors.yellowAccent,
      tl("red"): Colors.red,
      tl("blue"): Colors.blueAccent,
      tl("green"): Colors.green,
      tl("orange"): Colors.yellow,
      tl("grey"): Colors.grey,
      tl("light_grey"): Colors.grey[50]!,
      tl("white"): Colors.white
    };
    return colorMap[formattedColorInput];
  }

  static bool str2bool(String string) {
    if(["yes", "y", "true", "1", "t"].contains(string.toLowerCase())) {
      return true;
    } else {
      return false;
    }
  }

}