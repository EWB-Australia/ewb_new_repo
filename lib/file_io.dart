library file_io;

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final uuid = Uuid();

//Helper Helper function that I got from the internet: https://stackoverflow.com/questions/61919395/how-to-generate-random-string-in-dart
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

String generateFilename() {
  //PLACEHOLDER
  return getRandomString(6);
}

Future<Directory> createFolderInCache(String folderName) async {

//Get this App Document Directory
final Directory _appCacheDir = await getTemporaryDirectory();
final Directory _appCacheDirFolder =  Directory('${_appCacheDir.path}/$folderName/');

print('Directory to create: $_appCacheDirFolder');

if(await _appCacheDirFolder.exists()){ //if folder already exists return path
  return _appCacheDirFolder;
}else{//if folder not exists create folder and then return its path
  final Directory _appCacheDirNewFolder=await _appCacheDirFolder.create(recursive: true);
return _appCacheDirNewFolder;
}
}

Future<File> writeFile(filePath, data) async {

  final File file = await File(filePath).create(recursive: true);

  // Write the file.
  return file.writeAsString(data);
}

Future<File> writeFileRandomName(folderPath, extension, data) async {

  var filename = generateFilename();

  final File file = await File('${folderPath}/${filename}.${extension}').create(recursive: true);

  // Write the file.
  return file.writeAsString(data);
}

Future<void> delete_file(filePath) async {
  try {
    File file = await File(filePath);
    await file.delete();
  } catch (err)
  {
    print(err);
  }
}

Future<String> readFile(filePath) async {
  try {
    File file = new File(filePath);
    if (!await file.exists()) await file.create(recursive: true);
    return await file.readAsString();
  } catch (err) {
    print(err);
  }
}

Future<bool> check_folder_empty(folderPath) async {
  try {
    Directory dir = Directory(folderPath);
    List files = dir.listSync();
    return files.isEmpty;
  } catch (err) {
    print(err);
    return false;
  }
}

Future<bool> movement_detection(filename, folder, distance_threshold) async {
  final Directory directory = await getExternalStorageDirectory();
  var file = File('${directory.path}/${folder}/$filename.txt');
  String data =
      await file.readAsString(); // read the file's data as one big string
  List lines = data.split("||"); // split the big string at ||
  lines.remove(''); // remove the last element in lines cuz it's empty

  List gpsLines = lines.where((x) {
    return x.split(',').length > 6 ? x.split(',')[4] == ' gps' : false;
  }).toList(); // add only gps data from lines to gpsLines

  if (gpsLines.length == 0) {
    return false;
  }

  List initial = gpsLines[0]
      .split(","); // split the two values of each line where split by a comma
  double lat1 = double.tryParse(initial[5]); //get latitude
  double lon1 = double.tryParse(initial[6]); //get longitude

  for (int i = 1; i < gpsLines.length; i++) {
    List currentLine = gpsLines[i].split(",");
    double lat2 = double.tryParse(currentLine[5]); //getting second set of data
    double lon2 = double.tryParse(currentLine[6]);

    var distanceLength = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    if (distanceLength >= distance_threshold) {
      return true;
    }
  }
  return false;
}

Future<void> save_ID(string, id) async {
  final Directory directory = await getExternalStorageDirectory();
  var file = File('${directory.path}/$string.txt');
  file.create(recursive: true);
  final sink = file.openWrite();
  sink.write(id);
  sink.close();
}

Future<bool> check_ID(string) async {
  final Directory directory = await getExternalStorageDirectory();
  var file = File('${directory.path}/$string.txt');
  return await file.exists();
}

Future<void> delete_ID(string) async {
  final Directory directory = await getExternalStorageDirectory();
  var file = File('${directory.path}/$string.txt');
  await file.delete();
}

Future<String> read_ID(string) async {
  final Directory directory = await getExternalStorageDirectory();
  var file = File('${directory.path}/$string.txt');
  return await file.readAsString();
}
