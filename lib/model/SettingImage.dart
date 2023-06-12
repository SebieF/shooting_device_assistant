import 'package:flutter/cupertino.dart';

import 'ID.dart';

class SettingImage implements ID{
  int id; //PRIMARY KEY
  FileImage fileImage;
  int settingEntryID; //FOREIGN KEY
  int rotation;

  SettingImage(this.id, this.fileImage, this.settingEntryID, this.rotation);

  @override
  String toString() {
    return 'SettingImage{id: $id, fileImage: $fileImage, settingEntryID: $settingEntryID}';
  }

  @override
  int getID() {
    return id;
  }
}