import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:settings_app/model/Setting.dart';
import 'package:settings_app/model/SettingEntry.dart';

import '../../translations.dart';

class SettingsLineChart extends StatelessWidget {
  final List<charts.Series<SettingEntry, DateTime>> seriesList;
  final bool animate;

  SettingsLineChart(this.seriesList, this.animate);

  factory SettingsLineChart.fromSetting(Setting setting) {
    return SettingsLineChart(
      _createData(setting),
      // Disable animations for image tests.
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(seriesList,
        animate: animate,
        domainAxis: new charts.DateTimeAxisSpec(
            showAxisLine: false,
            renderSpec: new charts.SmallTickRendererSpec(

              // Tick and Label styling here.
                labelStyle: new charts.TextStyleSpec(
                    fontSize: 18, // size in Pts.
                    color: charts.MaterialPalette.black)),

                // Change the line colors to match text color.
            tickFormatterSpec: new charts.AutoDateTimeTickFormatterSpec(
                day: new charts.TimeFormatterSpec(
                    format: 'd', transitionFormat: allTranslations.text("date_format")))),

        /// Assign a custom style for the measure axis.
        primaryMeasureAxis: new charts.NumericAxisSpec(
            tickFormatterSpec: new charts.BasicNumericTickFormatterSpec.
            fromNumberFormat(new NumberFormat.decimalPattern()),

            renderSpec: new charts.GridlineRendererSpec(

                // Tick and Label styling here.
                labelStyle: new charts.TextStyleSpec(
                    fontSize: 18, // size in Pts.
                    color: charts.MaterialPalette.black),

                // Change the line colors to match text color.
                lineStyle: new charts.LineStyleSpec(
                    color: charts.MaterialPalette.black))),
        defaultRenderer: new charts.LineRendererConfig(includePoints: true));
  }

  static List<charts.Series<SettingEntry, DateTime>> _createData(
      Setting setting) {
    final data = setting.values;

    return [
      new charts.Series<SettingEntry, DateTime>(
        id: setting.name,
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (SettingEntry settingEntry, _) =>
            settingEntry.dateAndValue.getLeft,
        measureFn: (SettingEntry settingEntry, _) =>
            settingEntry.dateAndValue.getRight,
        data: data,
      )
    ];
  }
}
