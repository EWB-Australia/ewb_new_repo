// To parse this JSON data, do
//
//     final accel = accelFromJson(jsonString);

import 'dart:ffi';

import 'package:meta/meta.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Accel {
  Accel({
    @required this.moto,
    @required this.x,
    @required this.y,
    @required this.z,
    @required this.time
  });

  final String moto;
  final double x;
  final double y;
  final double z;
  final DateTime time;

  factory Accel.fromRawJson(String str) => Accel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Accel.fromJson(Map<String, dynamic> json) => Accel(
    moto: json["moto"],
    x: json["x"],
    y: json["y"],
    z: json["z"],
    time: DateTime.parse(json["time"]),
  );

  Map<String, dynamic> toJson() => {
    "moto": moto,
    "x": x,
    "y": y,
    "z": z,
    "time": time.toIso8601String(),
  };
}
