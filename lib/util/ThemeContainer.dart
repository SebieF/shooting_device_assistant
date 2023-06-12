import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeContainer with ChangeNotifier {
  Themes currentTheme = Themes.CYAN;
  static Color primaryColorCyan = Colors.cyan[600]!;
  static Color primaryColorRed = Color.fromRGBO(180, 8, 8, 1.0);
  static Color primaryColorDark = Color.fromRGBO(66, 66, 66, 1.0);

  static final ThemeContainer _instance = ThemeContainer._();

  ThemeContainer._();

  factory ThemeContainer() {
    return _instance;
  }

  void switchTheme(String themeString) async {
    Themes? themeToSwitch = _getThemeByString(themeString);
    if (themeToSwitch == null) {
      print("Theme not found! Not setting new theme.");
    } else {
      if (themeToSwitch != currentTheme) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        sharedPreferences.setString("current_theme", themeString);

        currentTheme = themeToSwitch;
        notifyListeners();
      }
    }
  }

  Themes? _getThemeByString(String theme) {
    final String cyan = Themes.CYAN.toString();
    final String red = Themes.RED.toString();
    final String dark = Themes.DARK.toString();

    if (theme == cyan) return Themes.CYAN;

    if (theme == red) return Themes.RED;

    if (theme == dark) return Themes.DARK;

    return null;
  }

  ThemeData getCurrentTheme() {
    switch (currentTheme) {
      case Themes.CYAN:
        return _getCyanTheme();
      case Themes.RED:
        return _getRedTheme();
      case Themes.DARK:
        return _getDarkTheme();
    }
  }

  ThemeData _getCyanTheme() {
    currentTheme = Themes.CYAN;
    return ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.dark,
      primaryColor: Colors.cyan[600],
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(secondary: Colors.black87, brightness: Brightness.dark),
      highlightColor: Colors.transparent,
      cardColor: Colors.white,
      // Define the default font family.
      //fontFamily: 'Georgia',

      textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          titleLarge: TextStyle(fontSize: 36.0, color: Colors.white),
          titleMedium: TextStyle(
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.cyan[600]),
          labelSmall: TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
          displayLarge: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              color: Colors.black54),
          displaySmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54),

          //Device CARD, HINT
          displayMedium: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.cyan[600]),
          headlineMedium: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54),
          bodySmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      bottomAppBarTheme:
          BottomAppBarTheme(color: Color.fromRGBO(220, 220, 220, 1.0)),
    );
  }

  ThemeData _getRedTheme() {
    currentTheme = Themes.RED;
    return ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.dark,
      primaryColor: Color.fromRGBO(180, 8, 8, 1.0),
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(secondary: Colors.black87, brightness: Brightness.dark),
      highlightColor: Colors.transparent,
      cardColor: Colors.white,

      textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          titleLarge: TextStyle(fontSize: 36.0, color: Colors.white),
          titleMedium: TextStyle(
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(
              fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.red),
          labelSmall: TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
          displayLarge: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              color: Colors.black54),
          displaySmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54),

          //Device CARD, HINT
          displayMedium: TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.red),
          headlineMedium: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54),
          bodySmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      bottomAppBarTheme:
          BottomAppBarTheme(color: Color.fromRGBO(220, 220, 220, 1.0)),
    );
  }

  ThemeData _getDarkTheme() {
    currentTheme = Themes.DARK;
    return ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.dark,
      primaryColor: Color.fromRGBO(66, 66, 66, 1.0),
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(secondary: Colors.blueGrey, brightness: Brightness.dark),
      highlightColor: Colors.transparent,
      cardColor: Colors.white,

      textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          titleLarge: TextStyle(fontSize: 36.0, color: Colors.white),
          titleMedium: TextStyle(
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
          labelSmall: TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
          displayLarge: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              color: Colors.black54),
          displaySmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54),

          //Device CARD, HINT
          displayMedium: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
          headlineMedium: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.black54),
          bodySmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      bottomAppBarTheme:
          BottomAppBarTheme(color: Color.fromRGBO(220, 220, 220, 1.0)),
    );
  }
}

enum Themes { CYAN, RED, DARK }
