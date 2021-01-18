library file_io;

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

final uuid = Uuid();

//Helper Helper function that I got from the internet: https://stackoverflow.com/questions/61919395/how-to-generate-random-string-in-dart
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

String generate_filename() {
  //PLACEHOLDER
  return getRandomString(5);
}

Future<String> write_file(
    data_array, data_type, filename, folder, vehicleId) async {
  final Directory directory = await getExternalStorageDirectory();
  var new_file = '${directory.path}/${folder}/${filename}.txt';
  final File file = await File(new_file).create(recursive: true);

  final data = await file.readAsString();
  final sink = file.openWrite();
  sink.write(data +
      "$vehicleId, ${uuid.v4()}, ${DateTime.now()}, ${DateTime.now().timeZoneOffset}, $data_type, ${data_array.join(",")}||");
  sink.close();
  return await file.readAsString();
}

Future<void> move_file(filename, folder_from, folder_to)  async {
  final Directory directory = await getExternalStorageDirectory();
  print('Moving file: $filename from: $folder_from to: $folder_to');

  File file = await File(
      '${directory.path}/${folder_from}/${filename}.txt'); //gone to file and aquired it
  if (await File(file.path).exists()) {
    if (await Directory("${directory.path}/${folder_to}").exists()) {
      await file.rename(
          '${directory.path}/${folder_to}/$filename.txt'); //moving file to where it needs to go
    } else {
      final Directory folder_to_dir =
          await Directory("${directory.path}/${folder_to}")
              .create(recursive: true);
      await file.rename(
          '${folder_to_dir.path}/$filename.txt'); //moving file to where it needs to go
    }
  }
  return;
}

Future<void> delete_file(filename, folder) async {
  try {
    final Directory directory = await getExternalStorageDirectory();

    final Directory folder_dir =
        await Directory('${directory.path}/${folder}');

    File file = await File('${folder_dir.path}/${filename}.txt');

    if (await File(file.path).exists()) {
      await file.delete();
    }
    return;
  } catch (err) {
    print(err);
  }
}

Future<String> readFile(filename, folder) async {
  try {
    final directory = await getExternalStorageDirectory();
    File file = new File('${directory.path}/$folder/$filename');
    if (!await file.exists()) await file.create(recursive: true);
    return await file.readAsString();
  } catch (err) {
    print(err);
  }
}

Future<bool> check_folder_empty(folder) async {
  try {
    final Directory directory = await getExternalStorageDirectory();
    Directory dir = Directory('${directory.path}/${folder}');
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
