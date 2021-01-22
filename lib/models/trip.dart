// To parse this JSON data, do
//
//     final trip = tripFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

class Trip {
  Trip({
    @required this.id,
    @required this.moto,
    @required this.name,
  });

  int id;
  String moto;
  String name;

  factory Trip.fromRawJson(String str) => Trip.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json["id"],
    moto: json["moto"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "moto": moto,
    "name": name,
  };
}
