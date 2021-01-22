library web;

import 'dart:async';
import 'package:async/async.dart';
import 'file_io.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

final uuid = Uuid();
final auth_token = '1NxqnduNW8XXQcwOMV0jSafNAZtE6VnUwkmSGdjvmPxPIjhlSqxj3g1mjIddCWmbgpKUzfX2cz2CoBOPiJsGxu0BwoavHpayN1G67ltDV0dxqQsBWb21FaBNdlZd8grdSZrYRGw2QvRaXQSkjrIU68d04xUppVTNRCKAikmL9IbsKZWZcsHRhUeWMJyaZp2CmupR604H';

Future<int> upload_file(url, filePath) async {
  print('Uploading to $url');

  final file = new File(filePath);

  var request = new http.MultipartRequest("POST", Uri.parse(url));

  // add file to multipart
  request.files.add(new http.MultipartFile.fromBytes('file', await file.readAsBytes(), filename: basename(file.path)));
  request.headers['auth_token'] = auth_token;

  final prefs = await SharedPreferences.getInstance();

  // Try reading data from the counter key. If it doesn't exist, return 0.
  final moto = prefs.getString('vehicleUID') ?? 0;
  request.headers['moto'] = moto;

  var response = await request.send();
  var responseData = await response.stream.toBytes();
  var responseString = String.fromCharCodes(responseData);
  print(responseString);

  return response.statusCode;
}

Future<void> upload_delete(url, filePath) async {
  try {
    await upload_file(url, filePath).then((e) async {
      print("response ${e.toString()}");
      if (e == 200) {
        print("Delete file ${basename(filePath)}");
        await delete_file(filePath);
      } else {
        print("upload error!!!!!!!!!");
      }
    });
  } catch (err) {
    print("upload_delete failed");
    print(err);
  }
}

Future<bool> is_connected() async {
  var connectivtyResult = await Connectivity().checkConnectivity();
  // print(connectivtyResult != ConnectivityResult.none
  //     ? "CONNECTED"
  //     : "NOT CONNECTED");
  return connectivtyResult != ConnectivityResult.none ? true : false;
}

Future<bool> ping_server(url) async {
  try {
    print('pinging $url');
    var response = await http.get(url);
    print(response.statusCode);
    if (response.statusCode == 200) {
      print("succeed to ping server");
      return true;
    } else {
      print("failed to ping server");
      return false;
    }
  } catch (err) {
    print("ping_server() failed");
    return false;
  }
}

Future<int> ping_button(url, string) async {
  print('SERVER PING BUTTTON PRESSED');
  var response = await http.post(url, body: {'payload': '$string'});
  print(response.statusCode);
  return response.statusCode;
}
