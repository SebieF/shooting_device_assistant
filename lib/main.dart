import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:settings_app/translations.dart';
import 'package:settings_app/util/ThemeContainer.dart';
import 'package:settings_app/view/screens/SplashScreen.dart';
import 'package:settings_app/view/screens/WelcomeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await allTranslations.init("de");
  runApp(SettingApp());
}

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
        seconds: 2,
        navigateAfterSeconds: WelcomeScreen(),
        title: Text('',),
        image: Image.asset("assets/logo/logoApp.png"),
        //backgroundColor: primaryColor,
        styleTextUnderTheLoader: new TextStyle(),
        photoSize: 80.0,
        loaderColor: Colors.transparent //Not visible
    );
  }
}

class SettingApp extends StatefulWidget {

  SettingApp() : super();

  @override
  _SettingAppState createState() => _SettingAppState();
}

class _SettingAppState extends State<SettingApp> {
  final ThemeContainer _themeContainer = ThemeContainer();

  @override
  void initState() {
    super.initState();
    initThemeContainer();
  }

  Future<void> initThemeContainer() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.get("current_theme") != null) {
      _themeContainer.switchTheme(sharedPreferences.get("current_theme").toString());
    }
    _themeContainer.addListener(() { setState(() {});});
  }

  @override
  Widget build(BuildContext context) {
    return BetterFeedback(
      child: MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: allTranslations.supportedLocales(),
          theme: _themeContainer.getCurrentTheme(),
          title: allTranslations.text("title"),

          home: Splash(),
        ),
    );
  }
}