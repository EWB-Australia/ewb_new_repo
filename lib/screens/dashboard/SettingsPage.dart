import 'package:moto_monitor/models/moto.dart';
import 'package:moto_monitor/models/settings.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:moto_monitor/utils/service_locator.dart' as SL;

final f = new DateFormat('yyyy-MM-dd HH:mm');

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {

  TextEditingController _textFieldController = TextEditingController();
  String codeDialog;
  String valueText = SL.getIt<Settings>().moto_name;

  @override
  void initState() {
    _textFieldController = new TextEditingController(text: SL.getIt<Settings>().moto_name);
    super.initState();
  }


  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('Settings'),
          leading: Icon(Icons.settings),
        ),
        body: ListView(
          children: <Widget>[
            Row(children: <Widget>[
              Flexible(
                child: SwitchListTile(
                  title: const Text('Show map'),
                  value: SL.getIt<Settings>().showMap,
                  onChanged: (bool value) {
                    setState(() {
                      SL.getIt<Settings>().showMap = value;
                      SL.getIt<Settings>().saveToPrefs();
                    });
                  },
                  secondary: const Icon(Icons.map_outlined),
                ),
              ),
            ]),
            Row(
              children: <Widget>[
                Flexible(
                  child: SwitchListTile(
                    title: const Text('Show debug log'),
                    value: SL.getIt<Settings>().showDebugLog,
                    onChanged: (bool value) {
                      setState(() {
                        SL.getIt<Settings>().showDebugLog = value;
                        SL.getIt<Settings>().saveToPrefs();
                      });
                    },
                    secondary: const Icon(Icons.build_rounded),
                  ),
                )
              ],
            ),
            Row(children: <Widget>[
              Flexible(
                child: ListTile(
                  leading: Icon(Icons.directions_car_outlined),
                  title: Text('Moto name'),
                  subtitle: Text(valueText ?? "NOT SET"),
                  trailing: RaisedButton(
                    color: Colors.yellow,
                    child: Text("Edit"),
                    onPressed: () {
                      setState(() {
                        _displayTextInputDialog(context);
                      });
                    },
                  ),
                ),
              ),
            ]),
            const Divider(
              color: Colors.black,
              height: 20,
              thickness: 5,
              indent: 0,
              endIndent: 0,
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: SwitchListTile(
                    title: const Text('Record Location'),
                    value: SL.getIt<Settings>().recordLocation,
                    onChanged: (bool value) {
                      setState(() {
                        SL.getIt<Settings>().recordLocation = value;
                        SL.getIt<Settings>().saveToPrefs();
                      });
                    },
                    secondary: const Icon(Icons.location_on_outlined),
                  ),
                )
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: SwitchListTile(
                    title: const Text('Record acceleration'),
                    value: SL.getIt<Settings>().recordAcceleration,
                    onChanged: (bool value) {
                      setState(() {
                        SL.getIt<Settings>().recordAcceleration = value;
                        SL.getIt<Settings>().saveToPrefs();
                      });
                    },
                    secondary: const Icon(Icons.compare_arrows),
                  ),
                )
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: SwitchListTile(
                    title: const Text('Record battery level'),
                    value: SL.getIt<Settings>().recordBattery,
                    onChanged: (bool value) {
                      setState(() {
                        SL.getIt<Settings>().recordBattery = value;
                        SL.getIt<Settings>().saveToPrefs();
                      });
                    },
                    secondary: const Icon(Icons.battery_full),
                  ),
                )
              ],
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: SwitchListTile(
                    title: const Text('Sleep mode'),
                    value: SL.getIt<Settings>().sleepMode,
                    onChanged: (bool value) {
                      setState(() {
                        SL.getIt<Settings>().sleepMode = value;
                        value ? SL.sleepModeOn() : SL.sleepModeOff();
                      });
                    },
                    secondary:
                        const Icon(Icons.airline_seat_legroom_extra_outlined),
                  ),
                )
              ],
            ),
            const Divider(
              color: Colors.black,
              height: 20,
              thickness: 5,
              indent: 0,
              endIndent: 0,
            ),
            ListTile(
              leading: Icon(Icons.architecture),
              title: Text('Record/calibrate inclination of phone'),
              trailing: RaisedButton(
                color: Colors.yellow,
                child: Text("Calibrate"),
                onPressed: () {
                  SL.getIt<Settings>().bytesUploaded = 0;
                  SL.getIt<Settings>().saveToPrefs();
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.vpn_key_outlined),
              title: Text('Clear auth/settings (force QR rescan)'),
              trailing: RaisedButton(
                color: Colors.yellow,
                child: Text("Clear"),
                onPressed: () {
                  SL.getIt<Settings>().clearPrefs();
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.cloud_upload_outlined),
              title: Text('Reset data counter'),
              trailing: RaisedButton(
                color: Colors.yellow,
                child: Text("Reset"),
                onPressed: () {
                  SL.getIt<Settings>().bytesUploaded = 0;
                  SL.getIt<Settings>().saveToPrefs();
                },
              ),
            ),
            const Divider(
              color: Colors.black,
              height: 20,
              thickness: 5,
              indent: 0,
              endIndent: 0,
            ),
            ListTile(
              leading: Icon(Icons.directions_car_outlined),
              title: Text('Moto Unique ID'),
              subtitle: Text(SL.getIt<Moto>().uid ?? "NONE"),
            ),
            ListTile(
              leading: Icon(Icons.directions_car_outlined),
              title: Text('App version'),
              subtitle: Text(SL.getIt<Settings>().packageInfo.version ?? "NONE"),
            ),
            ListTile(
              leading: Icon(Icons.vpn_key_outlined),
              title: Text('Auth key'),
              subtitle: Text(SL.getIt<Settings>().authCode ?? "NONE"),
            ),
            ListTile(
              leading: Icon(Icons.cloud_upload_outlined),
              title: Text('Uploaded data'),
              subtitle:
                  Text(filesize(SL.getIt<Settings>().bytesUploaded) ?? "---"),
            ),
            ListTile(
              leading: Icon(Icons.disc_full_outlined),
              title: Text('GPS Q size'),
              subtitle:
                  Text(SL.getIt<Moto>().gpsQueue.length.toString() ?? "---"),
            ),
            ListTile(
              leading: Icon(Icons.disc_full_outlined),
              title: Text('Accelerometer Q size'),
              subtitle:
                  Text(SL.getIt<Moto>().accelQueue.length.toString() ?? "---"),
            ),
            ListTile(
              leading: Icon(Icons.timer),
              title: Text('Data process frequency (seconds)'),
              subtitle: Text(
                  SL.getIt<Settings>().dataProcessFrequency.toString() ??
                      "NONE"),
            ),
          ],
        ));
  }



  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Moto name'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  SL.getIt<Moto>().name = value;
                });
              },
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Moto name"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    valueText = _textFieldController.text;
                    SL.getIt<Moto>().name = _textFieldController.text;
                    SL.getIt<Settings>().moto_name = _textFieldController.text;
                    SL.getIt<Settings>().saveToPrefs();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}
