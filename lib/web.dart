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

final uuid = Uuid();
final auth_token = '1NxqnduNW8XXQcwOMV0jSafNAZtE6VnUwkmSGdjvmPxPIjhlSqxj3g1mjIddCWmbgpKUzfX2cz2CoBOPiJsGxu0BwoavHpayN1G67ltDV0dxqQsBWb21FaBNdlZd8grdSZrYRGw2QvRaXQSkjrIU68d04xUppVTNRCKAikmL9IbsKZWZcsHRhUeWMJyaZp2CmupR604H';

Future<int> upload_file(url, fileToUpload, folder) async {
  print('sending to $url');

  final Directory directory = await getExternalStorageDirectory();
  var pth = '${directory.path}/${folder}/${fileToUpload}.txt';

  //var data = await readFile(fileToUpload, folder);
  final file = new File(pth);

  var request = new http.MultipartRequest("POST", Uri.parse(url));

  var stream = new http.ByteStream(DelegatingStream.typed(file.openRead()));
  var length = await file.length();

  // multipart that takes file
  var multipartFile = new http.MultipartFile('file', stream, length, filename: basename(file.path));

  // add file to multipart
  request.files.add(multipartFile);
  request.headers['auth_token'] = auth_token;
  try {
    var moto = await read_ID("savedID");
    request.headers['moto'] = moto;
  } catch (err) {
    print("error getting id");
    print(err);
  }


  var response = await request.send();
  var responseData = await response.stream.toBytes();
  var responseString = String.fromCharCodes(responseData);
  print(responseString);

  return response.statusCode;
}

Future<void> upload_delete(url, filename, folder) async {
  try {
    await upload_file(url, filename, folder).then((e) async {
      print("response ${e.toString()}");
      if (e == 200) {
        print("Delete file ${filename}");
        await delete_file(filename, folder);
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
    print('pinging $url/ping');
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
