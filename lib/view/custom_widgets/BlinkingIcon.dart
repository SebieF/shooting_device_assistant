import 'package:flutter/material.dart';

class BlinkingIcon extends StatefulWidget {
  BlinkingIcon({required this.shouldBlink, required this.icon});

  final bool Function() shouldBlink;
  final IconData icon;

  @override
  _BlinkingIconState createState() => _BlinkingIconState(shouldBlink, icon);
}

class _BlinkingIconState extends State<BlinkingIcon>
    with SingleTickerProviderStateMixin {
  final bool Function() shouldBlink;
  final IconData icon;

  late AnimationController _animationController;

  _BlinkingIconState(this.shouldBlink, this.icon);

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    _animationController.repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldBlink()) {
      _animationController.value = 1.0;
      _animationController.stop();
    }

    return FadeTransition(
      opacity: _animationController,
      child: Icon(icon),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
