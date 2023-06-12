import 'package:auto_size_text/auto_size_text.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/model/SettingEntry.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/DialogUtil.dart';
import 'package:settings_app/util/FormatUtil.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';
import 'package:settings_app/view/custom_widgets/SettingsLineChart.dart';

import 'DetailedEntryScreen.dart';

class DetailedSettingsScreen extends StatefulWidget {
  DetailedSettingsScreen(this.setting) : super();
  final Setting setting;

  @override
  _DetailedSettingsState createState() => _DetailedSettingsState();
}

class _DetailedSettingsState extends State<DetailedSettingsScreen> {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final settingEditController = TextEditingController();
  final List<TabItem> tabs = [
    TabItem(icon: Icons.arrow_back, title: allTranslations.text("back")),
    TabItem(icon: Icons.edit, title: allTranslations.text("change_value"))
  ];
  
  bool settingIsEdited = false;
  SettingEntry? _longPressedHistoryEntry;
  bool creatingEntries = false;
  
  _DetailedSettingsState();


  @override
  void initState() {
    super.initState();
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
        // ADD
        onTap: (int i) => {
          if (i == 0) Navigator.of(context).pop(), //BACK
          if (i == 1) changeSettingValue() // Change Value
        },
      ),
      body: GradientBackgroundContainer(
        child: Center(
            child: Column(
          children: <Widget>[
            Padding(
                padding:
                    EdgeInsets.only(top: SizeConfig.safeBlockVertical(context) * 3)),
            // SETTING:
            showSettingFixedOrEdited(),
            Divider(thickness: 2),

            //DATE:
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AutoSizeText(
                  widget.setting.getLatestDate == null
                      ? ""
                      : allTranslations.text("date") +
                          ": " +
                          DateFormat(allTranslations.text("date_format"))
                              .format(widget.setting.getLatestDate!),
                  style: TextStyle(color: Colors.white),
                  maxLines: 1,
                ),
              ],
            ),
            Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),

            // *** CHART: ***
            Expanded(
              // expansion inside Column pulls contents |
              child: new Row(
                // this stretch carries | expansion to <--> Expanded children
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row -> Expanded -> Chart expands chart horizontally <-->
                  new Expanded(
                    child: buildChartSettingHistory(), // verticalBarChart, lineChart
                  ),
                ],
              ),
            ),
            Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),

            // *** HISTORY***:
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  allTranslations.text("value_history") + ":",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
            Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),
            Expanded(
              // expansion inside Column pulls contents |
              child: new Row(
                // this stretch carries | expansion to <--> Expanded children
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row -> Expanded -> Chart expands chart horizontally <-->
                  new Expanded(
                    child: _buildHistorySettings(
                        scaffoldState), // verticalBarChart, lineChart
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget showSettingFixedOrEdited() {
    if (settingIsEdited) {
      settingEditController.text = "";
      return Row(
        // *** EDITING CARD ***
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Card(
              color: Theme.of(context).cardColor,
              child: ListTile(
                title: Center(
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.setting.values.length > 0
                          ? allTranslations.text("old_value") +
                              ': ' +
                              FormatUtil.formatValue(widget.setting.getLatestValue,
                                  widget.setting.getCurrentLengthMeasure())
                          : allTranslations.text("enter_value_hint"),
                      hintStyle: Theme.of(context).textTheme.headlineMedium,
                    ),
                    controller: settingEditController,
                    onSubmitted: (_) =>
                        addNewSetting(settingEditController.text),
                    keyboardType: TextInputType.text,
                    autofocus: true,
                  ),
                ),
                onTap: () => {
                  if (!settingIsEdited)
                    showDetailedEntryScreen(widget.setting.values.last)
                },
              ),
            ),
          ),
        ],
      );
    } else {
      // *** FIXED CARD ***
      return LimitedBox(
        maxHeight: SizeConfig.safeBlockVertical(context) * 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  title: AutoSizeText(
                    createTitle(),
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    if (widget.setting.values.length > 0)
                      showDetailedEntryScreen(widget.setting.values.last);
                    else
                      changeSettingValue();
                  },
                  onLongPress: changeSettingValue,
                  trailing: LimitedBox(
                    maxHeight:
                        SizeConfig.safeBlockVertical(context) * 5,
                    child: PopupMenuButton(
                      onSelected: _select,
                      child: Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.secondary,
                        size:
                            SizeConfig.safeBlockVertical(context) * 7,
                      ),
                      itemBuilder: (context) {
                        return <PopupMenuItem>[
                          PopupMenuItem(
                            child: Text(
                              allTranslations.text("view_details"),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            value: PopupMenuChoices.VIEW,
                          ),
                          PopupMenuItem(
                            child: Text(
                              allTranslations.text("change_value"),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            value: PopupMenuChoices.CHANGE_VALUE,
                          ),
                          PopupMenuItem(
                            child: Text(
                              allTranslations.text("change_setting_name"),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            value: PopupMenuChoices.CHANGE_NAME,
                          ),
                          PopupMenuItem(
                            child: Text(
                              allTranslations
                                  .text("create_for_all_disciplines"),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            value: PopupMenuChoices.CREATE_FOR_ALL_DISCIPLINES,
                          ),
                          PopupMenuItem(
                            child: Text(
                              allTranslations.text("remove_setting"),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            value: PopupMenuChoices.REMOVE_SETTING,
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHistorySettings(GlobalKey<ScaffoldState> scaffoldState) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index < widget.setting.values.length) {
            return _buildHistoryRow(
                scaffoldState, widget.setting.values.reversed.toList()[index]);
          }
          return null;
        });
  }

  Widget _buildHistoryRow(
      GlobalKey<ScaffoldState> scaffoldState, SettingEntry entry) {
    return ListTile(
      title: Text(
        FormatUtil.formatValue(
            entry.dateAndValue.getRight, entry.lengthMeasure),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Text(
        DateFormat(allTranslations.text("date_format"))
            .format(entry.dateAndValue.getLeft), //– hh:mm
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: () => showDetailedEntryScreen(entry),
      onLongPress: () {
        _longPressedHistoryEntry = entry;
        showDeleteSnackBar(scaffoldState);
      },
    );
  }

  Widget buildChartSettingHistory() {
    // BUILD CHART ONLY IF DOUBLE VALUES AVAILABLE:
    if (creatingEntries)
      return LinearProgressIndicator(
        value: null,
      );
    else {
      if (widget.setting.values.length > 0) {
        if (widget.setting.checkIfAllValuesCanBeConvertedToDouble()) {
          //DOUBLE
          return SettingsLineChart.fromSetting(widget.setting);
        } else {
          // NOT DOUBLE
          FormatUtil.formatColorInput(
              widget.setting.values.last.dateAndValue.getRight.toString());
          return buildPieChart();
        }
      } else {
        //NO VALUES YET
        return LimitedBox(maxHeight: 5);
      }
    }
  }

  Widget buildPieChart() {
    Map<String, double> dataMap = defineDataPie();
    List<Color> colorList = buildColorList();
    return PieChart(dataMap: dataMap, colorList: colorList);
  }

  void showDeleteSnackBar(GlobalKey<ScaffoldState> scaffold) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Theme.of(context).highlightColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () => DialogUtil.showSureToRemoveDialog(
                      context, deleteHistorySetting),
                  child: Icon(Icons.delete, size: 80)),
            ],
          )),
    );
  }

  void showDetailedEntryScreen(SettingEntry settingEntry) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return DetailedEntryScreen(settingEntry);
    })).then((value) => setState(() {}));
  }

  void _select(dynamic choice) async {
    setState(() {
      switch (choice) {
        case PopupMenuChoices.VIEW:
          if (widget.setting.values.length > 0)
            showDetailedEntryScreen(widget.setting.values.last);
          break;
        case PopupMenuChoices.CHANGE_VALUE:
          changeSettingValue();
          break;
        case PopupMenuChoices.CHANGE_NAME:
          _showEditNameDialog();
          break;
        case PopupMenuChoices.CREATE_FOR_ALL_DISCIPLINES:
          createForAllDisciplines();
          break;
        case PopupMenuChoices.REMOVE_SETTING:
          DialogUtil.showSureToRemoveDialog(context, deleteWholeSetting);
          break;
      }
    });
  }

  void addNewSetting(String newSetting) async {
    if (newSetting != '') await widget.setting.addValue(newSetting);
    setState(() {
      settingIsEdited = false;
    });
  }

  void changeSettingValue() {
    setState(() {
      settingIsEdited = true;
    });
  }

  void _showEditNameDialog() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final textController = TextEditingController();
    await showDialog<String>(
      context: context,
      builder: (buildContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: allTranslations.text("new_name"),
                    labelStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
                child: Text(allTranslations.text("abort")),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                }),
            TextButton(
                child: Text(allTranslations.text("okay")),
                onPressed: () {
                  changeSettingName(textController.text);
                  Navigator.of(context, rootNavigator: true).pop();
                })
          ],
        );
      },
    );
  }

  void changeSettingName(String newName) async {
    await widget.setting.updateName(newName);
    setState(() {});
  }

  void deleteHistorySetting() {
    if (_longPressedHistoryEntry != null) {
      setState(() {
        widget.setting.values.remove(_longPressedHistoryEntry);
        _longPressedHistoryEntry = null;
        if (widget.setting.checkIfAllValuesCanBeConvertedToDouble())
          widget.setting.changeAllValuesToDouble();
      });
    }
  }

  void deleteWholeSetting() {
    widget.setting.belongingDiscipline!.settings.remove(widget.setting);
    Navigator.of(context).pop();
  }

  void createForAllDisciplines() async {
    setState(() {
      creatingEntries = true;
    });
    DatabaseConverter databaseConverter = DatabaseConverter();
    Device device = widget.setting.belongingDiscipline!.belongingDevice;
    for (Discipline discipline in device.disciplines) {
      if (discipline.id != widget.setting.belongingDiscipline!.id) {
        int id = await databaseConverter.getNextSettingID();
        int position = 0;
        List<Setting> sortedSettings = [];
        sortedSettings.addAll(discipline.settings);
        sortedSettings.sort((setting1, setting2) =>
            setting1.orderedPosition <= setting2.orderedPosition ? -1 : 1);
        if (discipline.settings.isNotEmpty)
          position = sortedSettings.last.orderedPosition + 1;

        discipline.addNewSetting(
            Setting(id, widget.setting.name, position, discipline, discipline.id));
      }
    }
    setState(() {
      creatingEntries = false;
    });
  }

  double getMinimum(List<SettingEntry> values) {
    double min = double.infinity;
    for (SettingEntry value in values) {
      if (value.dateAndValue.getRight < min) {
        min = value.dateAndValue.getRight;
      }
    }
    return min;
  }

  Map<String, double> defineDataPie() {
    Map<String, double> dataMap = new Map();
    widget.setting.values.forEach((value) {
          dataMap.putIfAbsent(
              value.dateAndValue.getRight.toString().toUpperCase(),
              () => widget.setting.getNumberOfStringOccurrences(value));
        });
    return dataMap;
  }

  List<Color> buildColorList() {
    const List<Color> defaultColorList = [
      //FROM PIE CHART
      Color(0xFFff7675),
      Color(0xFF74b9ff),
      Color(0xFF55efc4),
      Color(0xFFffeaa7),
      Color(0xFFa29bfe),
      Color(0xFFfd79a8),
      Color(0xFFe17055),
      Color(0xFF00b894),
    ];
    List<Color> result = [];
    int i = 0;
    Set<String> settingValues = Set();
    widget.setting.values.forEach(
        (value) => settingValues.add(value.dateAndValue.getRight.toString()));
    for (String value in settingValues) {
      Color? formatColor = FormatUtil.formatColorInput(value);
      if (formatColor != null) {
        result.add(formatColor);
      } else {
        result.add(defaultColorList[i % defaultColorList.length]);
        i++;
      }
    }
    return result;
  }

  String createTitle() {
    String latestValueString = FormatUtil.formatValue(
        widget.setting.getLatestValue, widget.setting.getCurrentLengthMeasure());
    return widget.setting.belongingDiscipline!.formatDisciplineName() +
        " - " +
        widget.setting.name +
        " - " +
        latestValueString;
  }
}

enum PopupMenuChoices {
  VIEW,
  CHANGE_VALUE,
  CHANGE_NAME,
  CREATE_FOR_ALL_DISCIPLINES,
  REMOVE_SETTING
}
