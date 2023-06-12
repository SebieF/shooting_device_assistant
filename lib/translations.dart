import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _storageKey = "SettingsApp_";
const List<String> _supportedLanguages = ['en', 'de'];
Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

class GlobalTranslations {
  Locale? _locale;
  Map<dynamic, dynamic>? _localizedValues;
  VoidCallback? _onLocaleChangedCallback;

  Iterable<Locale> supportedLocales() =>
      _supportedLanguages.map<Locale>((lang) => Locale(lang, ''));

  List<String> supportedLanguages() => _supportedLanguages;

  get currentLanguage => _locale == null ? '' : _locale!.languageCode;

  get locale => _locale;

  String text(String key) {
    // Return the requested string
    if (_localizedValues != null) {
      return (_localizedValues![key] == null)
          ? '** $key not found'
          : _localizedValues![key];
    } else {
      return '** $key not found';
    }
  }

  Future<Null> init(String language) async {
    if (_locale == null) {
      await setNewLanguage(language);
    }
    return null;
  }

  Future<String> getPreferredLanguage() async {
    return _getApplicationSavedInformation('language');
  }

  Future<bool> setPreferredLanguage(String lang) async {
    return _setApplicationSavedInformation('language', lang);
  }

  Future<Null> setNewLanguage(String newLanguage,
      {bool saveInPrefs = true}) async {
    String language = newLanguage;
    if (language == "") {
      language = await getPreferredLanguage();
    }

    // Set the locale
    if (language == "") {
      language = "de";
    }
    _locale = Locale(language, "");

    // Load the language strings
    String jsonContent = await rootBundle
        .loadString("locale/i18n_${_locale!.languageCode}.json");
    _localizedValues = json.decode(jsonContent);

    if (saveInPrefs) {
      await setPreferredLanguage(language);
    }

    if (_onLocaleChangedCallback != null) {
      _onLocaleChangedCallback!();
    }

    return null;
  }

  set onLocaleChangedCallback(VoidCallback callback) {
    _onLocaleChangedCallback = callback;
  }

  Future<String> _getApplicationSavedInformation(String name) async {
    final SharedPreferences prefs = await _prefs;

    return prefs.getString(_storageKey + name) ?? '';
  }

  Future<bool> _setApplicationSavedInformation(
      String name, String value) async {
    final SharedPreferences prefs = await _prefs;

    return prefs.setString(_storageKey + name, value);
  }

  static final GlobalTranslations _translations =
      new GlobalTranslations._internal();

  factory GlobalTranslations() {
    return _translations;
  }

  GlobalTranslations._internal();
}

GlobalTranslations allTranslations = new GlobalTranslations();
