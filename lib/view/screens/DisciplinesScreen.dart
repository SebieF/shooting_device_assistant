import 'package:auto_size_text/auto_size_text.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/model/Wizard.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/DialogUtil.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/view/custom_widgets/BlinkingIcon.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';
import 'package:settings_app/view/dialogs/DisciplineSelectingDialog.dart';
import 'package:settings_app/view/dialogs/WizardSelectingDialog.dart';

import 'DisciplineTabScreen.dart';
import 'WizardScreen.dart';

class DisciplineScreen extends StatefulWidget {
  final Device device;

  DisciplineScreen(this.device) : super();

  @override
  _DisciplineScreenState createState() => _DisciplineScreenState();
}

class _DisciplineScreenState extends State<DisciplineScreen> {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  _DisciplineScreenState();

  List<Wizard> _wizards = []; //DUMMY LIST FOR CREATING A WIZARD
  Discipline? _tappedDiscipline;
  Discipline? _longPressedDiscipline;
  bool blinkButtonPressed = false;
  int oldLength = 0;
  List<TabItem> tabs = [];

  @override
  void initState() {
    super.initState();
    widget.device.sortDisciplines();
    tabs = [];
    tabs
      ..add(
          TabItem(icon: Icons.arrow_back, title: allTranslations.text("back")))
      ..add(TabItem(
          icon: BlinkingIcon(shouldBlink: shouldBlink, icon: Icons.add_circle),
          title: allTranslations.text("new_discipline")));
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
        initialActiveIndex: 1,
        onTap: (int i) => {
          if (i == 0) Navigator.of(context).pop(), //BACK
          if (i == 1) addDiscipline(), // ADD
        },
      ),
      body: GradientBackgroundContainer(
        child: Column(
          children: <Widget>[
            // *** HEADING ***:
            Padding(
                padding: EdgeInsets.only(
                    top: SizeConfig.safeBlockVertical(context) * 3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Center(
                    child: AutoSizeText(widget.device.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(color: Theme.of(context).colorScheme.secondary),
                        textAlign: TextAlign.center,
                        maxLines: 1),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: AutoSizeText(
                        allTranslations.text("available_disciplines"),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                        maxLines: 2),
                  ),
                ),
              ],
            ),
            Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),
            Row(
              // this stretch carries | expansion to <--> Expanded children
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    flex: 1,
                    child: Center(
                      child: _buildDisciplineList(),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplineList() {
    List<Discipline> disciplinesWithoutConfigurations = [];
    widget.device.disciplines.forEach((element) {
      if (!element.isConfiguration)
        disciplinesWithoutConfigurations.add(element);
    });
    return LimitedBox(
      maxHeight: SizeConfig.safeBlockVertical(context) * 55,
      child: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext _context, int i) {
            if (i.isOdd) {
              return Padding(padding: const EdgeInsets.all(15));
            }
            final int index = i ~/ 2;
            if (index < disciplinesWithoutConfigurations.length) {
              return _buildCircleDiscipline(
                  disciplinesWithoutConfigurations[index]);
            }
            return null;
          }),
    );
  }

  Widget _buildCircleDiscipline(Discipline discipline) {
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          LimitedBox(
            maxWidth: SizeConfig.safeBlockHorizontal(context) * 10.0,
            maxHeight: SizeConfig.safeBlockVertical(context) * 10.0,
            child: CircleAvatar(
              minRadius: SizeConfig.safeBlockVertical(context) * 20.0,
              maxRadius: SizeConfig.safeBlockVertical(context) * 20.0,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  discipline.assetImageName(),
                  width: SizeConfig.safeBlockHorizontal(context) * 20.0,
                  height: SizeConfig.safeBlockVertical(context) * 20.0,
                ),
              ),
            ),
          ),
          Text(
            discipline.formatDisciplineName(),
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
      onTap: () => onDisciplineTapped(discipline),
      onLongPress: () => {
        _longPressedDiscipline = discipline,
        showDeleteSnackBar(),
      },
    );
  }

  void showWizardDialog() {
    _wizards = [];
    showDialog(
      context: context,
      builder: (BuildContext context) => WizardSelectingDialog(
        allTranslations.text("show_wizard"),
        allTranslations.text("show_wizard_description"),
        allTranslations.text("abort"),
        _wizards,
        onCloseWizard,
        context
      ),
    );
  }

  void showWizardScreen(Wizard wizard) async {
    await askForPermissions();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return WizardScreen(wizard);
    }));
  }

  void showDisciplineSettingsScreen(Discipline discipline) async {
    await askForPermissions();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return DisciplineTabScreen(discipline);
    }));
  }

  void showDeleteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Theme.of(context).highlightColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () => DialogUtil.showSureToRemoveDialog(
                      context, deleteDiscipline),
                  child: Icon(Icons.delete, size: 80)),
            ],
          )),
    );
  }

  void addDiscipline() {
    oldLength = widget.device.disciplines.length;
    setState(() {
      blinkButtonPressed = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) => DisciplineSelectingDialog(
          allTranslations.text("add_discipline"),
          allTranslations.text("add_discipline_description"),
          allTranslations.text("abort"),
          widget.device.disciplines,
          onCloseDialog,
          context,
          widget.device),
    );
  }

  void deleteDiscipline() {
    if (_longPressedDiscipline != null) {
      setState(() {
        widget.device.sorting = false;
        widget.device.disciplines.remove(_longPressedDiscipline);
        removeAllConfigurations(_longPressedDiscipline!);
        _longPressedDiscipline = null;
        if (widget.device.disciplines.length == 0) {
          blinkButtonPressed = false;
        }
      });
    }
  }

  void removeAllConfigurations(Discipline discipline) {
    List<Discipline> configsToRemove = [];
    for (Discipline config in widget.device.disciplines) {
      if (config.isConfiguration && discipline.name == config.name) {
        configsToRemove.add(config);
      }
    }

    for (Discipline config in configsToRemove) {
      widget.device.disciplines.remove(config);
    }
  }

  void onDisciplineTapped(Discipline discipline) {
    if (discipline.settings.length == 0) {
      _tappedDiscipline = discipline;
      if (Wizard.wizardExists(
          widget.device.deviceCategory, _tappedDiscipline!.name)) {
        showWizardDialog();
        return;
      }
    }
    showDisciplineSettingsScreen(discipline);
  }

  void startWizard() {
    if (_tappedDiscipline != null) {
      Wizard wizard = Wizard(widget.device.deviceCategory,
          _tappedDiscipline!.name, _tappedDiscipline);
      showWizardScreen(wizard);
    }
  }

  void onCloseWizard() {
    if (_tappedDiscipline != null) {
      if (_wizards.length > 0) {
        startWizard();
      } else {
        setState(() {});
        showDisciplineSettingsScreen(_tappedDiscipline!);
      }
    }
  }

  void onCloseDialog() {
    setState(() {
      // SHOW UPDATED LIST
      widget.device.sortDisciplines();
    });
  }

  Future<void> askForPermissions() async {
    var statusCamera = await Permission.camera.status;
    if (statusCamera.isDenied) {
      await Permission.camera.request();
    }
    var statusFiles = await Permission.storage.status;
    if (statusFiles.isDenied) {
      await Permission.storage.request();
    }
  }

  bool shouldBlink() {
    return !blinkButtonPressed && widget.device.disciplines.length == 0;
  }
}
