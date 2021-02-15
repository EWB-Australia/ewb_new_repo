library web;
import 'dart:async';
import 'package:moto_monitor/models/moto.dart';
import 'package:moto_monitor/models/settings.dart';
import 'file_io.dart';
import 'package:f_logs/f_logs.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:filesize/filesize.dart';
import 'package:foreground_service/foreground_service.dart';
import 'service_locator.dart' as SL;

final uuid = Uuid();

Future<int> upload_file(url, filePath) async {
  final file = new File(filePath);

  // Get size of upload
  final fileSize = file.lengthSync();
  var request = new http.MultipartRequest("POST", Uri.parse(url));

  // add file to multipart
  request.files.add(new http.MultipartFile.fromBytes('file', await file.readAsBytes(), filename: basename(file.path)));
  // add auth code from settings
  request.headers['auth-token'] = SL.getIt<Settings>().authCode;

  var moto = SL.getIt<Moto>().uid;

  // Update the total bytse in settings
  SL.getIt<Settings>().bytesUploaded += fileSize;
  SL.getIt<Settings>().saveToPrefs();

  // Add moto UID to headers
  request.headers['moto'] = moto;

  FLog.info(className: "moto",
      methodName: "uploadfile", text: "Uploading file: ${basename(filePath)} Size: ${filesize(fileSize)}");
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    print(responseString);

    // Attempt to update foreground service
  if (await ForegroundService
      .isBackgroundIsolateSetupComplete()) {
    await ForegroundService.sendToPort(filesize(SL.getIt<Settings>().bytesUploaded));
    FLog.info(className: "moto",
        methodName: "Upload File", text: "Updated foreground service");
  } else {
    FLog.warning(className: "moto",
        methodName: "Upload File", text: "Can't communicate with foreground service");
  }
    return response.statusCode;
  }

Future<void> upload_delete(url, filePath) async {
    await upload_file(url, filePath).then((e) async {
      print("response ${e.toString()}");
      if (e == 200) {
        print("Delete file ${basename(filePath)}");
        await delete_file(filePath);
        //Don't delete, move file to processed directory

      } else {
        FLog.error(className: "moto",
            methodName: "uploadfile", text: "Error uploading file: ${basename(filePath)}}");
      }
    });
}