// To parse this JSON data, do
//
//     final battery = batteryFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

class Battery {
  Battery({
    @required this.moto,
    @required this.level,
  });

  String moto;
  int level;

  factory Battery.fromRawJson(String str) => Battery.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Battery.fromJson(Map<String, dynamic> json) => Battery(
    moto: json["moto"],
    level: json["level"],
  );

  Map<String, dynamic> toJson() => {
    "moto": moto,
    "level": level,
  };
}
