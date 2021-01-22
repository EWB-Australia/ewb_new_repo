import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';

  File createZipFile(String fileName) {
    final zipFilePath = fileName;
    final zipFile = File(zipFilePath);

    if (zipFile.existsSync()) {
      print("Deleting existing zip file: " + zipFile.path);
      zipFile.deleteSync();
    }
    return zipFile;
  }

