import 'package:flutter/material.dart';
import 'package:settings_app/translations.dart';

class DialogUtil {
  static void showSureToRemoveDialog(
      BuildContext context, Function onDelete) async {
    await showDialog<String>(
      context: context,
      builder: (buildContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Row(
            children: <Widget>[
              Expanded(child: Text(allTranslations.text("sure_to_delete")))
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
                  Navigator.of(context, rootNavigator: true).pop();
                  onDelete();
                })
          ],
        );
      },
    );
  }
}
