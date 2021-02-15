import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRscan extends StatefulWidget {
  const QRscan({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRscanState();
}

class _QRscanState extends State<QRscan> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final GlobalKey qrKey2 = GlobalKey(debugLabel: 'QR2');

  // In order to get hot reload to work we need to pause the camera
  @override
  void reassemble() {
    super.reassemble();
    controller.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: qrKey2,
      body: Column(
        children: <Widget>[
          Expanded(flex: 9, child: _buildQrView(context)),
            FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                      ),
                        RaisedButton(
                          color: Colors.yellow,
                          onPressed: () {
                            controller.pauseCamera();
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ],
              ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      cameraFacing: CameraFacing.back,
      onQRViewCreated: _onQRViewCreated,
      formatsAllowed: [BarcodeFormat.qrcode],
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (scanData.format == BarcodeFormat.qrcode && scanData.code != null) {
        controller.pauseCamera();
        Navigator.pop(context, scanData.code);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

}
