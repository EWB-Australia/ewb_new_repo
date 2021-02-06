import 'package:moto_monitor/models/moto.dart';
import 'package:moto_monitor/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../utils/file_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:f_logs/f_logs.dart';
import 'dashboard/home.dart';
import 'dashboard/map.dart';
import 'dashboard/debug.dart';
import 'dashboard/SettingsPage.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:foreground_service/foreground_service.dart';
import 'package:filesize/filesize.dart';
import '../utils/service_locator.dart' as SL;

SharedPreferences prefs;

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  PageController _pageController;
  String _appMessage = "";

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    FLog.info(text: "Dispose of listeners");
    SL.getIt<Moto>().removeListener(update);
    SL.getIt<Settings>().removeListener(update);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {

    // Check the internet status
    final bool connected = await ConnectivityUtils.instance.isPhoneConnected();
    FLog.info(text: "Check internet connection");
    // Set the initial state of internet connection
    if (connected == true) {
      FLog.info(text: "Internet connected");
      SL.getIt<Settings>().setOnline();
    }
    else{
      FLog.info(text: "Internet not connected");
      SL.getIt<Settings>().setOffline();
    }

    await createFolderInCache("stagging");
    await createFolderInCache("upload");
    await createFolderInCache("uploaded");

    // Set up gps
    SL.getIt<Moto>().gpsSubscribe();

    // Configure sensors
    // Check if magnet sensor and linear acceleration are available, if not use only phone raw acceleration
    if (await motionSensors.isMagnetometerAvailable() && await motionSensors.isUserAccelerationAvailable() && await motionSensors.isAccelerometerAvailable()) {
      SL.getIt<Moto>().sensorSubscribe();
      // Save result in settings
      SL.getIt<Settings>().sensorAccelOnly = false;
      FLog.info(text: "Setting up with all sensors");
    }
    else if (await motionSensors.isMagnetometerAvailable() == false) {
      SL.getIt<Moto>().sensorSubscribeAccelOnly();
      // Save result in settings
      SL.getIt<Settings>().sensorAccelOnly = true;
      FLog.info(text: "Setting up with only accelerometer");
    }
    else {
      // No sensor found, raise error
      FLog.error(text: "No sensors found");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  //Initialization
  @override
  void initState() {
    super.initState();
    SL.maybeStartFGS();
    initPlatformState();

    _pageController = PageController();

    SL.getIt<Moto>().addListener(update);
    SL.getIt<Settings>().addListener(update);
    // Setup directories
    SL.getIt<Settings>().setDirectories();

    // Setup periodic call to process/upload data
    Timer.periodic(Duration(minutes: 5), (Timer t) {
      SL.getIt<Moto>().processDataQueues();
    });
  }

  void update() => setState(() => {});

  void _connectivityOnline(){
    SL.getIt<Settings>().setOnline();
  }
  void _connectivityOffline(){
    SL.getIt<Settings>().setOffline();
  }

//Display
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      color: Colors.yellow,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SizedBox.expand(
          child: PageView(
            physics: NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: <Widget>[
              Home(),
              Map(),
              SettingsPage(),
              Debug(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavyBar(
        selectedIndex: _currentIndex,
        showElevation: true,
        itemCornerRadius: 24,
        curve: Curves.easeIn,
        onItemSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
        items: <BottomNavyBarItem>[
          BottomNavyBarItem(
            icon: Icon(Icons.dashboard),
            title: Text('Home'),
            activeColor: Colors.blue,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: Icon(Icons.map),
            title: Text('Map'),
            activeColor: Colors.blue,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: Icon(Icons.settings),
            title: Text(
              'Settings ',
            ),
            activeColor: Colors.blue,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: Icon(Icons.build_rounded),
            title: Text('Debug'),
            activeColor: Colors.blue,
            textAlign: TextAlign.center,
          ),
        ],
      ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}