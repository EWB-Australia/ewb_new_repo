import 'dart:collection';
import 'package:moto_monitor/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:moto_monitor/utils/zip.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'dart:convert';
import 'package:moto_monitor/models/accel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'dart:async';
import 'dart:math';
import 'package:moto_monitor/models/point.dart';
import 'package:stream_transform/stream_transform.dart';
import 'dart:io';
import '../utils/web.dart';
import 'package:battery/battery.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import '../utils/service_locator.dart' as SL;
import 'package:connectivity_widget/connectivity_widget.dart';

class Moto extends ChangeNotifier {
  Moto({
    @required this.uid,
    this.name,
    this.rego,
  });

  double x, y, z, xV, yV, zV, heading, latitude = 0, longitude = 0;
  String uid;
  String name;
  String rego;
  LatLng location;
  int batLevel, speed = 0;
  Queue accelQueue = new Queue();
  Queue gpsQueue = new Queue();
  String vehicleID; // Vehicle ID which is editable on user screen

  StreamSubscription<Position> gpsStream;
  StreamSubscription<AccelerometerEvent> accelStream;
  StreamSubscription<UserAccelerometerEvent> userAccelStream;
  StreamSubscription<MagnetometerEvent> magnetStream;

  Vector3 _accelerometer = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAccelerometer = Vector3.zero();

  bool isRecordingAccel = false;

  List<CircleMarker> markers = new List<CircleMarker>();

  factory Moto.fromRawJson(String str) => Moto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Moto.fromJson(Map<String, dynamic> json) => Moto(
        uid: json["uid"],
        name: json["name"],
        rego: json["rego"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "rego": rego,
      };

  // Set up sensor subscriptions
  void sensorSubscribe() async {
    // Throttle stream using "audit" so we only get one event every 25ms
    accelStream = motionSensors.accelerometer
        .listen((AccelerometerEvent event) {

      if (SL.getIt<Settings>().recordAcceleration) {

        // Update x,y,z state variables (for display)
        _accelerometer.setValues(event.x, event.y, event.z);
        x = event.x;
        y = event.y;
        z = event.z;

        var matrix =
        motionSensors.getRotationMatrix(_accelerometer, _magnetometer);

        matrix.transform3(_userAccelerometer);

        xV = _userAccelerometer.x;
        yV = _userAccelerometer.y;
        zV = _userAccelerometer.z;

        // Push the accel object into the queue if speed greater than 15kmhr
        if (speed >= SL.getIt<Settings>().accelMinSpeed) {
          // Create an accelerometer object from event data
          Accel ac = Accel(
              time: DateTime.now(),
              x: xV,
              y: xV,
              z: xV,
              moto: uid);

          accelQueue.add(ac);
          isRecordingAccel = true;
        } else
          {
            isRecordingAccel = false;
          }

        notifyListeners();
      }

    });

    userAccelStream =
        motionSensors.userAccelerometer.listen((UserAccelerometerEvent event) {
      if (SL.getIt<Settings>().recordAcceleration) {
        _userAccelerometer.setValues(event.x, event.y, event.z);
      }
    });

    magnetStream = motionSensors.magnetometer.listen((MagnetometerEvent event) {
      if (SL.getIt<Settings>().recordAcceleration) {
        // Update x,y,z state variables (for display)
        _magnetometer.setValues(event.x, event.y, event.z);
      }
    });

    motionSensors.accelerometerUpdateInterval = Duration.microsecondsPerSecond ~/ 60;
    motionSensors.userAccelerometerUpdateInterval = Duration.microsecondsPerSecond ~/ 60;
    motionSensors.magnetometerUpdateInterval = Duration.microsecondsPerSecond ~/ 60;

  }

  // Setup sensor subscription for only the accelerometer
  // This is for basic phone suchas the Alcatel 1 B

  void sensorSubscribeAccelOnly() async {

    // Throttle stream using "audit" so we only get one event every 25ms
    accelStream = motionSensors.accelerometer
        .listen((AccelerometerEvent event) {

      if (SL.getIt<Settings>().recordAcceleration) {

        // Update x,y,z state variables (for display)
        _accelerometer.setValues(event.x, event.y, event.z);
        x = event.x;
        y = event.y;
        z = event.z;

        //Vector3 _userAccelerometer = _accelerometer.cross(SL.getIt<Settings>().gravityVector).normalized();

        // Subtract gravity vector from accelerometer readings
        xV = x - SL.getIt<Settings>().gravityVector.x;
        yV = y - SL.getIt<Settings>().gravityVector.y;
        zV = z - SL.getIt<Settings>().gravityVector.z;

        // Push the accel object into the queue if speed greater than 15kmhr
        if (speed >= SL.getIt<Settings>().accelMinSpeed) {
          // Create an accelerometer object from event data
          Accel ac = Accel(
              time: DateTime.now(),
              x: xV,
              y: xV,
              z: xV,
              moto: uid);

          accelQueue.add(ac);
          isRecordingAccel = true;
        } else
        {
          isRecordingAccel = false;
        }

        notifyListeners();
      }
    });

    motionSensors.accelerometerUpdateInterval = Duration.microsecondsPerSecond ~/ SL.getIt<Settings>().accelSamplesPerSecond;
  }

  void gpsSubscribe() async {

// Subscribe to the GPS location stream, request update every second
    gpsStream = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: Duration(seconds: 1))
        .listen((Position position) {
      if (SL.getIt<Settings>().recordLocation) {
        final double distance = Geolocator.distanceBetween(
            latitude, longitude, position.latitude, position.longitude);

        // only update location if we have travelled more than 10 metres
        if (distance >= SL.getIt<Settings>().distanceFilter) {
          latitude = position.latitude;
          longitude = position.longitude;

          // Create position object
          Point p = Point(
              trip: uid,
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              altitude: position.altitude,
              speed: position.speed,
              speedAccuracy: position.speedAccuracy,
              heading: position.heading,
              time: DateTime.now());

          // Add to processing queue
          gpsQueue.add(p);

          // Add marker to map if distance > distanec filter
          if (speed > SL.getIt<Settings>().accelMinSpeed) {
            var cm = CircleMarker(
                radius: 5,
                color: Colors.blue,
                point: LatLng(p.latitude, p.longitude));
            markers.add(cm);
          } else {
            var cm = CircleMarker(
                radius: 5,
                color: Colors.amber,
                point: LatLng(p.latitude, p.longitude));
            markers.add(cm);
          }
        }

        speed = (position.speed * 3.6).toInt();
        location = LatLng(position.latitude, position.longitude);
        heading = position.heading;

        notifyListeners();
      }
    });
  }

  // Dispose of sensor streams
  void sensorUnSubscribe() {
    if (gpsStream != null) gpsStream.cancel();
    if (accelStream != null) accelStream.cancel();
    if (userAccelStream != null) userAccelStream.cancel();
    if (magnetStream != null) magnetStream.cancel();
  }

  // Return a list of object from a Q for processing
  List<dynamic> popQueue(q) {
    // Temp list of objects
    List<dynamic> ld = new List<dynamic>();

    // Get length of Q
    var length_q = q.length;

    // Move items from the Q to temp list
    for (var i = length_q; i >= 1; i--) {
      ld.add(q.first);
      q.removeFirst();
    }

    return ld;
  }

  Future<int> getBattery() async {
    if (SL.getIt<Settings>().recordBattery) {
      var _battery = Battery();
      var level = await _battery.batteryLevel;
      return level;
    } else {
      return null;
    }
  }

  Future<void> processDataQueues() async {
    if (accelQueue.length > 0 || gpsQueue.length > 0) {
      Directory uploadDir =
          Directory('${SL.getIt<Settings>().cacheDir.path}/upload');

      List<dynamic> gList = new List<dynamic>();
      List<dynamic> aList = new List<dynamic>();

      Random random = new Random();
      int randomNumber = random.nextInt(9000) + 1000;

      List<File> files = [];

      if (accelQueue.length > 0) {
        // Get list of accelerometer readings from Q
        aList = popQueue(accelQueue);
      }

      if (gpsQueue.length > 0) {
        // Get list of gps readings from Q
        gList = popQueue(gpsQueue);
      }

      final File payloadFile =
          await File('${SL.getIt<Settings>().cacheDir.path}/payload.json')
              .create(recursive: true);

      // Pacakge all the data we need to send into a json file
      final payload = {
        'moto': uid,
        'trip': uid,
        'batteryLevel': await getBattery() ?? '',
        'gps_values': gList,
        'acceleration_values': aList
      };
      // Write the file.
      payloadFile.writeAsStringSync(json.encode(payload));

      files.add(payloadFile);

      if (files.length > 0) {
        print("compressing");

        final zipFile = createZipFile(
            '${SL.getIt<Settings>().cacheDir.path}/${randomNumber.toString()}.zip');

        // Try to create zip file
        await ZipFile.createFromFiles(
            sourceDir: SL.getIt<Settings>().cacheDir,
            files: [
              payloadFile,
            ],
            zipFile: zipFile);

        // Move file to upload directory
        await zipFile.rename(
            '${SL.getIt<Settings>().cacheDir.path}/upload/${randomNumber.toString()}.zip');

        // Don't follow links and dont scan sub-folders
        uploadDir.list(recursive: false, followLinks: false).listen((e) async {
          // TODO UPLOAD ALL FILES IN DIRECTORY INCLUDING LOGS
          // Only upload if we have internet connection
          var isOnlineNow = await ConnectivityUtils.instance.isPhoneConnected();
          if (isOnlineNow) {
            await upload_delete(SL.getIt<Settings>().databaseURL, e.path);
          }
        });
      }
    }
  }
}
