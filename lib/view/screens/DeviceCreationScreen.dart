import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:settings_app/database/DatabaseConverter.dart';
import 'package:settings_app/model/Device.dart';
import 'package:settings_app/translations.dart';
import 'package:settings_app/util/SizeConfig.dart';
import 'package:settings_app/view/custom_widgets/GradientBackgroundContainer.dart';

class DeviceCreationScreen extends StatefulWidget {
  final List<Device> deviceListToAddCreationTo;
  final Function() onClose;

  DeviceCreationScreen(this.deviceListToAddCreationTo, this.onClose) : super();

  @override
  _DeviceCreationState createState() => _DeviceCreationState();
}

class _DeviceCreationState extends State<DeviceCreationScreen> {
  final TextEditingController deviceCategoryController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();
  final TextEditingController stockNameController = TextEditingController();
  final FocusNode categoryFocus = FocusNode();
  final FocusNode categoryNameFocus = FocusNode();
  final FocusNode deviceFocus = FocusNode();
  final GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final List<TabItem> tabs = [TabItem(icon: Icons.arrow_back, title: allTranslations.text("back"))];

  CreationState state = CreationState.SELECT_CATEGORY;

  Device? selectedCategory;
  String? customCategoryName;
  String? deviceName;
  String? stockName;

  _DeviceCreationState();

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
        // BACK
        onTap: (int i) => {
          if (i == 0) Navigator.of(context).pop(), //BACK
        },
      ),
      body: GradientBackgroundContainer(child: _handleState()),
    );
  }

  String calculateTitle() {
    final String standardAffix = allTranslations.text("device");
    final String suffix = " " + allTranslations.text("add");
    if (selectedCategory != null) {
      if (selectedCategory!.deviceCategory == DeviceCategories.OTHER) {
        if (deviceCategoryController.text != "") {
          if (allTranslations.currentLanguage == "de")
            return deviceCategoryController.text + suffix;
          else
            return suffix + " " + deviceCategoryController.text;
        }
      } else {
        if (allTranslations.currentLanguage == "de")
          return selectedCategory!.name + suffix;
        else
          return suffix + " " + selectedCategory!.name;
      }
    }
    if (allTranslations.currentLanguage == "de")
      return standardAffix + suffix;
    else
      return suffix + " " + standardAffix;
  }

  Widget _handleState() {
    switch (state) {
      case CreationState.SELECT_CATEGORY:
        return buildDeviceCategoryList();
      case CreationState.DEFINE_CATEGORY:
        return buildNaming();
      case CreationState.CREATE_OWN_CATEGORY:
        return buildDeviceCategoryNaming();
    }
  }

  Widget buildNaming() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        buildDeviceNaming(),
        buildStockNaming(),
        buildButtons(),
      ],
    );
  }

  Widget buildDeviceCategoryList() {
    List<Device> categories = Device.getAllDeviceForDeviceCategories();
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index < categories.length) {
            return _buildCategory(categories[index]);
          }
          return null;
        });
  }

  Widget _buildCategory(Device category) {
    return ListTile(
        title: Text(
          category.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => {
              setState(() {
                selectedCategory = category;
                if (selectedCategory!.deviceCategory == DeviceCategories.OTHER)
                  state = CreationState.CREATE_OWN_CATEGORY;
                else
                  state = CreationState.DEFINE_CATEGORY;
              })
            });
  }

  Widget buildDeviceCategoryNaming() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: TextField(
            focusNode: categoryNameFocus,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
                hintText: allTranslations.text("enter_category_name_hint"),
                hintStyle: Theme.of(context).textTheme.displaySmall),
            controller: deviceCategoryController,
            style: Theme.of(context).textTheme.displaySmall,
            keyboardType: TextInputType.text,
            onSubmitted: (_) => {
              setState(() {
                state = CreationState.DEFINE_CATEGORY;
              })
            },
          ),
        ),
        IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => {
                  setState(() {
                    state = CreationState.SELECT_CATEGORY;
                    customCategoryName = null;
                    selectedCategory = null;
                  })
                }),
      ],
    );
  }

  Widget buildDeviceNaming() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Center(
            child: TextField(
              focusNode: deviceFocus,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  hintText: allTranslations.text("enter_device_name_hint"),
                  hintStyle: Theme.of(context).textTheme.displaySmall),
              onSubmitted: (_) => setState(() {}),
              controller: deviceNameController,
              style: Theme.of(context).textTheme.displaySmall,
              keyboardType: TextInputType.text,
              autofocus: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStockNaming() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Center(
            child: TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  hintText: allTranslations.text("define_stock_hint"),
                  hintStyle: Theme.of(context).textTheme.displaySmall),
              controller: stockNameController,
              style: Theme.of(context).textTheme.displaySmall,
              keyboardType: TextInputType.text,
              onSubmitted: (_) => addCreationToList(),
              autofocus: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildButtons() {
    return Center(
        child: Visibility(
      visible: selectedCategory != null && deviceNameController.text != "",
      child: GestureDetector(
        child: Icon(
          Icons.check_circle,
          size: SizeConfig.blockSizeVertical(context) * 12,
          semanticLabel: allTranslations.text("confirm"),
          color: Colors.green,
        ),
        onTap: addCreationToList,
      ),
    ));
  }

  void addCreationToList() async {
    DatabaseConverter databaseConverter = DatabaseConverter();
    deviceName = deviceNameController.text;
    customCategoryName = deviceCategoryController.text;
    stockName = stockNameController.text;
    bool customCategoryOkay = (selectedCategory!.deviceCategory == DeviceCategories.OTHER && customCategoryName != "") ||
        selectedCategory!.deviceCategory != DeviceCategories.OTHER;

    if (deviceName != null && selectedCategory != null && stockName != null && customCategoryOkay) {
      int deviceID = await databaseConverter.getNextDeviceID();
      Device creation = Device(deviceID, deviceName!, selectedCategory!.deviceCategory, stockName!, null);
      if (creation.isRifle()) creation.image = Image.asset("assets/devices/generic_rifle.png");
      if (creation.isPistol()) creation.image = Image.asset("assets/devices/generic_pistol.png");
      if (selectedCategory!.deviceCategory == DeviceCategories.OTHER) creation.customCategoryName = customCategoryName!;

      widget.deviceListToAddCreationTo.add(creation);
      Navigator.of(context).pop();
      widget.onClose();
    } else {
      if (deviceName == "")
        deviceFocus.requestFocus();
      else {
        if (selectedCategory == null || selectedCategory!.deviceCategory == DeviceCategories.OTHER) {
          if (state == CreationState.CREATE_OWN_CATEGORY)
            categoryNameFocus.requestFocus();
          else
            categoryFocus.requestFocus();
        }
      }
    }
  }
}

// SELECT_CATEGORY ==> DEFINE_CATEGORY || SELECT_CATEGORY ==> CREATE_OWN_CATEGORY ==> DEFINE_CATEGORY
enum CreationState { SELECT_CATEGORY, DEFINE_CATEGORY, CREATE_OWN_CATEGORY }
