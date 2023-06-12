import 'package:flutter/material.dart';
import 'package:settings_app/util/ThemeContainer.dart';

class GradientBackgroundContainer extends StatelessWidget {
  final Widget child;
  final double secondStop;

  GradientBackgroundContainer({required this.child, this.secondStop = 0.5});

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints.expand(),
        decoration: new BoxDecoration(
          gradient: new LinearGradient(
              colors: getGradientColors().asList(),
              begin: FractionalOffset.topCenter,
              end: FractionalOffset.bottomCenter,
              stops: [0.0, secondStop, 1.0],
              tileMode: TileMode.clamp),
        ),
        child: child);
  }

  GradientColors getGradientColors() {
    switch (ThemeContainer().currentTheme) {
      case Themes.CYAN:
        return GradientColors(
            Color.fromRGBO(0, 172, 193, 1.0),
            Color.fromRGBO(110, 190, 200, 1.0),
            Color.fromRGBO(220, 220, 220, 1.0));
      case Themes.RED:
        return GradientColors(
            Color.fromRGBO(156, 8, 8, 1.0),
            Color.fromRGBO(240, 80, 80, 1.0),
            Color.fromRGBO(220, 220, 220, 1.0));
      case Themes.DARK:
        return GradientColors(
            Color.fromRGBO(66, 66, 66, 1.0),
            Color.fromRGBO(66, 66, 66, 1.0),
            Color.fromRGBO(66, 66, 66, 1.0));
    }
  }
}

class GradientColors {
  final Color gradientStart;
  final Color gradientMiddle;
  final Color gradientEnd;

  GradientColors(this.gradientStart, this.gradientMiddle, this.gradientEnd);

  asList() {
    return [gradientStart, gradientMiddle, gradientEnd];
  }
}
