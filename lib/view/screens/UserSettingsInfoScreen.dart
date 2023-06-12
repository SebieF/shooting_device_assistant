import 'package:auto_size_text/auto_size_text.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/util/ThemeContainer.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../util/FormatUtil.dart';

class UserSettingsInfoScreen extends StatefulWidget {
  final ShakeDetector shakeDetector;

  UserSettingsInfoScreen(this.shakeDetector) : super();

  @override
  _UserSettingsInfoScreenState createState() => _UserSettingsInfoScreenState();
}

class _UserSettingsInfoScreenState extends State<UserSettingsInfoScreen> {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final List<TabItem> tabs = [
    TabItem(icon: Icons.arrow_back, title: allTranslations.text("back"))
  ];
  final String githubURL = "https://github.com/SebieF/shooting_device_assistant";
  final String paypalURL = "https://paypal.me/Sebie552";

  String _selectedLanguage = allTranslations.currentLanguage;
  late Future<bool> feedbackEnabled;

  _UserSettingsInfoScreenState();

  @override
  void initState() {
    super.initState();
    feedbackEnabled = getEnableFeedback();
  }

  Future<bool> getEnableFeedback() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? enableFeedbackPref =
        sharedPreferences.get("enable_feedback") as String?;
    if (enableFeedbackPref != null) {
      return FormatUtil.str2bool(enableFeedbackPref);
    } else {
      setEnableFeedback(true.toString());
      return true;
    }
  }

  Future<bool> setEnableFeedback(String value) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();

    bool enabled = FormatUtil.str2bool(value);
    if (enabled) {
      widget.shakeDetector.startListening();
    } else {
      widget.shakeDetector.stopListening();
    }
    feedbackEnabled = Future.value(enabled);
    return sharedPreferences.setString("enable_feedback", value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      bottomNavigationBar: ConvexAppBar(
        items: tabs,
        activeColor: Theme.of(context).primaryColor,
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        initialActiveIndex: 0,
        // BACK
        onTap: (int i) => {
          if (i == 0) Navigator.of(context).pop(), //BACK
        },
      ),
      body: GradientBackgroundContainer(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(
                      top: SizeConfig.safeBlockVertical(context) * 3)),
              _buildLanguageSelection(),
              _buildThemeSelection(),
              Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),
              SizedBox(height: SizeConfig.safeBlockVertical(context) * 2.0),
              SizedBox(height: SizeConfig.safeBlockVertical(context) * 1.0),
              SizedBox(height: SizeConfig.safeBlockVertical(context) * 5.0),
              Text(allTranslations.text("info"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall),
              _buildEnableFeedback(),
              Container(height: 5),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelection() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      ElevatedButton(
        child: Text(allTranslations.text("red").toUpperCase()),
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary),
        onPressed: () => switchTheme(Themes.RED),
      ),
      Container(width: 5),
      ElevatedButton(
        child: Text(allTranslations.text("blue").toUpperCase()),
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary),
        onPressed: () => switchTheme(Themes.CYAN),
      ),
      Container(width: 5),
      ElevatedButton(
        child: Text(allTranslations.text("dark").toUpperCase()),
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary),
        onPressed: () => switchTheme(Themes.DARK),
      ),
    ]);
  }

  void switchTheme(theme) async {
    ThemeContainer().switchTheme(theme.toString());
  }

  Widget _buildLanguageSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        DropdownButton<String>(
          hint: Text(
            allTranslations.text("selected_language") +
                ": \t" +
                _selectedLanguage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: _selectedLanguage,
          onChanged: (String? language) {
            setState(() {
              _selectedLanguage = language!;
              allTranslations.setNewLanguage(_selectedLanguage);
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (BuildContext context) {
                return UserSettingsInfoScreen(widget.shakeDetector);
              }));
            });
          },
          items: allTranslations.supportedLanguages().map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Row(
                children: <Widget>[
                  ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 25, maxWidth: 25),
                      child: Image(
                        image: Image.asset("assets/flags/" + language + ".png")
                            .image,
                      )),
                  SizedBox(
                    width: 25,
                  ),
                  Text(
                    language,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEnableFeedback() {
    return FutureBuilder(
      future: feedbackEnabled,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: snapshot.data,
                onChanged: (bool? enabled) => setState(() {
                  setEnableFeedback(enabled!.toString());
                }),
              ),
              AutoSizeText(
                allTranslations.text("enable_feedback"),
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall,
              )
            ],
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: SizeConfig.screenWidth(context) * 0.5,
            height: SizeConfig.screenWidth(context) * 0.2,
            child: ElevatedButton(
              onPressed: () {
                showLicensePage(
                    context: context,
                    applicationIcon: SizedBox(
                        height: SizeConfig.safeBlockVertical(context) * 20,
                        width: SizeConfig.safeBlockHorizontal(context) * 30,
                        child: Image.asset("assets/logo/logoApp.png")),
                    applicationName: allTranslations.text("app_title"));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.file_present),
                  AutoSizeText(allTranslations.text("show_licenses"),
                      maxLines: 1),
                ],
              ),
            ),
          ),
          Container(height: 5),
          SizedBox(
            width: SizeConfig.screenWidth(context) * 0.5,
            height: SizeConfig.screenWidth(context) * 0.2,
            child: ElevatedButton(
              onPressed: () => _launchURL(githubURL),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.link),
                  AutoSizeText(allTranslations.text("show_website"),
                      maxLines: 1),
                ],
              ),
            ),
          ),
          Container(height: 5),
          SizedBox(
            width: SizeConfig.screenWidth(context) * 0.5,
            height: SizeConfig.screenWidth(context) * 0.2,
            child: ElevatedButton(
              onPressed: () => _launchURL(paypalURL),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.paypal),
                  AutoSizeText(allTranslations.text("donate"), maxLines: 1),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }
}
