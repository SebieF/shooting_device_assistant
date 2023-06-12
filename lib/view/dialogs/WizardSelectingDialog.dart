import 'package:flutter/material.dart';
import 'package:settings_app/model/Wizard.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/view/dialogs/CustomSelectingDialog.dart';

import '../../util/SizeConfig.dart';

class WizardSelectingDialog extends CustomSelectingDialog{

  WizardSelectingDialog(String title, String description,
      String buttonText, List<Wizard> listToAddSelectionTo, Function() onClose, context) :
        super(title, description, buttonText, listToAddSelectionTo, onClose, context);

  dialogContent() {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            top: Consts.avatarRadius + Consts.padding,
            bottom: Consts.padding,
            left: Consts.padding,
            right: Consts.padding,
          ),
          margin: EdgeInsets.only(top: Consts.avatarRadius),
          decoration: new BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.9),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(Consts.padding),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              Flexible(
                flex: 2,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Flexible(
                flex: 8,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Flexible(
                flex: 4,
                child: _buildWizardSelection(),
              ),
              Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // To close the dialog
                    },
                    child: Text(buttonText,
                      style: Theme.of(context).textTheme.bodyMedium,),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: Consts.padding,
          right: Consts.padding,
          child: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: Consts.avatarRadius,
          ),
        ),
      ],
    );
  }

  Widget _buildWizardSelection() {
    return LimitedBox(
        maxHeight: SizeConfig.blockSizeVertical(context) * 25,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            GestureDetector(
              child: Icon(
                Icons.check_circle,
                size: SizeConfig.blockSizeVertical(context) * 10,
                semanticLabel: allTranslations.text("use_wizard"),
                color: Color.fromRGBO(0, 200, 0, 1.0),
              ),
              onTap: () => addSelectionToList(Wizard.dummy()), //DUMMY WIZARD
            ),
            GestureDetector(
                child: Icon(
                    Icons.cancel,
                    size: SizeConfig.blockSizeVertical(context) * 10,
                    semanticLabel: allTranslations.text("dont_use_wizard"),
                    color: Color.fromRGBO(200, 0, 0, 1.0)
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onClose();
                }
            ),
          ],
        )
    );
  }

  void addSelectionToList(dynamic wizard) {
    listToAddSelectionTo.add(wizard);
    Navigator.of(context).pop();
    onClose();
  }

}