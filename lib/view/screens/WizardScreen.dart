import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/model/SettingImage.dart';
import 'package:settings_app/model/Wizard.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/Tuple.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';

import '../../util/SizeConfig.dart';
import 'DisciplineTabScreen.dart';

class WizardScreen extends StatefulWidget {
  final Wizard wizard;

  WizardScreen(this.wizard) : super();

  @override
  _WizardScreenState createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  final textValuesController = TextEditingController();
  final textNotesController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  FocusNode notesFocusNode = FocusNode();

  Tuple<FileImage, int>? longPressedImage; //TUPLE FOR ROTATION
  String value = ""; //WORKAROUND FOR ASYNC DATABASE
  //CROSS FADE:
  bool switchFirst = true;
  bool switchSecond = true;
  List<Tuple<FileImage, int>> _images = []; //Left: Image, Right: Rotation

  late Setting settingToGenerate;
  WizardState state = WizardState.VALUE;

  _WizardScreenState() {}

  @override
  void initState() {
    super.initState();
    settingToGenerate = createSetting();
  }

  Setting createSetting() {
    int orderedPosition = widget.wizard.usedValues.length;
    return Setting(
        -1,
        widget.wizard.next(),
        orderedPosition,
        widget.wizard.disciplineToGenerate,
        widget.wizard.disciplineToGenerate!.id);
  }

  Column calculateTitle() {
    String valueString = value;
    return Column(
      children: <Widget>[
        AutoSizeText(
            settingToGenerate.name +
                (settingToGenerate.values.isEmpty ? "" : ":"),
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center),
        AutoSizeText(
          valueString,
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
          maxLines: 2,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        title: SizedBox(
          width: SizeConfig.screenWidth(context) / 0.75,
          child: AutoSizeText("Wizard: " +
              widget.wizard.disciplineToGenerate!.formatDisciplineName() + " " +
              widget.wizard.getPercentFinished().toString() +
              "%", maxLines: 1,),
        ),
        leading: IconButton(
          icon: Icon(Icons.cancel),
          tooltip: allTranslations.text("cancel_wizard_tooltip"),
          onPressed: () => leaveWizardWithoutSaving(),
        ),
      ),
      body: GradientBackgroundContainer(
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: calculateTitle(),
                ),
                Divider(thickness: 2.0),
                AnimatedCrossFade(
                  firstChild: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: switchFirst
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: valueSettingWidget(),
                    secondChild: notesSettingWidget(),
                  ),
                  secondChild: _buildImageSelection(),
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: switchSecond
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                ),
                Divider(thickness: 2),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.check_circle,
                                color: Color.fromRGBO(0, 200, 0, 1.0)), //green
                            tooltip: allTranslations.text("next"),
                            onPressed: handleState,
                          ),
                          TextButton(
                            child: Text(
                              allTranslations.text("next"),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            //shape: RoundedRectangleBorder(
                            //    borderRadius: new BorderRadius.circular(24.0)),
                            onPressed: handleState,
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.fast_forward,
                                color: Color.fromRGBO(255, 200, 0, 1.0)),
                            tooltip: allTranslations.text("skip"),
                            onPressed: () =>
                                showNextWizardOrFinish(true, false),
                          ),
                          TextButton(
                            child: Text(
                              allTranslations.text("skip"),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            //shape: RoundedRectangleBorder(
                            //    borderRadius: new BorderRadius.circular(24.0)),
                            onPressed: () =>
                                showNextWizardOrFinish(true, false),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.fast_rewind,
                                color: Color.fromRGBO(200, 0, 0, 1.0)),
                            tooltip: allTranslations.text("back"),
                            onPressed: back,
                          ),
                          TextButton(
                            child: Text(
                              allTranslations.text("back"),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            //shape: RoundedRectangleBorder(
                            //  borderRadius: new BorderRadius.circular(24.0)),
                            onPressed: back,
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.assignment_turned_in,
                                color: Colors.blueAccent),
                            tooltip: allTranslations.text("finish"),
                            onPressed: () =>
                                showNextWizardOrFinish(false, true),
                          ),
                          TextButton(
                            child: Text(
                              allTranslations.text("finish"),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            //shape: RoundedRectangleBorder(
                            //    borderRadius: new BorderRadius.circular(24.0)),
                            onPressed: () =>
                                showNextWizardOrFinish(false, true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget valueSettingWidget() => Container(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(allTranslations.text("value") + ":",
              style: Theme.of(context).textTheme.titleLarge),
          TextField(
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: allTranslations.text("value_hint")),
            controller: textValuesController,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
            autofocus: false,
          ),
        ],
      ));

  Widget notesSettingWidget() => Container(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(allTranslations.text("notes"),
              style: Theme.of(context).textTheme.titleLarge),
          TextField(
            focusNode: notesFocusNode,
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: allTranslations.text("notes_hint")),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            controller: textNotesController,
          ),
        ],
      ));

  Widget _buildImageSelection() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon:
                  Icon(Icons.add_a_photo, color: Color.fromRGBO(0, 0, 0, 1.0)),
              tooltip: allTranslations.text("pick_image_tooltip"),
              onPressed: () => showImageSnackBar(),
            ),
            TextButton(
              child: Text(
                allTranslations.text("pick_image"),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              //shape: RoundedRectangleBorder(
              //    borderRadius: new BorderRadius.circular(24.0)),
              onPressed: () => showImageSnackBar(),
            ),
          ],
        ),
        LimitedBox(
            maxHeight: 500,
            child: Row(
              children: <Widget>[
                _buildImageList(),
              ],
            )),
      ],
    );
  }

  Widget _buildImageList() {
    if (_images.length > 0) {
      return Expanded(
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: ClampingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemBuilder: (BuildContext _context, int i) {
              if (i.isOdd) {
                return Divider();
              }
              final int index = i ~/ 2;
              if (index < _images.length) {
                return _buildDecoratedImage(index);
              }
              return null;
            }),
      );
    } else {
      return LimitedBox(maxHeight: 5);
    }
  }

  Widget _buildDecoratedImage(int imageIndex) => GestureDetector(
        child: Container(
          margin: const EdgeInsets.all(4),
          child: _images.length < imageIndex
              ? Container()
              : RotationTransition(
                  turns: AlwaysStoppedAnimation(
                      _images[imageIndex].getRight / 360),
                  child: Image(image: _images[imageIndex].getLeft)),
        ),
        onLongPress: () {
          longPressedImage = _images[imageIndex];
          showChangeImageSnackBar();
        },
      );

  void showImageSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Theme.of(context).highlightColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () => getImage(ImageSource.camera),
                  child: Icon(
                    Icons.camera_alt,
                    size: 80,
                  )),
              SizedBox(width: 2),
              GestureDetector(
                  onTap: () => getImage(ImageSource.gallery),
                  child: Icon(Icons.insert_drive_file, size: 80)),
            ],
          )),
    );
  }

  void showChangeImageSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Theme.of(context).highlightColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                flex: 4,
                child: GestureDetector(
                    onTap: () => rotateImage(),
                    child: Icon(Icons.rotate_right, size: 80)),
              ),
              Spacer(flex: 1),
              Flexible(
                flex: 4,
                child: GestureDetector(
                    onTap: () => deleteImage(),
                    child: Icon(Icons.delete, size: 80)),
              ),
            ],
          )),
    );
  }

  void rotateImage() async {
    if (longPressedImage != null) {
      int rotation = longPressedImage!.getRight;
      longPressedImage!.setRight(rotation + 90);
      if (longPressedImage!.getRight == 360) longPressedImage!.setRight(0);
      setState(() {
        longPressedImage = null;
      });
    }
  }

  Future<void> addSettingToDiscipline() async {
    widget.wizard.disciplineToGenerate!.addNewSetting(settingToGenerate);
  }

  void showNextWizardOrFinish(bool skip, bool finish) async {
    if (skip) {
      if (settingToGenerate.getLatestValue != null)
        await addSettingToDiscipline();
    }
    if (finish) {
      widget.wizard.predefinedValues = ListQueue<String>();
      if (settingToGenerate.getLatestValue != null)
        await addSettingToDiscipline();
    }
    if (widget.wizard.predefinedValues.length > 0) {
      Navigator.of(context).pop();
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (BuildContext context) {
        return WizardScreen(widget.wizard);
      }));
    } else {
      //FINISH
      Navigator.of(context).pop();
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (BuildContext context) {
        return DisciplineTabScreen(widget.wizard.disciplineToGenerate!);
      }));
    }
  }

  void handleState() async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    switch (state) {
      case WizardState.VALUE:
        if (textValuesController.text != "") {
          addValue(textValuesController.text);
          state = WizardState.NOTES;
        }
        break;
      case WizardState.NOTES:
        addNotes(textNotesController.text);
        state = WizardState.IMAGES;
        break;
      case WizardState.IMAGES:
        List<SettingImage> settingImages = [];
        for (Tuple<FileImage, int> image in _images) {
          int nextImageID = await databaseConverter.getNextImageID();
          settingImages.add(SettingImage(nextImageID, image.getLeft,
              settingToGenerate.values.last.id, image.getRight));
        }
        settingToGenerate.values.last.images.addAll(settingImages);
        await addSettingToDiscipline();
        showNextWizardOrFinish(false, false);
        break;
    }
  }

  Future<void> addValue(dynamic value) async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    int settingID = await databaseConverter.getNextSettingID();
    settingToGenerate.id = settingID; //Previously -1 to avoid unused numbers
    await settingToGenerate.addValue(value.toString());

    setState(() {
      switchFirst = false;
    });
  }

  void addNotes(String notes) async {
    setState(() {
      settingToGenerate.values.last.updateNotes(notes);
      switchSecond = false;
    });
  }

  Future getImage(ImageSource imageSource) async {
    try {
      var picker = ImagePicker();
      var image = await picker.pickImage(source: imageSource);
      if (image == null) {
        print("No picture selected");
        return;
      }
      if (imageSource == ImageSource.camera) {
        await GallerySaver.saveImage(image.path,
            albumName: "ShootingSettingsApp");
      }
      File file = File(image.path);

      setState(() {
        _images.add(Tuple(FileImage(file), 0));
      });
    } catch (exception) {
      print("No picture selected");
    }
  }

  void deleteImage() {
    if (longPressedImage != null) {
      setState(() {
        _images.remove(longPressedImage);
        longPressedImage = null;
      });
    }
  }

  void back() {
    if (widget.wizard.isAtStartingPoint()) {
      leaveWizardWithoutSaving();
    } else {
      widget.wizard.back();
      Navigator.of(context).pop();
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (BuildContext context) {
        return WizardScreen(widget.wizard);
      }));
    }
  }

  void leaveWizardWithoutSaving() {
    widget.wizard.disciplineToGenerate!.settings.removeRange(
        0, widget.wizard.disciplineToGenerate!.settings.length); //REMOVE ALL
    Navigator.of(context).pop();
  }
}

enum WizardState { VALUE, NOTES, IMAGES }
