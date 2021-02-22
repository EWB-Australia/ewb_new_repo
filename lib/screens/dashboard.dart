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
import 'package:foreground_service/foreground_service.dart';
import '../utils/service_locator.dart' as SL;
import 'package:motion_sensors/motion_sensors.dart';

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

    // Setup directories
    await SL.getIt<Settings>().setDirectories();
    await createFolder('${SL.getIt<Settings>().cacheDir.path }/upload/');
    await createFolder('${SL.getIt<Settings>().cacheDir.path }/uploaded/');

    // Set up gps
    SL.getIt<Moto>().gpsSubscribe();

    // Check if phone has magnometer
    if (await motionSensors.isAccelerometerAvailable() && await motionSensors.isUserAccelerationAvailable() && await motionSensors.isMagnetometerAvailable() ) {
      SL.getIt<Settings>().sensorAccelOnly = false;
    } else {
      SL.getIt<Settings>().sensorAccelOnly = true;
    }


    // Setup sensors
    if (SL.getIt<Settings>().sensorAccelOnly == true){
      SL.getIt<Moto>().sensorSubscribeAccelOnly();
    } else {
      SL.getIt<Moto>().sensorSubscribe();
    }

    if (await ForegroundService
        .isBackgroundIsolateSetupComplete()) {
      await ForegroundService.sendToPort("OK");
      FLog.info(text: "Foreground service comms setup");
    } else {
      FLog.error(text: "Problem setting up foreground service comms");
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
    SL.getIt<Settings>().isForegroundService = true;

    _pageController = PageController();

    SL.getIt<Moto>().addListener(update);
    SL.getIt<Settings>().addListener(update);

    initPlatformState();

    // Setup periodic call to process/upload data
    SL.getIt<Settings>().dataProcessTimer = Timer.periodic(Duration(seconds: SL.getIt<Settings>().dataProcessFrequency), (Timer t1) {
      SL.getIt<Moto>().processDataQueues();
    });

    // Setup periodic call to process/upload data
    SL.getIt<Settings>().pingServerTimer = Timer.periodic(Duration(minutes: 60), (Timer t2) {
      SL.getIt<Moto>().pingServer();
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