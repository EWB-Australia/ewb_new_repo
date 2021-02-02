import 'package:ewb_app/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:f_logs/f_logs.dart';
import 'package:intl/intl.dart';
import 'package:ewb_app/utils/service_locator.dart' as SL;


final f = new DateFormat('yyyy-MM-dd HH:mm');

class Debug extends StatefulWidget {
  @override
  _DebugState createState() => _DebugState();
}

class _DebugState extends State<Debug>
    with AutomaticKeepAliveClientMixin<Debug> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  Widget projectWidget() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.connectionState == ConnectionState.none &&
            projectSnap.hasData == null) {
          return Container();
        }
        return ListView.builder(
          controller: _scrollController,
          itemCount: projectSnap.data?.length ?? 0,
          //reverse: true,
          itemBuilder: (context, index) {
            var log = projectSnap.data[index];
            var date = DateTime.fromMillisecondsSinceEpoch(log.timeInMillis);

            return Column(children: <Widget>[
              ListTile(
                title: Text(f.format(date)),
                tileColor: _getColour(log.logLevel.toString()),
                subtitle: Text(
                    "${log.logLevel.toString().split('.')[1]} - ${log.text.toString()}"),
                selected: false,
              ),
              SizedBox(
                height: 5,
              )
            ]);
          },
        );
      },
      future: FLog.getAllLogsByFilter(filterType: FilterType.LAST_24_HOURS),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text('Log'),
        leading: Icon(Icons.build_rounded),
      ),
      body: Column(children: [
        SizedBox(
          height: 25,
        ),
        SL.getIt<Settings>().showDebugLog
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RaisedButton(
                    color: Colors.yellow,
                    child: Text("Clear logs"),
                    onPressed: () {
                      FLog.clearLogs();
                    },
                  ),
                  RaisedButton(
                    color: Colors.yellow,
                    child: Text("Go to bottom"),
                    onPressed: () {
                      _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.fastOutSlowIn);
                    },
                  ),
                  RaisedButton(
                    color: Colors.yellow,
                    child: Text("Export logs"),
                    onPressed: () {
                      FLog.exportLogs();
                    },
                  )
                ],
              )
            : SizedBox(
                height: 25,
              ),
        Expanded(
          child: SL.getIt<Settings>().showDebugLog
              ? projectWidget()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                      const ListTile(
                        leading: Icon(Icons.warning_amber_outlined),
                        title: Text('Debug logger is disabled.'),
                        subtitle:
                            Text('You can enable it in the settings tab.'),
                      ),
                    ]),
        ),
      ]),
    );
  }

  Color _getColour(String level) {
    if (level == "LogLevel.INFO") {
      return Colors.lightGreen[100];
    }
    if (level == "LogLevel.WARNING") {
      return Colors.yellow[800];
    }
    if (level == "LogLevel.ERROR") {
      return Colors.red[800];
    } else {
      return Colors.white;
    }
  }

  @override
  bool get wantKeepAlive => true;
}
