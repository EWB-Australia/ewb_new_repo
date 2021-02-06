import 'package:moto_monitor/models/moto.dart';
import 'package:moto_monitor/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:connectivity_widget/connectivity_widget.dart';
import 'package:filesize/filesize.dart';
import '../../utils/service_locator.dart' as SL;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

List<StaggeredTile> _staggeredTiles = <StaggeredTile>[
  StaggeredTile.count(4, 1),
  StaggeredTile.count(4, 1),
  StaggeredTile.count(4, 4),
  StaggeredTile.count(4, 4),
  StaggeredTile.count(8, 1),
  StaggeredTile.count(4, 1),
  StaggeredTile.count(4, 1),
  StaggeredTile.count(4, 1),
  StaggeredTile.count(4, 1),
  StaggeredTile.count(8, 1),
  StaggeredTile.count(2, 2),
  StaggeredTile.count(2, 2),
  StaggeredTile.count(2, 2),
  StaggeredTile.count(2, 2),
  StaggeredTile.count(8, 4),
];

void _connectivityOnline() {
  SL.getIt<Settings>().setOnline();
}

void _connectivityOffline() {
  SL.getIt<Settings>().setOffline();
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    List<Widget> _tiles = <Widget>[
      _TextTile(Text("Speed",
          textScaleFactor: 1.5, style: TextStyle(fontWeight: FontWeight.bold))),
      _TextTile(Text("Heading",
          textScaleFactor: 1.5, style: TextStyle(fontWeight: FontWeight.bold))),
      _getRadialSpeedo(),
      _getRadialCompass(),
      _TextTile(Text("GPS",
          textScaleFactor: 1.5, style: TextStyle(fontWeight: FontWeight.bold))),
      _TextTile(Text("Latitude",
          textScaleFactor: 1.5, style: TextStyle(fontWeight: FontWeight.bold))),
      _TextTile(Text(SL.getIt<Moto>().latitude.toString(), textScaleFactor: 1)),
      _TextTile(Text("Longitude",
          textScaleFactor: 1.5, style: TextStyle(fontWeight: FontWeight.bold))),
      _TextTile(
          Text(SL.getIt<Moto>().longitude.toString(), textScaleFactor: 1)),
      _TextTile(Text("Accelerometer",
          textScaleFactor: 1.5, style: TextStyle(fontWeight: FontWeight.bold))),
      _getRangePointerGauge(SL.getIt<Moto>().xV, Colors.green),
      _getRangePointerGauge(SL.getIt<Moto>().yV, Colors.red),
      _getRangePointerGauge(SL.getIt<Moto>().zV, Colors.blue),
      _accelerometerStatusTile(),
    ];

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Dashboard'),
          leading: Icon(Icons.dashboard),
          actions: [
            Padding(
                padding: EdgeInsets.all(15),
                child: ElevatedButton.icon(
                  label: SL.getIt<Settings>().isForegroundService
                      ? Text("Record")
                      : Text("Stop"),
                  icon: SL.getIt<Settings>().isForegroundService
                      ? Icon(Icons.play_arrow)
                      : Icon(Icons.stop),
                  onPressed: () {
                    setState(() {
                      SL.toggleForegroundServiceOnOff();
                    });

                  },
                  style: ElevatedButton.styleFrom(
                    primary: SL.getIt<Settings>().isForegroundService
                        ? Colors.lightGreen
                        : Colors.redAccent,
                  ),
                )),
          ],
        ),
        body: ConnectivityWidget(
            onlineCallback: _connectivityOnline,
            offlineCallback: _connectivityOffline,
            builder: (context, isOnline) => Container(
                child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: new StaggeredGridView.count(
                      crossAxisCount: 8,
                      staggeredTiles: _staggeredTiles,
                      children: _tiles,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      padding: const EdgeInsets.all(4.0),
                    )))));
  }

  SfRadialGauge _getRadialSpeedo() {
    return SfRadialGauge(axes: <RadialAxis>[
      RadialAxis(minimum: 0, maximum: 150, ranges: <GaugeRange>[
        GaugeRange(startValue: 0, endValue: 15, color: Colors.orange),
        GaugeRange(startValue: 15, endValue: 110, color: Colors.green),
        GaugeRange(startValue: 110, endValue: 150, color: Colors.red)
      ], pointers: <GaugePointer>[
        NeedlePointer(
          value: SL.getIt<Moto>().speed.toDouble() ?? 0,
          knobStyle: KnobStyle(knobRadius: 0),
        )
      ], annotations: <GaugeAnnotation>[
        GaugeAnnotation(
            verticalAlignment: GaugeAlignment.far,
            angle: 90,
            positionFactor: 0,
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(SL.getIt<Moto>().speed.toString() ?? "",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 30)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: Text(
                    'km/h',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 14),
                  ),
                )
              ],
            ))
      ])
    ]);
  }

  /// Returns the direction compass gauge using annotation support
  SfRadialGauge _getRadialCompass() {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
            showAxisLine: false,
            ticksPosition: ElementsPosition.outside,
            labelsPosition: ElementsPosition.outside,
            startAngle: 320,
            endAngle: 320,
            minorTicksPerInterval: 10,
            minimum: 0,
            maximum: 360,
            showLastLabel: false,
            interval: 30,
            labelOffset: 20,
            majorTickStyle:
                MajorTickStyle(length: 0.16, lengthUnit: GaugeSizeUnit.factor),
            minorTickStyle: MinorTickStyle(
                length: 0.16, lengthUnit: GaugeSizeUnit.factor, thickness: 1),
            axisLabelStyle: GaugeTextStyle(fontSize: 12),
            pointers: <GaugePointer>[
              MarkerPointer(
                  value: SL.getIt<Moto>().heading ?? 0,
                  markerType: MarkerType.triangle),
              NeedlePointer(
                  value: 310,
                  needleLength: 0.5,
                  lengthUnit: GaugeSizeUnit.factor,
                  needleColor: const Color(0xFFC4C4C4),
                  needleStartWidth: 1,
                  needleEndWidth: 1,
                  knobStyle: KnobStyle(knobRadius: 0),
                  tailStyle: TailStyle(
                      color: const Color(0xFFC4C4C4),
                      width: 1,
                      lengthUnit: GaugeSizeUnit.factor,
                      length: 0.5)),
              NeedlePointer(
                value: 221,
                needleLength: 0.5,
                lengthUnit: GaugeSizeUnit.factor,
                needleColor: const Color(0xFFC4C4C4),
                needleStartWidth: 1,
                needleEndWidth: 1,
                knobStyle:
                    KnobStyle(knobRadius: 0, sizeUnit: GaugeSizeUnit.factor),
              ),
              NeedlePointer(
                value: 40,
                needleLength: 0.5,
                lengthUnit: GaugeSizeUnit.factor,
                needleColor: const Color(0xFFC4C4C4),
                needleStartWidth: 1,
                needleEndWidth: 1,
                knobStyle: KnobStyle(knobRadius: 0),
              )
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  angle: 230,
                  positionFactor: 0.38,
                  widget: Container(
                    child: Text('W',
                        style: TextStyle(
                            fontFamily: 'Times',
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  )),
              GaugeAnnotation(
                  angle: 310,
                  positionFactor: 0.38,
                  widget: Container(
                    child: Text('N',
                        style: TextStyle(
                            fontFamily: 'Times',
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  )),
              GaugeAnnotation(
                  angle: 129,
                  positionFactor: 0.38,
                  widget: Container(
                    child: Text('S',
                        style: TextStyle(
                            fontFamily: 'Times',
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  )),
              GaugeAnnotation(
                  angle: 50,
                  positionFactor: 0.38,
                  widget: Container(
                    child: Text('E',
                        style: TextStyle(
                            fontFamily: 'Times',
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ))
            ])
      ],
    );
  }

  SfRadialGauge _getRangePointerGauge(double inputVal, Color color) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
            showLabels: false,
            showTicks: false,
            startAngle: 270,
            endAngle: 270,
            minimum: 0,
            maximum: 25,
            radiusFactor: 0.8,
            axisLineStyle: AxisLineStyle(
                thicknessUnit: GaugeSizeUnit.factor, thickness: 0.15),
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  angle: 180,
                  widget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        child: Text(
                          inputVal?.toStringAsFixed(2) ?? "0",
                          style: TextStyle(
                              fontFamily: 'Times',
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )),
            ],
            pointers: <GaugePointer>[
              RangePointer(
                  value: inputVal ?? 0,
                  cornerStyle: CornerStyle.bothCurve,
                  enableAnimation: false,
                  sizeUnit: GaugeSizeUnit.factor,
                  // Sweep gradient not supported in web
                  color: color,
                  width: 0.15),
            ]),
      ],
    );
  }
}

Card _accelerometerStatusTile() {
  return new Card(
    color: SL.getIt<Moto>().isRecordingAccel ? Colors.green : Colors.red,
    child: new InkWell(
      onTap: () {},
      child: new Center(
        child: new Padding(
          padding: const EdgeInsets.all(4.0),
          child: new Icon(
            SL.getIt<Moto>().isRecordingAccel ? Icons.blur_on : Icons.blur_off,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

class _Example01Tile extends StatelessWidget {
  const _Example01Tile(this.backgroundColor, this.iconData);

  final Color backgroundColor;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: backgroundColor,
      child: new InkWell(
        onTap: () {},
        child: new Center(
          child: new Padding(
            padding: const EdgeInsets.all(4.0),
            child: new Icon(
              iconData,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextTile extends StatelessWidget {
  const _TextTile(this.text);

  final Text text;

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: Colors.grey[100],
      child: new InkWell(
        onTap: () {},
        child: new Center(
          child: new Padding(
            padding: const EdgeInsets.all(4.0),
            child: text,
          ),
        ),
      ),
    );
  }
}
