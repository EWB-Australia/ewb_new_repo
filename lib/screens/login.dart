// Login screen
//
// User needs a valid QR code to proceed to main app
// Code is sent to server for validation using http get headers
// When code is validated it is stored in shared_preferences

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ewb_app/screens/QRscan.dart';
import 'package:http/http.dart' as http;
import '../models/settings.dart';
import '../screens/dashboard.dart';
import 'package:f_logs/f_logs.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:async/async.dart';
import 'package:flutter/scheduler.dart';
import 'package:ewb_app/utils/service_locator.dart' as SL;

final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
SharedPreferences prefs;

class EWBlogin extends StatefulWidget {
  const EWBlogin({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EWBloginState();
}

class _EWBloginState extends State<EWBlogin> {
  bool _isButtonDisabled = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    this._isButtonDisabled = false;
  }

  @override
  Widget build(BuildContext context) {
    if (SL.getIt<Settings>()?.authCode?.isNotEmpty ?? false ) {
      return Dashboard();
    } else {
      return Scaffold(
        key: _scaffoldKey,
        body: Center(
          child: Container(
            padding: EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image(
                      image: AssetImage("assets/images/ewb_australia.png")),
                ),
                ListTile(
                  title: Text(
                    'Welcome',
                    style: Theme.of(context).textTheme.headline1,
                  ),
                  subtitle: Text(
                    '\nThis application requires an authorisation code to operate. Please scan the QR provided by your EWB coordinator to configure the application.\n\nFor support or queries please contact xxx@ewb.com.au',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
                RaisedButton(
                  color: Colors.yellow,
                  child:
                      this._isButtonDisabled ? Text("Hold on...") : Text("Scan QR"),
                  onPressed: () {
                    this._isButtonDisabled ? null : _navigateAndScanQR(context);
                  },
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  _navigateAndScanQR(BuildContext context) async {
    try {
      // Close any open snack bars from previous attempts
      _scaffoldKey.currentState.hideCurrentSnackBar();
    } on Exception catch (_) {
      FLog.info(text: "No previous snackbars open");
    }

    //Open QR reader and wait for result to be returned
    final String result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRscan()),
    );

    FLog.info(text: "Received result from QR scanner: $result");

    // Got result now disable scan button
    setState(() {
      this._isButtonDisabled = true;
    });

    var authCode = SL.getIt<Settings>().authCode;

    FLog.info(text: "Previous auth code stored in settings: $authCode");

    // Show a message to the user that we are validating QR code
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      duration: new Duration(minutes: 1),
      content: new Row(
        children: <Widget>[
          new CircularProgressIndicator(),
          SizedBox(width: 50),
          new Text("Validating QR code")
        ],
      ),
    ));

    FLog.info(text: "Check the web for new settings - TODO");
    // Check if there are new settings available
    //await settings.updateFromWeb();

    // Validate auth token with server,
    FLog.info(text: "Checking auth-token with server");
    var response = await http.get(
      'https://ewb.thinktransit.com.au/validate_auth_code/',
      // Send authorization headers to the backend.
      headers: {'auth-token': result},
    );

    // Get json data from response
    var responseJson = jsonDecode(response.body);

    FLog.info(text: "Server response: $responseJson");
    // Check response
    if (responseJson['result'] == true) {
      // Key validated, go to dashboard
      //
      // Store current auth code from QR
      SL.getIt<Settings>().authCode = result;
      SL.getIt<Settings>().saveToPrefs();

      FLog.info(text: "Key validated, push to Dashboard");
      // Wrap Navigator with SchedulerBinding to wait for rendering state before navigating
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
    } else {
      // Key did not validate
      // Hide current snack bar
      FLog.warning(text: "Auth code did not validate: $result");
      _scaffoldKey.currentState.hideCurrentSnackBar();
      // Show error message
      _scaffoldKey.currentState.showSnackBar(new SnackBar(
        duration: new Duration(seconds: 5),
        content: new Row(
          children: <Widget>[
            new Text("The QR code is incorrect, please try again")
          ],
        ),
      ));
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }
}
