import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sensors/sensors.dart';
import 'dart:async';
import 'dart:math';
import 'file_io.dart';
import 'sensor.dart';
import 'web.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:collection';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info/device_info.dart';
import 'package:ewb_app/models/point.dart';
import 'package:ewb_app/models/accel.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'utils/zip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_logs/flutter_logs.dart';

var uuid = Uuid();

final bat_delay = Duration(seconds: 3);
final thread2_delay = Duration(seconds: 10);
final thread4_delay = Duration(seconds: 60);
final exportLogsDelay = Duration(hours: 1);
final String upload = "upload";
final String stagging = "stagging";
final String compile = "compile";
final String savedID = "savedID";
final double distance_threshold = 10.0;
final String databaseurl = "https://kk9t74j5th.execute-api.ap-southeast-1.amazonaws.com/dev";
final auth_token = '1NxqnduNW8XXQcwOMV0jSafNAZtE6VnUwkmSGdjvmPxPIjhlSqxj3g1mjIddCWmbgpKUzfX2cz2CoBOPiJsGxu0BwoavHpayN1G67ltDV0dxqQsBWb21FaBNdlZd8grdSZrYRGw2QvRaXQSkjrIU68d04xUppVTNRCKAikmL9IbsKZWZcsHRhUeWMJyaZp2CmupR604H';
final String pingurl = "http://google.com";
SharedPreferences prefs;


/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(String taskId) async {
  print('[BackgroundFetch] Headless event received.');
  BackgroundFetch.finish(taskId);
}

void main() {
  runApp(MyApp());
}


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
  double latitude = 0;
  double longitude = 0;
  String filename;
  bool connected_server = false;
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];
  int batLevel;
  final myController = TextEditingController();
  Queue accelQueue = new Queue();
  Queue gpsQueue = new Queue();
  Directory tmpDir;
  int countEvents = 0;
  String vehicleID; // Vehicle ID which is editable on user screen
  String vehicleUID; // Unique vehicle ID based on build.androidID

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }


  Future<void> thread2() async {

    Directory compileDir = Directory('${tmpDir.path}/$compile');

    if (!await check_folder_empty(compileDir.path)) {

      print(compileDir);

      compileDir.list(recursive: false, followLinks: false).listen((e) async {

          await e.rename(e.path.replaceAll(compile, upload));
          print('moved file to upload: ${basename(e.path)}');

      });
    }
  }

  // Return a list of object from a Q for processing
  List<dynamic> popQueue(q) {

    // Temp list of objects
    List<dynamic> ld = new List<dynamic>();

    // Get length of Q
    var length_q = q.length;

    // Move items from the Q to temp list
    for( var i = length_q ; i >= 1; i-- ) {
      ld.add(q.first);
      q.removeFirst();
    }

    return ld;
  }

  Future<void> exportLogFiles() async {

    FlutterLogs.exportLogs(
        exportType: ExportType.ALL);

  }

  Future<void> thread4() async {
    if (accelQueue.length > 0 || gpsQueue.length > 0 ) {
      if (await is_connected()) {
        if (await ping_server(pingurl)) {

          Directory uploadDir = Directory('${tmpDir.path}/$upload');

          List<dynamic> gList = new List<dynamic>();
          List<dynamic> aList  = new List<dynamic>();

          Random random = new Random();
          int randomNumber = random.nextInt(9000)+1000;

          List<File> files = [
          ];

          if(accelQueue.length > 0) {
            // Get list of acceleoremter readings from Q
            aList = popQueue(accelQueue);
          };

          if(gpsQueue.length > 0) {
            // Get list of gps readings from Q
            gList = popQueue(gpsQueue);
          }

          final File payloadFile = await File('${tmpDir.path}/payload.json').create(recursive: true);

          // Pacakge all the data we need to send into a json file
          final payload = {
            'moto': vehicleUID,
            'trip': vehicleUID,
            'batteryLevel': await getBattery(),
            'gps_values': gList,
            'acceleration_values': aList
          };
          // Write the file.
          payloadFile.writeAsString(json.encode(payload));

          files.add(payloadFile);

          if(files.length > 0) {
            print("compressing");

            final zipFile =
                createZipFile('${tmpDir.path}/${randomNumber.toString()}.zip');

            try {
              await ZipFile.createFromFiles(
                  sourceDir: tmpDir, files: [payloadFile,], zipFile: zipFile);
            } catch (e) {
              print(e);
            }

            // Move file
            await zipFile
                .rename('${tmpDir.path}/upload/${randomNumber.toString()}.zip');

            print("uploading to server");
            // Don't follow links and dont scan sub-folders
            uploadDir
                .list(recursive: false, followLinks: false)
                .listen((e) async {
              FlutterLogs.logInfo("UPLOAD", "Start", "Uploading ${zipFile.path}");
              await upload_delete(databaseurl, e.path);
            });
          }
        }
      }
    }
  }

  Future<void> initPlatformState() async {

    //Initialize Logging
    await FlutterLogs.initLogs(
        logLevelsEnabled: [
          LogLevel.INFO,
          LogLevel.WARNING,
          LogLevel.ERROR,
          LogLevel.SEVERE
        ],
        timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE,
        directoryStructure: DirectoryStructure.FOR_DATE,
        logTypesEnabled: ["device","network","errors"],
        logFileExtension: LogFileExtension.LOG,
        logsWriteDirectoryName: "EWB_Logs",
        logsExportDirectoryName: "EWB_LOGS/Exported",
        debugFileOperations: true,
        isDebuggable: true);

    tmpDir = await getTemporaryDirectory();

    // obtain shared preferences
    prefs = await SharedPreferences.getInstance();

    // set value
    prefs.setString('savedID', savedID);

    // Get device info
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    // Set vehicle ID, this is used to identify vehicle in backend
    vehicleUID = androidInfo.androidId;
    vehicleID = prefs.getString('vehicleID') ?? vehicleUID;

    prefs.setString('vehicleUID', vehicleUID);

    // Create working directories
    await createFolderInCache(compile);
    await createFolderInCache(stagging);
    await createFolderInCache(upload);

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

  //Initialization
  @override
  void initState() {
    super.initState();

    initPlatformState();
    filename = generateFilename();

    FlutterLogs.logInfo("INIT", "initState", "Setting State variables");


    // Subscribe to accelerometer event stream
    // Throttle stream using "audit" so we only get one event every 25ms
    accelerometerEvents.audit(const Duration(milliseconds: 25)).listen((AccelerometerEvent event) {
      // Count the number of events received, for debug only
      countEvents = countEvents + 1;
      // Create an accelerometer object from event data
      Accel ac = Accel(time: DateTime.now(), x: event.x, y: event.y, z: event.z, moto: vehicleUID );
      // Push the accel object into the queue
      accelQueue.add(ac);

      // Update x,y,z state variables (for display)
      setState(() {
      x = event.x;
      y = event.y;
      z = event.z;

      });
    });

    // Subscribe to the GPS location stream, request update every second
    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.bestForNavigation, intervalDuration: Duration(seconds: 1)).listen(

            (Position position) {
          print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());

          // Create position object
          Point p = Point(trip: vehicleUID, latitude: position.latitude, longitude: position.longitude, accuracy: position.accuracy, altitude: position.altitude, speed: position.speed, speedAccuracy: position.speedAccuracy, heading: position.heading, time: DateTime.now());
          // Add to processing queue
          gpsQueue.add(p);


          setState(() {
            latitude = position.latitude;
            longitude = position.longitude;
          });
        });


    Timer.periodic(thread2_delay, (Timer thread2Timer) {
      thread2();
    });

    Timer.periodic(thread4_delay, (Timer thread4Timer) {
      thread4();
    });

    Timer.periodic(exportLogsDelay, (Timer exportLogsTimer) {
      exportLogFiles();
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
                      Text(x != null
                          ? x.toStringAsFixed(3)
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
                      Text(y != null
                          ? y.toStringAsFixed(3)
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
                      Text(z != null
                          ? z.toStringAsFixed(3)
                          : 'nothing...'),
                    ],
                  ),
                ),
                Text(''),
                Text(
                  "GPS Data",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                ),
                Text(latitude != null
                    ? "latitude: " + latitude.toString()
                    : 'nothing...'),
                Text(longitude != null
                    ? "longitude: " + longitude.toString()
                    : 'nothing...'),
                Text(''),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Text(
                    "Vehicle ID",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                ),
                Text(vehicleID != null
                ? vehicleID : "Loading ......."),
                Text(''),
                TextField(
                  controller: myController,
                ),
                Text(''),
                FloatingActionButton.extended(
                  onPressed: () {
                    prefs.setString('vehicleID', myController.text.toString());
                    setState(() {
                      vehicleID = myController.text.toString();
                    });
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
