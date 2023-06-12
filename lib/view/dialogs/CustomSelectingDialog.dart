import 'package:flutter/material.dart';
import 'package:settings_app/model/Wizard.dart';

abstract class CustomSelectingDialog<T> extends StatelessWidget{
  final String title, description, buttonText;
  final List<T> listToAddSelectionTo; // DeviceS / DISCIPLINES
  final Function() onClose;
  final BuildContext context;

  CustomSelectingDialog(this.title, this.description,
    this.buttonText, this.listToAddSelectionTo, this.onClose, this.context);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Consts.padding),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(),
    );
  }

  Stack dialogContent(); //abstract

  void addSelectionToList(T selection) {
    listToAddSelectionTo.add(selection);
    Navigator.of(context).pop();
    //DOUBLE CLOSE:
    if(selection is Wizard)
      Navigator.of(context).pop();

    onClose();
  }

}

class Consts {
  Consts._();

  static const double padding = 16.0;
  static const double avatarRadius = 38.0;
}