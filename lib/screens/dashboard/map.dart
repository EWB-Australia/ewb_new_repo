import 'package:moto_monitor/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import '../../models/moto.dart';
import '../../utils/service_locator.dart' as SL;
import 'package:flutter_map/plugin_api.dart';

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> with AutomaticKeepAliveClientMixin<Map> {
  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  Widget build(BuildContext context) {
    var moto = SL.getIt<Moto>();
    var settings = SL.getIt<Settings>();

    return Scaffold(
      appBar: new AppBar(
        leading: Icon(Icons.map),
        title: new Text('Map'),
      ),
      body: Column(
        children: [
          settings.showMap? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RaisedButton(
                color: Colors.yellow,
                child: Text("Clear markers"),
                onPressed: () {
                  moto.markers.clear();
                },
              ),
            ],
          ):SizedBox(height: 25,),
          Expanded(
            child: settings.showMap
                ? FlutterMap(
                    options: MapOptions(
                      center: moto.location ?? LatLng(51.5, -0.09),
                      zoom: 16.0,
                    ),
                    layers: [
                      TileLayerOptions(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                        maxZoom: 20,
                        maxNativeZoom: 18,
                        // For example purposes. It is recommended to use
                        // TileProvider with a caching and retry strategy, like
                        // NetworkTileProvider or CachedNetworkTileProvider
                        //tileProvider: CachedNetworkTileProvider(),
                      ),
                      CircleLayerOptions(circles: moto.markers)
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        const ListTile(
                          leading: Icon(Icons.warning_amber_outlined),
                          title: Text('Map is disabled.'),
                          subtitle:
                              Text('You can enable it in the settings tab.'),
                        ),
                      ]),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
