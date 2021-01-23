// To parse this JSON data, do
//
//     final moto = motoFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

class Moto {
  Moto({
    @required this.uid,
    this.name,
    this.rego,
  });

  String uid;
  String name;
  String rego;

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
}
