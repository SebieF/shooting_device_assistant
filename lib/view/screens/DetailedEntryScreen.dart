import 'dart:async';
import 'dart:io';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/SettingEntry.dart';
import 'package:settings_app/model/SettingImage.dart';
import 'package:settings_app/util/DialogUtil.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';
import 'package:share_extend/share_extend.dart';

import '../../translations.dart';

class DetailedEntryScreen extends StatefulWidget {
  final SettingEntry settingEntry;

  DetailedEntryScreen(this.settingEntry) : super();

  @override
  _DetailedEntryState createState() => _DetailedEntryState();
}

class _DetailedEntryState extends State<DetailedEntryScreen> {
  final textNotesController = TextEditingController();
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final List<TabItem> tabs = [
    TabItem(icon: Icons.arrow_back, title: allTranslations.text("back")),
    TabItem(icon: Icons.delete, title: allTranslations.text("remove_value")),
    TabItem(icon: Icons.add_a_photo, title: allTranslations.text("pick_image"))
  ];

  SettingImage? _longPressedImage;
  bool wasDeleted = false;

  _DetailedEntryState();

  @override
  void initState() {
    super.initState();
    textNotesController.text = widget.settingEntry.notes;
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
          if (i == 0) Navigator.of(context).pop(),
          //BACK
          if (i == 1)
            DialogUtil.showSureToRemoveDialog(context, deleteThisSetting),
          // DELETE AND GO BACK
          if (i == 2) showImageSnackBar()
          // ADD PHOTO
        },
      ),
      body: GradientBackgroundContainer(
        child: Center(
          child: Column(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(
                      top: SizeConfig.safeBlockVertical(context) * 3)),
              // *** HEADING ***:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: Center(
                    child: Text(
                      createTitle(),
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              Divider(thickness: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    allTranslations.text('date') + ": ",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    DateFormat(allTranslations.text("date_format")).format(
                        widget.settingEntry.dateAndValue.getLeft), //– hh:mm
                    style: Theme.of(context).textTheme.titleLarge,
                  )
                ],
              ),
              Divider(thickness: 2),
              // *** NOTES ***:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    allTranslations.text("notes") + ":",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),
              Flexible(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: allTranslations.text("notes_hint")),
                  controller: textNotesController,
                  minLines: 2,
                  //onChanged: (_) =>  _settingEntry.updateNotes(textNotesController.text), Not good because of database writing
                  onEditingComplete: () => setState(() => widget.settingEntry
                      .updateNotes(textNotesController.text)),
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                ),
              ),

              Divider(thickness: 5, color: Color.fromRGBO(0, 0, 0, 1)),
              // *** IMAGES ***
              Expanded(
                flex: 2,
                child: _buildImageList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageList() {
    return ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          /*if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2; */
          final int index = i;
          if (index < widget.settingEntry.images.length) {
            print(widget.settingEntry.images[index].fileImage.file.path);
            return _buildDecoratedImage(index);
          }
          return null;
        });
  }

  Widget _buildDecoratedImage(int imageIndex) => GestureDetector(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: SizeConfig.safeBlockHorizontal(context) * 60.0),
          child: RotationTransition(
            turns: AlwaysStoppedAnimation(
                widget.settingEntry.images[imageIndex].rotation / 360),
            child: PhotoView(
              imageProvider: widget.settingEntry.images[imageIndex].fileImage,
              backgroundDecoration: BoxDecoration(color: Colors.transparent),
            ),
          ),
        ),
        onLongPress: () => {
          _longPressedImage = widget.settingEntry.images[imageIndex],
          showImageChangeSnackBar(),
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

  void showImageChangeSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Theme.of(context).highlightColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () => rotateImage(),
                  child: Icon(Icons.rotate_right, size: 80)),
              GestureDetector(
                  onTap: () => shareImage(),
                  child: Icon(Icons.share, size: 80)),
              GestureDetector(
                  onTap: () => deleteImage(),
                  child: Icon(Icons.delete, size: 80)),
            ],
          )),
    );
  }

  Future<void> getImage(ImageSource imageSource) async {
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

      SettingImage settingImage =
          SettingImage(nextImageID, FileImage(file), widget.settingEntry.id, 0);
      setState(() {
        widget.settingEntry.images.add(settingImage);
      });
    } catch (exception) {
      print("No picture selected");
    }
  }

  void shareImage() async {
    if (_longPressedImage != null) {
      String imagePath = _longPressedImage!.fileImage.file.path;

      String fileName = imagePath.split('/').last;
      String fileExtension = fileName.split('.').last;

      await ShareExtend.share(imagePath, fileExtension);

      _longPressedImage = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void deleteImage() {
    if (_longPressedImage != null) {
      setState(() {
        widget.settingEntry.images.remove(_longPressedImage);
        _longPressedImage = null;
      });
    }
  }

  void rotateImage() async {
    if (_longPressedImage != null) {
      _longPressedImage!.rotation += 90;
      if (_longPressedImage!.rotation == 360) _longPressedImage!.rotation = 0;
      DatabaseConverter databaseConverter = DatabaseConverter();
      await databaseConverter.updateImage(_longPressedImage!);
      setState(() {
        _longPressedImage = null;
      });
    }
  }

  void deleteThisSetting() {
    widget.settingEntry.belongingSetting!.values.remove(widget.settingEntry);
    if (widget.settingEntry.belongingSetting!
        .checkIfAllValuesCanBeConvertedToDouble())
      widget.settingEntry.belongingSetting!.changeAllValuesToDouble();

    wasDeleted = true;
    Navigator.of(context).pop();
  }

  String createTitle() {
    return widget.settingEntry.belongingSetting!.belongingDiscipline!
            .formatDisciplineName() +
        " - " +
        widget.settingEntry.belongingSetting!.name +
        " - " +
        widget.settingEntry.dateAndValue.getRight.toString() +
        (widget.settingEntry.belongingSetting!.getLatestValue ==
                widget.settingEntry.dateAndValue.getRight
            ? ""
            : " (Alter Wert)");
  }

  @override
  void dispose() {
    if (!wasDeleted) widget.settingEntry.updateNotes(textNotesController.text);
    textNotesController.dispose();
    super.dispose();
  }
}
