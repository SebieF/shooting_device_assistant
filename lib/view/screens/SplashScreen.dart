import 'dart:core';
import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';

class SplashScreen extends StatefulWidget {
  final int seconds;
  final Text title;
  final Color backgroundColor;
  final TextStyle styleTextUnderTheLoader;
  final dynamic navigateAfterSeconds;
  final double photoSize;
  final dynamic onClick;
  final Color loaderColor;
  final Image image;
  final Text loadingText;

  SplashScreen(
      {required this.loaderColor,
      required this.seconds,
      required this.photoSize,
      this.onClick,
      this.navigateAfterSeconds,
      this.title = const Text(''),
      this.backgroundColor = Colors.white,
      this.styleTextUnderTheLoader = const TextStyle(
          fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
      required this.image,
      this.loadingText = const Text("")});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: widget.seconds), () {
      if (widget.navigateAfterSeconds is String) {
        // It's fairly safe to assume this is using the in-built material
        // named route component
        Navigator.of(context).pushReplacementNamed(widget.navigateAfterSeconds);
      } else if (widget.navigateAfterSeconds is Widget) {
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => widget.navigateAfterSeconds));
      } else {
        throw new ArgumentError(
            'widget.navigateAfterSeconds must either be a String or Widget');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new GradientBackgroundContainer(
        child: Center(
          child: new InkWell(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                AnimatedTextKit(animatedTexts: [
                  FadeAnimatedText(allTranslations.text("app_title"),
                      duration: (Duration(seconds: widget.seconds)),
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center)
                ]),

                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: new Container(child: widget.image),
                  radius: widget.photoSize,
                ),

                Container(), // Centering
              ],
            ),
          ),
        ),
      ),
    );
  }
}
