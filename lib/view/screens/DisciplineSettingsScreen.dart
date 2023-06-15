import 'dart:io';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:reorderables/reorderables.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Discipline.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/model/SettingEntry.dart';
import 'package:settings_app/model/SettingImage.dart';
import 'package:settings_app/util/FormatUtil.dart';
import 'package:settings_app/util/PDFCreator.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/util/ThemeContainer.dart';
import 'package:settings_app/view/custom_widgets/BlinkingIcon.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';
import 'package:settings_app/view/screens/DisciplineTabScreen.dart';

import '../../translations.dart';
import 'DetailedSettingsScreen.dart';
import 'PDFScreen.dart';

class DisciplineSettingsScreen extends StatefulWidget {
  final Discipline configuration;
  final GlobalKey<ScaffoldState> scaffoldParentState;
  final DisciplineTabScreenState tabScreen;

  DisciplineSettingsScreen(
      this.configuration, this.scaffoldParentState, this.tabScreen)
      : super();

  @override
  _DisciplineSettingsState createState() => _DisciplineSettingsState();
}

class _DisciplineSettingsState extends State<DisciplineSettingsScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  bool blinkButtonPressed = false;
  int changeToPosition = 0;

  late List<TabItem> tabs;
  late List<Widget> _rows;
  late List<Setting> _sortedSettings;

  _DisciplineSettingsState();

  @override
  void initState() {
    super.initState();
    _buildTabs();
    _buildRows();
  }

  void _buildTabs() {
    tabs = [
      TabItem(icon: Icons.arrow_back, title: allTranslations.text("back")),
      TabItem(
          icon: Icons.edit, title: allTranslations.text("change_config_name")),
      TabItem(
          icon: Icons.picture_as_pdf, title: allTranslations.text("print_pdf")),
      TabItem(
          icon: BlinkingIcon(shouldBlink: shouldBlink, icon: Icons.add_circle),
          title: allTranslations.text("new_setting"))
    ];
  }

  void _buildRows() {
    _rows = [];
    _sortedSettings = [];
    _sortedSettings.addAll(widget.configuration.settings);
    _sortedSettings.sort((setting1, setting2) =>
        setting1.orderedPosition <= setting2.orderedPosition ? -1 : 1);

    for (Setting setting in _sortedSettings) {
      _rows.add(_buildRow(setting));
    }
    cleanUpOrderedPositions();
  }

  void cleanUpOrderedPositions() async {
    int i = 0;
    for (Setting setting in _sortedSettings) {
      setting.updatePosition(i);
      i++;
    }
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
        initialActiveIndex: 3,
        onTap: (int i) => {
          if (i == 0) Navigator.of(context).pop(), //BACK
          if (i == 1) _showEditNameDialog(), // EDIT NAME
          if (i == 2) createPDF(), // PDF
          if (i == 3) _showAddSettingDialog(), // ADD
        },
      ),
      body: GradientBackgroundContainer(
        child: Center(
          child: _buildSettings(widget.configuration),
        ),
        secondStop: 0.0,
      ),
    );
  }

  Widget _buildSettings(Discipline discipline) {
    void _onReorder(int oldIndex, int newIndex) async {
      changeToPosition = newIndex;
      Widget row = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, row);

      for (int i = 0; i < _rows.length; i++) {
        for (Setting setting in discipline.settings) {
          if (setting.key == _rows[i].key) {
            await setting.updatePosition(i);
            break;
          }
        }
      }
      setState(() {});
    }

    ScrollController _scrollController = ScrollController(
        initialScrollOffset:
            changeToPosition * SizeConfig.safeBlockVertical(context) * 10);
    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverAppBar(
            leading: Container(), //no back icon
            expandedHeight: SizeConfig.safeBlockVertical(context) * 30,
            flexibleSpace: FlexibleSpaceBar(
              title: discipline.generalEntryForImage == null ||
                      discipline.generalEntryForImage!.images.isEmpty
                  ? TextButton(
                      child: Text(allTranslations.text("pick_overview_image"),
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                      onPressed: showImageSnackBar,
                    )
                  : Container(),
              background: discipline.generalEntryForImage == null ||
                      discipline.generalEntryForImage!.images.isEmpty
                  ? Image.asset("assets/images/no_general_image.png")
                  : GestureDetector(
                      child: RotationTransition(
                        turns: AlwaysStoppedAnimation(discipline
                                .generalEntryForImage!.images[0].rotation /
                            360),
                        child: PhotoView(
                          imageProvider: discipline
                              .generalEntryForImage!.images[0].fileImage,
                        ),
                      ),
                      onLongPress: showImageSnackBar,
                    ),
            )),
        ReorderableSliverList(
          delegate: ReorderableSliverChildListDelegate(_rows),
          onReorder: _onReorder,
        )
      ],
    );
  }

  Widget _buildRow(Setting setting) {
    Key key = Key(setting.hashCode.toString());
    setting.key = key;
    return Column(
      key: key,
      children: <Widget>[
        ListTile(
          title: Text(setting.name,
              style: ThemeContainer()
                  .getCurrentTheme()
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 20.0)),
          trailing: Text(
            FormatUtil.formatValue(
                setting.getLatestValue, setting.getCurrentLengthMeasure()),
          ),
          onTap: () => showDetailedSettingsScreen(setting),
        ),
        Divider(),
      ],
    );
  }

  void _showAddSettingDialog() async {
    setState(() {
      blinkButtonPressed = true;
    });
    final textController = TextEditingController();
    await showDialog<String>(
      context: context,
      builder: (buildContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: allTranslations.text("new_setting"),
                      labelStyle: Theme.of(context).textTheme.titleMedium,
                      hintText: allTranslations.text("new_setting_hint")),
                ),
              )
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
                  addSetting(textController.text);
                  Navigator.of(context, rootNavigator: true).pop();
                })
          ],
        );
      },
    );
  }

  void _showEditNameDialog() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final textController = TextEditingController();
    await showDialog<String>(
      context: context,
      builder: (buildContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Row(
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
                  widget.tabScreen.renameConfiguration(
                      widget.configuration, textController.text);
                  Navigator.of(context, rootNavigator: true).pop();
                })
          ],
        );
      },
    );
  }

  void createPDF() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    File file = await PDFCreator.createPDF(widget.configuration);
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PDFScreen(pathPDF: file.path)));
  }

  void showDetailedSettingsScreen(Setting setting) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return DetailedSettingsScreen(setting);
    })).then((value) => setState(() {
              _buildRows();
            }));
  }

  void addSetting(String name) async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    int nextSettingID = await databaseConverter.getNextSettingID();
    setState(() {
      int position = 0;
      if (widget.configuration.settings.isNotEmpty)
        position = _sortedSettings.last.orderedPosition + 1;
      widget.configuration.settings.add(Setting(nextSettingID, name, position,
          widget.configuration, widget.configuration.id));
      _buildRows();
    });
  }

  void showImageSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Theme.of(context).highlightColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () => getGeneralImage(ImageSource.camera),
                  child: Icon(
                    Icons.camera_alt,
                    size: 80,
                  )),
              SizedBox(width: 2),
              GestureDetector(
                  onTap: () => getGeneralImage(ImageSource.gallery),
                  child: Icon(Icons.insert_drive_file, size: 80)),
              SizedBox(width: 2),
              Visibility(
                visible: widget.configuration.generalEntryForImage != null &&
                    widget
                        .configuration.generalEntryForImage!.images.isNotEmpty,
                child: GestureDetector(
                    onTap: () => rotateImage(),
                    child: Icon(Icons.rotate_right, size: 80)),
              ),
              SizedBox(width: 2),
              Visibility(
                visible: widget.configuration.generalEntryForImage != null,
                child: GestureDetector(
                    onTap: () => deleteImage(),
                    child: Icon(Icons.delete, size: 80)),
              ),
            ],
          )),
    );
  }

  Future getGeneralImage(ImageSource imageSource) async {
    try {
      var picker = ImagePicker();
      var image = await picker.pickImage(source: imageSource);

      if (image == null) {
        print("No picture selected");
        return;
      }

      if (imageSource == ImageSource.camera) {
        await GallerySaver.saveImage(image.path,
            albumName: "ShootingDeviceAssistant");
      }
      File file = File(image.path);

      DatabaseConverter databaseConverter = DatabaseConverter();
      int nextImageID = await databaseConverter.getNextImageID();
      int nextSettingEntryID = await databaseConverter.getNextSettingEntryID();

      SettingEntry generalImageEntry = SettingEntry(nextSettingEntryID, null,
          null, null, widget.configuration.id, "", true);
      SettingImage settingImage =
          SettingImage(nextImageID, FileImage(file), nextSettingEntryID, 0);
      generalImageEntry.images.add(settingImage);
      await widget.configuration.addGeneralSettingImage(generalImageEntry);
      setState(() {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    } catch (exception) {
      print("No picture selected");
    }
  }

  void rotateImage() async {
    widget.configuration.generalEntryForImage!.images[0].rotation += 90;
    if (widget.configuration.generalEntryForImage!.images[0].rotation == 360)
      widget.configuration.generalEntryForImage!.images[0].rotation = 0;
    DatabaseConverter databaseConverter = DatabaseConverter();
    await databaseConverter
        .updateImage(widget.configuration.generalEntryForImage!.images[0]);
    setState(() {});
  }

  void deleteImage() async {
    if (widget.configuration.generalEntryForImage != null) {
      await widget.configuration.deleteCurrentSettingImage();
      setState(() {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    }
  }

  bool shouldBlink() {
    return !blinkButtonPressed && widget.configuration.settings.length == 0;
  }
}
