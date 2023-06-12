import 'dart:async';
import 'dart:io';


import 'package:intl/intl.dart';
import 'package:settings_app/model/Discipline.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/FormatUtil.dart';

class PDFCreator {

  static Future<File> createPDF(Discipline discipline) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
                children: <pw.Widget>[
                  pw.Text(discipline.belongingDevice.name + "\n" + discipline.formatDisciplineName(),
                      style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, font: pw.Font.courier())),
                  pw.SizedBox(height: 5.0),

                  pw.Text(discipline.configurationName,
                      style: pw.TextStyle(fontSize: 24, fontStyle: pw.FontStyle.italic, font: pw.Font.courier())),
                  pw.SizedBox(height: 5.0),

                  pw.Text(DateFormat(allTranslations.text("date_format")).format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 24, fontStyle: pw.FontStyle.italic, font: pw.Font.courier())),
                  pw.SizedBox(height: 15.0),


                  pw.Table(
                      children: _buildTableRows(discipline),
                      border: pw.TableBorder(),
                  ),
                  pw.SizedBox(height: 15.0),
                  getFooter(),
                ]
            ),
          ); // Center
        })); // Page


    final output = await getApplicationDocumentsDirectory();
    final String title = "/" + discipline.formatDisciplineName() + discipline.configurationName + ".pdf";
    final String path = output.path + title;
    final file = File(path);
    print(path);
    await file.writeAsBytes((await pdf.save()).toList());
    return file;
  }

  static List<pw.TableRow> _buildTableRows(Discipline discipline) {
    List<pw.TableRow> rows = [];

    pw.TableRow header = pw.TableRow(
      children: <pw.Widget>[
        pw.Center(child: pw.Text(allTranslations.text("setting"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text(allTranslations.text("notes"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text(allTranslations.text("value"), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
      ]
    );
    rows.add(header);

    List<Setting> settings = [];
    settings.addAll(discipline.settings);
    settings.sort((setting1, setting2) =>
      setting1.orderedPosition <= setting2.orderedPosition ? -1 : 1);

    for(Setting setting in settings) {
      if(setting.values.length != 0) {
        pw.TableRow row = pw.TableRow(
            children: <pw.Widget>[
              pw.Center(child: pw.Text(setting.name)),
              pw.Center(child: pw.Text(setting.values.last.notes)),
              pw.Center(child: pw.Text(FormatUtil.formatValue(setting.getLatestValue,
                  setting.getCurrentLengthMeasure())),),
            ]
        );
        rows.add(row);
      }
    }

    return rows;
  }

  static pw.Widget getFooter() {
    return pw.Align(
      alignment: pw.Alignment.bottomCenter,
      child: pw.Text(allTranslations.text("powered_by") + ": " + allTranslations.text("app_title"))
    );
  }
}