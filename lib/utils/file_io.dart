library file_io;
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:ewb_app/models/settings.dart';
import 'package:uuid/uuid.dart';

import 'package:ewb_app/utils/service_locator.dart' as SL;

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
  final Directory _appCacheDir = SL.getIt<Settings>().cacheDir;
  final Directory _appCacheDirFolder =
      Directory('${_appCacheDir.path}/$folderName/');

  print('Directory to create: $_appCacheDirFolder');

  if (await _appCacheDirFolder.exists()) {
    //if folder already exists return path
    return _appCacheDirFolder;
  } else {
    //if folder not exists create folder and then return its path
    final Directory _appCacheDirNewFolder =
        await _appCacheDirFolder.create(recursive: true);
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

  final File file = await File('${folderPath}/${filename}.${extension}')
      .create(recursive: true);

  // Write the file.
  return file.writeAsString(data);
}

Future<void> delete_file(filePath) async {
  try {
    File file = await File(filePath);
    await file.delete();
  } catch (err) {
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
