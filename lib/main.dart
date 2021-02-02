import 'package:device_info/device_info.dart';
import 'package:ewb_app/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'utils/theme.dart';
import 'screens/login.dart';
import 'utils/service_locator.dart' as SL;


var uuid = Uuid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SL.setupConfig();
  runApp(EWBApp());
}

class EWBApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EWB Moto app',
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => EWBlogin(),
        '/dashboard': (context) => Dashboard(),
      },
    );
  }
}
