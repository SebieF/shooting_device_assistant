import 'package:flutter/material.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/view/dialogs/CustomSelectingDialog.dart';

import '../../util/SizeConfig.dart';

class DisciplineSelectingDialog extends CustomSelectingDialog {
  final Device _device;

  DisciplineSelectingDialog(
      String title,
      String description,
      String buttonText,
      List<Discipline> listToAddSelectionTo,
      Function() onClose,
      BuildContext context,
      this._device)
      : super(title, description, buttonText, listToAddSelectionTo, onClose,
            context);

  @override
  Stack dialogContent() {
    double avatarRadius = SizeConfig.safeBlockVertical(context) * 10.0;
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            top: avatarRadius + Consts.padding,
            bottom: Consts.padding,
            left: Consts.padding,
            right: Consts.padding,
          ),
          margin: EdgeInsets.only(top: avatarRadius),
          decoration: BoxDecoration(
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
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Flexible(
                flex: 4,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Flexible(
                flex: 10,
                child: _buildDisciplineList(allRemainingDisciplines()),
              ),
              Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // To close the dialog
                    },
                    child: Text(
                      buttonText,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          !.copyWith(fontSize: 16.0),
                    ),
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
            //backgroundImage: AssetImage("assets/logo/logoApp.png"),// Icon(Icons.add, color: Theme.of(context).accentColor, size: 48.0,),
            backgroundColor: Theme.of(context).primaryColor,
            radius: avatarRadius,
          ),
        ),
      ],
    );
  }

  List<Discipline> allRemainingDisciplines() {
    //REMOVE ALREADY ADDED DISCIPLINES:
    List<Discipline> disciplines = Discipline.getAllPredefinedDisciplines();
    List<Discipline> toDelete = [];
    for (Discipline discipline in listToAddSelectionTo) {
      for (Discipline predef in disciplines) {
        if (predef.name == discipline.name) {
          toDelete.add(predef);
        }
      }
    }
    for (Discipline delete in toDelete) {
      disciplines.remove(delete);
    }
    return disciplines;
  }

  Widget _buildDisciplineList(List<Discipline> disciplines) {
    return LimitedBox(
      maxHeight: SizeConfig.blockSizeVertical(context) * 50,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext _context, int i) {
            if (i.isOdd) {
              return Padding(padding: const EdgeInsets.all(15));
            }
            final int index = i ~/ 2;
            if (index < disciplines.length) {
              return _buildCircleDiscipline(disciplines, index);
            }
            return null;
          }),
    );
  }

  Widget _buildCircleDiscipline(var disciplines, int disciplineIndex) {
    Discipline discipline;
    if (disciplineIndex < disciplines.length) {
      discipline = disciplines[disciplineIndex];

      return new GestureDetector(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            LimitedBox(
              maxWidth: SizeConfig.blockSizeHorizontal(context) * 15.0,
              maxHeight: SizeConfig.blockSizeVertical(context) * 15.0,
              child: CircleAvatar(
                minRadius: SizeConfig.blockSizeVertical(context) * 15.0,
                maxRadius: SizeConfig.blockSizeVertical(context) * 15.0,
                backgroundColor: Theme.of(context).cardColor,
                child: ClipOval(
                  child: Image.asset(
                    discipline.assetImageName(),
                    width: SizeConfig.blockSizeVertical(context) * 10.0,
                    height: SizeConfig.blockSizeVertical(context) * 10.0,
                  ),
                ),
              ),
            ),
            Expanded(
                child: Text(
              discipline.formatDisciplineName(),
              style: Theme.of(context).textTheme.bodyMedium,
            )),
          ],
        ),
        onTap: () => addDisciplineToList(discipline),
      );
    } else {
      return Container();
    }
  }

  void addDisciplineToList(Discipline discipline) async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    int disciplineID = await databaseConverter.getNextDisciplineID();
    discipline.id = disciplineID;
    discipline.deviceID = _device.id;
    discipline.belongingDevice = _device;
    addSelectionToList(discipline);
  }
}
