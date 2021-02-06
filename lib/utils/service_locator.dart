import 'package:device_info/device_info.dart';
import 'package:moto_monitor/models/moto.dart';
import 'package:moto_monitor/models/settings.dart';
import 'package:get_it/get_it.dart';
import 'package:f_logs/f_logs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foreground_service/foreground_service.dart';

// This is our global ServiceLocator
final GetIt getIt = GetIt.instance;

Future<void> setupConfig() async {

  SharedPreferences prefs;
  Settings settings;
  // obtain shared preferences
  prefs = await SharedPreferences.getInstance();

  // Get unique identifier of device
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  var uid = androidInfo.androidId;

  // Check if previous settings exist
  if (prefs.getString("settings") == null) {
    // Settings don't exist, create object
    FLog.info(className: "init", methodName: "service locator", text: "Settings doesn't exist in shared prefs");
    getIt.registerSingleton<Settings>(Settings(moto_uid: uid));
  } else {
    FLog.info(className: "init", methodName: "service locator", text: "Settings key exists, try to create object");
    try {
      var s = Settings.fromRawJson(prefs.getString('settings'));
      getIt.registerSingleton<Settings>(s);
    } catch (err) {
      FLog.info(className: "init", methodName: "service locator", text: "Failed to read settings json string");
      getIt.registerSingleton<Settings>(Settings(moto_uid: uid));
    }
  }

  // Create moto object and register in state
  FLog.info(className: "init", methodName: "service locator", text: "Vehicle ID ${androidInfo.androidId}");
  getIt.registerSingleton<Moto>(Moto(uid: uid));

  await getIt.allReady();

  getIt<Settings>().saveToPrefs();
}

void toggleForegroundServiceOnOff() async {
  final fgsIsRunning = await ForegroundService.foregroundServiceIsStarted();
  String appMessage;

  if (fgsIsRunning) {
    await ForegroundService.stopForegroundService();
    appMessage = "Stopped foreground service.";
    getIt<Moto>().sensorUnSubscribe();
    getIt<Settings>().isForegroundService = true;
  } else {
    maybeStartFGS();
    appMessage = "Started foreground service.";
    getIt<Moto>().sensorSubscribe();
    getIt<Settings>().isForegroundService = false;
  }
}

//use an async method so we can await
void maybeStartFGS() async {
  ///if the app was killed+relaunched, this function will be executed again
  ///but if the foreground service stayed alive,
  ///this does not need to be re-done
  if (!(await ForegroundService.foregroundServiceIsStarted())) {
    await ForegroundService.setServiceIntervalSeconds(5);

    //necessity of editMode is dubious (see function comments)
    await ForegroundService.notification.startEditMode();

    await ForegroundService.notification
        .setTitle("EWB Moto app recording");

    await ForegroundService.notification
        .setText("Data uploaded: ---");

    await ForegroundService.notification.finishEditMode();

    await ForegroundService.startForegroundService(foregroundServiceFunction);
    await ForegroundService.getWakeLock();
  }

  ///this exists solely in the main app/isolate,
  ///so needs to be redone after every app kill+relaunch
  await ForegroundService.setupIsolateCommunication((data) {
    print("main received: $data");
  });
}

void foregroundServiceFunction() {
  //ForegroundService.notification.setText("Data uploaded: 0");

  if (!ForegroundService.isIsolateCommunicationSetup) {

    ForegroundService.setupIsolateCommunication((data) {
      ForegroundService.notification.setText("Data uploaded: $data");
    });
  }
}
