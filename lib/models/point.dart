// To parse this JSON data, do
//
//     final point = pointFromJson(jsonString);

import 'dart:ffi';

import 'package:meta/meta.dart';
import 'dart:convert';

class Point {
  Point({
    @required this.trip,
    @required this.latitude,
    @required this.longitude,
    @required this.accuracy,
    @required this.altitude,
    @required this.speed,
    @required this.speedAccuracy,
    @required this.heading,
    @required this.time,
  });

  String trip;
  double latitude;
  double longitude;
  double accuracy;
  double altitude;
  double speed;
  double speedAccuracy;
  double heading;
  DateTime time;

  factory Point.fromRawJson(String str) => Point.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Point.fromJson(Map<String, dynamic> json) => Point(
    trip: json["trip"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    accuracy: json["accuracy"],
    altitude: json["altitude"],
    speed: json["speed"],
    speedAccuracy: json["speedAccuracy"],
    heading: json["heading"],
    time: DateTime.parse(json["time"]),
  );

  Map<String, dynamic> toJson() => {
    "trip": trip,
    "latitude": latitude,
    "longitude": longitude,
    "accuracy": accuracy,
    "altitude": altitude,
    "speed": speed,
    "speedAccuracy": speedAccuracy,
    "heading": heading,
    "time": time.toIso8601String(),
  };
}
