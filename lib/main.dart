import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sensors/sensors.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'file_io.dart';
import 'file_io.dart';
import 'file_io.dart';
import 'file_io.dart';
import 'sensor.dart';
import 'sensor.dart';
import 'web.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

final accel_delay = Duration(seconds: 3);
final gps_delay = Duration(seconds: 3);
final bat_delay = Duration(seconds: 3);
final thread2_delay = Duration(seconds: 10);
final thread3_delay = Duration(seconds: 25);
final thread4_delay = Duration(seconds: 30);
String vehicleID;
final String upload = "upload";
final String stagging = "stagging";
final String compile = "compile";
final String savedID = "savedID";
final double distance_threshold = 10.0;
final String databaseurl = "https://kk9t74j5th.execute-api.ap-southeast-1.amazonaws.com/dev";
final String pingurl = "8.8.4.4";

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(String taskId) async {
  print('[BackgroundFetch] Headless event received.');
  BackgroundFetch.finish(taskId);
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[300],
          title: Text('EWB APPtech'),
        ),
        body: Column(
          children: [MainStructure()],
        ),
      ),
    );
  }
}

class MainStructure extends StatefulWidget {
  @override
  _MainStructureState createState() => _MainStructureState();
}



class _MainStructureState extends State<MainStructure> {
  //State Variables
  double x, y, z = 0;
  List<double> accelValues;
  Location location = new Location();
  var latlong;
  String filename;
  bool connected_server = false;
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];
  int batLevel;
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }


  //Main Threads
  Future<void> accelData() async {
    setState(() {
      accelValues = [x, y, z];
    });
    write_file(accelValues, 'accel', filename, compile, vehicleID);
  }

  Future<void> gpsData() async {
    getGPS(location).then((value) {
      setState(() {
        latlong = value;
      });
      write_file(latlong, 'gps', filename, compile, vehicleID);
    });
  }

  Future<void> batteryLevel() async {
    getBattery().then((value) {
      setState(() {
        batLevel = value;
      });
      write_file([value], 'battery', filename, compile, vehicleID);
    });
  }

  Future<void> thread2() async {
    if (!await check_folder_empty(compile)) {
      setState(() {
        filename = generate_filename();
      });

      final Directory directory = await getExternalStorageDirectory();
      Directory compileDir = Directory('${directory.path}/$compile');
      //var dir = Directory('${directory.path}/$upload');
      //  bool dirExists = await dir.exists();
      //  if(!dirExists){
      //     dir.create(/*recursive=true*/); //pass recursive as true if directory is recursive
      //  }
      print(compileDir);
      compileDir.list(recursive: true, followLinks: false).listen((e) async {
        String name = e.path.split('/').last.split('.')[0];
        if (name != filename) {
          await move_file(name, compile, stagging);
          print('moved file to stagging: ${name}');
        }
      });
    }
  }

  Future<void> thread3() async {
    final Directory directory = await getExternalStorageDirectory();
    Directory staggingDir = Directory('${directory.path}/$stagging');

    staggingDir.list(recursive: true, followLinks: false).listen((e) async {
      String name = e.path.split('/').last.split('.')[0];
      //if (await movement_detection(name, stagging, distance_threshold)) {
        await move_file(name, stagging, upload);
        print('moved file from stagging to upload: ${name}');
      //} else {
      //  delete_file(name, stagging);
      //  print("delete_stagging");
      //}


    });
  }

  Future<void> thread4() async {
    if (!await check_folder_empty(upload)) {
      print('checked!');
      if (await is_connected()) {
        if (await ping_server(pingurl)) {
          print("uploading to server");
          final Directory directory = await getExternalStorageDirectory();
          Directory uploadDir = Directory('${directory.path}/$upload');

          uploadDir.list(recursive: true, followLinks: false).listen((e) async {
            String name = e.path.split('/').last.split('.')[0];
            print("uploading");
            await upload_delete(databaseurl, name, upload);
          });
        }
      }
    }
  }

  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: false,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async {
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      setState(() {
        _events.insert(0, new DateTime.now());
      });
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
      setState(() {
        _status = e;
      });
    });

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  Future<void> sort_ID(string) async {
    try {
      if (await check_ID(string)) {
        setState(() async {
          vehicleID = await read_ID(string);
        });
      } else {
        String id = uuid.v1();
        setState(() async {
          vehicleID = id;
        });
        save_ID(savedID, id);
      }
    } catch (err) {
      print("Sort problem");
    }
  }

  Future<void> changeID(string, id) async {
    setState(() {
      vehicleID = id;
    });
    if (await check_ID(string)) {
      delete_ID(string);
      save_ID(string, id);
    } else {
      save_ID(string, id);
    }
  }

  //Initialization
  @override
  void initState() {
    super.initState();
    initPlatformState();
    filename = generate_filename();

    sort_ID(savedID);

    accelerometerEvents.listen((event) {
      setState(() {
        x = event.x;
        y = event.y;
        z = event.z;
      });
    });

    Timer.periodic(accel_delay, (Timer accelTimer) {
      accelData();
    });

    Timer.periodic(gps_delay, (Timer gpsTimer) {
      gpsData();
    });

    Timer.periodic(bat_delay, (Timer batTimer) {
      batteryLevel();
    });

    Timer.periodic(thread2_delay, (Timer thread2Timer) {
      thread2();
    });

    Timer.periodic(thread3_delay, (Timer thread3Timer) {
      thread3();
    });

    Timer.periodic(thread4_delay, (Timer thread3Timer) {
      thread4();
    });

    Timer.periodic(Duration(milliseconds: 3000), (timer) async {
      bool conn_server = await ping_server(pingurl);
      setState(() {
        connected_server = conn_server != null ? conn_server : false;
      });
    });
  }

  //Display
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(connected_server
                ? '🟢 Connected to Server 😌'
                : '🟠 Not Connected to Server 😴'),
            Text(''),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Accel Data",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("X-Axis"),
                      Text(accelValues != null
                          ? accelValues[0].toStringAsFixed(3)
                          : 'nothing...'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Y-Axis"),
                      Text(accelValues != null
                          ? accelValues[1].toStringAsFixed(3)
                          : 'nothing...'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Z-Axis"),
                      Text(accelValues != null
                          ? accelValues[2].toStringAsFixed(3)
                          : 'nothing...'),
                    ],
                  ),
                ),
                Text(''),
                Text(
                  "GPS Data",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                ),
                Text(latlong != null
                    ? "latitude: " + latlong[0].toString()
                    : 'nothing...'),
                Text(latlong != null
                    ? "longitude: " + latlong[1].toString()
                    : 'nothing...'),
                Text(''),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Text(
                    "Vehicle ID",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                ),
                Text(vehicleID),
                Text(''),
                TextField(
                  controller: myController,
                ),
                Text(''),
                FloatingActionButton.extended(
                  onPressed: () {
                    changeID(savedID, myController.text.toString());
                    myController.clear();
                  },
                  label: Text('Change ID'),
                  backgroundColor: Colors.green,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
