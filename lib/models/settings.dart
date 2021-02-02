import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings({
  @required this.moto_uid,
  this.authCode,
  this.databaseURL = "https://kk9t74j5th.execute-api.ap-southeast-1.amazonaws.com/dev",
  this.bytesUploaded = 0,
  this.isOnline = false,
  this.isForegroundService = false,
  this.showDebugLog = false,
  this.showMap = false,
  this.recordLocation = true,
  this.recordAcceleration = true,
  this.recordBattery = true,
  this.dataProcessFrequency = Duration.secondsPerMinute*5,
  this.exportLogsDelay = Duration.secondsPerHour,
  this.accelMinSpeed = 15,
    this.distanceFilter = 10.0
  });

  String moto_uid;
  String authCode;
  String databaseURL = "https://kk9t74j5th.execute-api.ap-southeast-1.amazonaws.com/dev";
  int bytesUploaded = 0;
  bool isOnline = false;
  bool isForegroundService = false;
  bool showDebugLog = false;
  bool showMap = false;
  bool recordLocation = true;
  bool recordAcceleration = true;
  bool recordBattery = true;
  int dataProcessFrequency = Duration(minutes: 5).inSeconds;
  int exportLogsDelay = Duration(hours: 1).inSeconds;
  int accelMinSpeed = 15;
  double distanceFilter = 10.0;
  SharedPreferences prefs;
  Directory tmpDir;
  Directory cacheDir;

  factory Settings.fromRawJson(String str) => Settings.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Settings.fromJson(Map<String, dynamic> json) =>
      Settings(
        moto_uid: json["moto_uid"],
        authCode: json["authCode"],
        bytesUploaded: json["bytesUploaded"],
        databaseURL: json["databaseURL"],
        isOnline: json["isOnline"],
        isForegroundService: json["isForegroundService"],
        showDebugLog: json["showDebugLog"],
        showMap: json["showMap"],
        recordLocation: json["recordLocation"],
        recordAcceleration: json["recordAcceleration"],
        recordBattery: json["recordBattery"],
        dataProcessFrequency: json["dataProcessFrequency"],
        exportLogsDelay: json["exportLogsDelay"],
        accelMinSpeed: json["accelMinSpeed"],
        distanceFilter: json["distanceFilter"]
      );

  Map<String, dynamic> toJson() =>
      {
        "moto_uid": moto_uid,
        "authCode": authCode,
        "bytesUploaded": bytesUploaded,
        "databaseURL": databaseURL,
        "isOnline": isOnline,
        "isForegroundService": isForegroundService,
        "showDebugLog": showDebugLog,
        "showMap": showMap,
        "recordLocation": recordLocation,
        "recordAcceleration": recordAcceleration,
        "recordBattery": recordBattery,
        "dataProcessFrequency": dataProcessFrequency,
        "exportLogsDelay": exportLogsDelay,
        "accelMinSpeed": accelMinSpeed,
        "distanceFilter": distanceFilter
      };

  void setOnline() async {

    isOnline = true;
    notifyListeners();
  }

  void setOffline() {

    isOnline = false;
    notifyListeners();
  }

  // Set temporary and cache directories
  Future<void> setDirectories() async {

    tmpDir =  await getTemporaryDirectory();
    cacheDir = await getApplicationDocumentsDirectory();
  }

  // Check the server to see if there are any updated settings
  // TODO Implement later
  Future<bool> updateFromWeb() async {

    return true;
  }

  void saveToPrefs() async {

    prefs = await SharedPreferences.getInstance();

    prefs.setString('settings', this.toRawJson());

  }

  Future<void> clearPrefs() async {

    prefs = await SharedPreferences.getInstance();

    await prefs.remove('settings');

    await prefs.clear().then((value) => exit(0));
  }
}
