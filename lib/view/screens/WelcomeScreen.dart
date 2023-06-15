import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:observable/observable.dart';
import 'package:path_provider/path_provider.dart';

import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/AppState.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/DialogUtil.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';
import 'package:settings_app/view/screens/DisciplinesScreen.dart';
import 'package:settings_app/view/screens/UserSettingsInfoScreen.dart';
import 'package:settings_app/view/screens/DeviceCreationScreen.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../util/FormatUtil.dart';

class WelcomeScreen extends StatefulWidget {
  WelcomeScreen() : super();

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final List<TabItem> tabs = [
    TabItem(icon: Icons.settings, title: allTranslations.text("settings")),
    TabItem(icon: Icons.add_circle, title: allTranslations.text("add_device"))
  ];

  ObservableList<Device> _devices = ObservableList();
  bool blinkButtonPressed = false;
  bool dataLoaded = false;
  Device? _longPressedDevice;

  late ShakeDetector shakeDetector;

  _WelcomeScreenState();

  @override
  void initState() {
    super.initState();
    loadData();
    setShakeDetector();
  }

  Future<String> writeTempImageToStorage(Uint8List feedbackScreenshot) async {
    final Directory output = await getTemporaryDirectory();
    final String screenshotFilePath = '${output.path}/feedback.png';
    final File screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(feedbackScreenshot);
    return screenshotFilePath;
  }

  Future<void> sendFeedbackAsMail(UserFeedback feedback) async {
    String tempScreenshotPath =
        await writeTempImageToStorage(feedback.screenshot);

    final Email email = Email(
      body: feedback.text,
      subject: 'Feedback Shooting Device Assistant',
      recipients: ['sebastian11@online.de'],
      attachmentPaths: [tempScreenshotPath],
      isHTML: false,
    );

    FlutterEmailSender.send(email);
  }

  Future<void> setShakeDetector() async {
    shakeDetector = ShakeDetector.waitForStart(
      onPhoneShake: () {
        BetterFeedback.of(context).show((UserFeedback userFeedback) {
          sendFeedbackAsMail(userFeedback);
        });
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? enableFeedbackPref =
        sharedPreferences.get("enable_feedback") as String?;
    if (enableFeedbackPref != null) {
      if (FormatUtil.str2bool(enableFeedbackPref)) {
        shakeDetector.startListening();
      }
    } else {
      sharedPreferences.setString("enable_feedback", "true");
    }
  }

  Future<void> loadData() async {
    List<Device> devices =
        await DatabaseConverter().readAllValuesFromDatabase();
    await initDevices(devices);
    setState(() {
      AppState.appState = AppStates.RUNNING;
      dataLoaded = true;
    });
  }

  Future<void> initDevices(List<Device> devices) async {
    _devices = ObservableList()..addAll(devices);
    DatabaseConverter databaseConverter = DatabaseConverter();

    _devices.listChanges.listen((changes) {
      changes.forEach((change) => print("Device " + change.toString()));
      changes.forEach((change) => change.added.forEach((device) => {
            if (AppState.appState != AppStates.LOADING)
              databaseConverter.insertDevice(device)
          }));
      changes.forEach((change) => change.removed.forEach((device) => {
            if (AppState.appState != AppStates.LOADING)
              databaseConverter.deleteDevice(device.id)
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    setShakeDetector();
    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        title: SizedBox.square(
            dimension: SizeConfig.screenWidth(context),
            child: Center(
                child: AutoSizeText(allTranslations.text("app_title"),
                    maxLines: 1))),
      ),
      bottomNavigationBar: Visibility(
        visible: dataLoaded,
        child: ConvexAppBar(
          items: tabs,
          activeColor: Theme.of(context).primaryColor,
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).bottomAppBarTheme.color,
          initialActiveIndex: 1,
          onTap: (int i) => {
            if (i == 0) showSettingsScreen(),
            if (i == 1) addDevice(),
          },
        ),
      ),
      body: GradientBackgroundContainer(
        child: _buildDeviceList(),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (!dataLoaded)
      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircularProgressIndicator(value: null),
          ],
        ),
      );
    else {
      return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext _context, int i) {
            if (i.isOdd) {
              return Divider();
            }
            final int index = i ~/ 2;
            if (index < _devices.length) {
              return _buildDecoratedDevice(index);
            }
            return null;
          });
    }
  }

  Widget _buildDecoratedDevice(int deviceIndex) {
    Device device;
    if (deviceIndex < _devices.length) {
      device = _devices[deviceIndex];
      return Container(
        child: Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: LimitedBox(
                maxWidth: SizeConfig.safeBlockHorizontal(context) * 10.0,
                child: device.image),
            title: Text(
              device.name,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            subtitle: Text(
              device.formatDeviceCategory() + "\n" + device.formatStockKind(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            isThreeLine: true,
            onTap: () => showDisciplinesScreen(_devices[deviceIndex]),
            onLongPress: () => {
              _longPressedDevice = device,
              showDeleteSnackBar(),
            },
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  void showDisciplinesScreen(Device device) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return DisciplineScreen(device);
    })).then((_) => setState(() {}));
  }

  void showSettingsScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return UserSettingsInfoScreen(shakeDetector);
    })).then((_) => setState(() {
              //_buildTabs();
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
                  onTap: () =>
                      DialogUtil.showSureToRemoveDialog(context, deleteDevice),
                  child: Icon(Icons.delete, size: 80)),
            ],
          )),
    );
  }

  void addDevice() {
    setState(() {
      blinkButtonPressed = true;
    });
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return DeviceCreationScreen(
        _devices,
        onCloseDialog,
      );
    })).then((_) => setState(() {}));
  }

  void deleteDevice() {
    if (_longPressedDevice != null) {
      setState(() {
        _devices.remove(_longPressedDevice);
        _longPressedDevice = null;
        if (_devices.length == 0) {
          blinkButtonPressed = false;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    }
  }

  void onCloseDialog() {
    setState(() {
      // SHOW UPDATED LIST
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
