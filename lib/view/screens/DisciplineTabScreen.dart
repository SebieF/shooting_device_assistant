import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/model/SettingEntry.dart';
import 'package:settings_app/model/SettingImage.dart';
import 'package:settings_app/util/DialogUtil.dart';
import 'package:settings_app/view/screens/DisciplineSettingsScreen.dart';

import '../../translations.dart';

class DisciplineTabScreen extends StatefulWidget {
  final Discipline discipline;

  DisciplineTabScreen(this.discipline) : super();

  @override
  DisciplineTabScreenState createState() => DisciplineTabScreenState();
}

class DisciplineTabScreenState extends State<DisciplineTabScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  List<Tab> _tabs = [];
  List<Discipline> configurations = [];
  late TabController _tabController;
  late Discipline _currentConfiguration;
  bool addingConfiguration = false;

  DisciplineTabScreenState();

  @override
  void initState() {
    super.initState();
    _buildTabs();
  }

  void _buildTabs() {
    _tabs = [];
    configurations = [];
    configurations.add(widget.discipline);
    List<Discipline> allBelongingConfigurations = widget
        .discipline.belongingDevice
        .getAllConfigurations(widget.discipline);
    configurations.addAll(allBelongingConfigurations);
    configurations.sort((conf1, conf2) =>
        conf1.orderedConfigPosition < conf2.orderedConfigPosition ? -1 : 1);
    for (Discipline configuration in configurations) {
      Tab tab = Tab(
          key: Key(configuration.configurationName),
          child: GestureDetector(
            child: AutoSizeText(
              configuration.configurationName,
              maxLines: 2,
              minFontSize: 6,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black),
            ),
          ));
      _tabs.add(tab);
    }
    _tabController = TabController(vsync: this, length: _tabs.length);
    _currentConfiguration = configurations[_tabController.index];
    _tabController.addListener(() {
      if (addingConfiguration) {
        //Don't allow navigation when adding Configuration:
        _tabController.animateTo(_tabController.previousIndex);
      } else {
        _currentConfiguration = configurations[_tabController.index];
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        leading: Container(),
        title: Center(
          child: AutoSizeText(
            widget.discipline.formatDisciplineName(),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Theme.of(context).colorScheme.secondary),
            maxLines: 1,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: _select,
            child: Icon(
              Icons.menu,
              color: Theme.of(context).colorScheme.secondary,
            ),
            itemBuilder: (context) {
              return <PopupMenuItem>[
                PopupMenuItem(
                  child: Text(
                    allTranslations.text("copy_config"),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  value: PopupMenuChoices.COPY,
                ),
                PopupMenuItem(
                  enabled: configurations.length > 1,
                  child: Text(
                    allTranslations.text("move_config_right"),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  value: PopupMenuChoices.MOVE_RIGHT,
                ),
                PopupMenuItem(
                  enabled: configurations.length > 1,
                  child: Text(
                    allTranslations.text("move_config_left"),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  value: PopupMenuChoices.MOVE_LEFT,
                ),
                PopupMenuItem(
                  enabled: configurations.length > 1 &&
                      _currentConfiguration.isConfiguration,
                  child: Text(
                    allTranslations.text("delete_config"),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  value: PopupMenuChoices.DELETE,
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: addingConfiguration
          ? LinearProgressIndicator(
              value: null,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary),
            )
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((Tab tab) {
                return DisciplineSettingsScreen(
                    configurations[_tabs.indexOf(tab)], scaffoldState, this);
              }).toList(),
            ),
    );
  }

  void _select(dynamic choice) async {
    switch (choice) {
      case PopupMenuChoices.COPY:
        await addConfiguration();
        break;
      case PopupMenuChoices.MOVE_RIGHT:
        await shiftConfigRight(_currentConfiguration);
        break;
      case PopupMenuChoices.MOVE_LEFT:
        await shiftConfigLeft(_currentConfiguration);
        break;
      case PopupMenuChoices.DELETE:
        DialogUtil.showSureToRemoveDialog(
            context, () => deleteConfiguration(_currentConfiguration));
        break;
    }
    setState(() {});
  }

  Future<void> addConfiguration() async {
    setState(() {
      addingConfiguration = true;
    });
    DatabaseConverter databaseConverter = DatabaseConverter();
    int disciplineID = await databaseConverter.getNextDisciplineID();

    Discipline configuration = Discipline(
        disciplineID,
        _currentConfiguration.name,
        _currentConfiguration.deviceID,
        configurations.length);
    configuration.belongingDevice = _currentConfiguration.belongingDevice;
    configuration.isConfiguration = true;
    configuration.configurationName =
        allTranslations.text("default_new_configuration_name");

    //Copy all values:
    for (Setting setting in _currentConfiguration.settings) {
      int settingID = await databaseConverter.getNextSettingID();
      Setting copySetting = Setting(settingID, setting.name,
          setting.orderedPosition, configuration, disciplineID);

      if (setting.values.isNotEmpty) {
        SettingEntry latestEntry = setting.values.last;
        int settingEntryID = await databaseConverter.getNextSettingEntryID();
        SettingEntry copyEntry = SettingEntry(
            settingEntryID,
            latestEntry.dateAndValue,
            copySetting,
            latestEntry.lengthMeasure,
            settingID,
            latestEntry.notes,
            false);
        copySetting.values.add(copyEntry);

        for (SettingImage image in latestEntry.images) {
          int imageID = await databaseConverter.getNextImageID();
          SettingImage copyImage =
              SettingImage(imageID, image.fileImage, settingID, image.rotation);
          copyEntry.images.add(copyImage);
        }
      }
      configuration.settings.add(copySetting);
    }

    widget.discipline.belongingDevice.disciplines.add(configuration);

    _buildTabs();
    setState(() {
      addingConfiguration = false;
      _tabController.animateTo(_tabs.length - 1);
    });
  }

  Future<void> shiftConfigLeft(Discipline configuration) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (configuration.orderedConfigPosition != 0) {
      int oldPosition = configuration.orderedConfigPosition;
      int newPosition = oldPosition - 1;
      if (configurations.length >= newPosition) {
        await configurations[newPosition].updatePosition(oldPosition);
      }
      await configuration.updatePosition(newPosition);
      if (newPosition == 0) {
        //REFRESH, WORKAROUND FOR STRANGE BEHAVIOR IN TAB CONTROLLER
        Navigator.of(context).pop();
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (BuildContext context) {
          return DisciplineTabScreen(widget.discipline);
        }));
      } else {
        _buildTabs();
        setState(() {
          _tabController.animateTo(newPosition);
        });
      }
    }
  }

  Future<void> shiftConfigRight(Discipline configuration) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (configuration.orderedConfigPosition !=
        configurations.last.orderedConfigPosition) {
      int oldPosition = configuration.orderedConfigPosition;
      int newPosition = oldPosition + 1;
      if (configurations.length >= newPosition) {
        await configurations[newPosition].updatePosition(oldPosition);
      }
      await configuration.updatePosition(newPosition);
      _buildTabs();
      setState(() {
        _tabController.animateTo(newPosition);
      });
    }
  }

  void renameConfiguration(Discipline configuration, String name) async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    configuration.configurationName = name;
    await databaseConverter.updateDiscipline(configuration);
    int oldIndex = _tabController.index;
    _buildTabs();
    setState(() {
      _tabController.animateTo(oldIndex);
    });
  }

  void deleteConfiguration(Discipline configuration) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (configuration.isConfiguration) {
      configuration.belongingDevice.sorting = false;
      configuration.belongingDevice.disciplines.remove(configuration);
      _buildTabs();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

enum PopupMenuChoices { COPY, MOVE_RIGHT, MOVE_LEFT, DELETE }
