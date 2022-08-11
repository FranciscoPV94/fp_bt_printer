import 'dart:typed_data';
import 'dart:io';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';

import 'package:fp_bt_printer/fp_bt_printer.dart';

void main() {
  print("holaa");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(DateTime.now().toString());

    return MaterialApp(home: HomeSecreen());
  }
}

class HomeSecreen extends StatefulWidget {
  const HomeSecreen({Key? key}) : super(key: key);

  @override
  State<HomeSecreen> createState() => _HomeSecreenState();
}

class _HomeSecreenState extends State<HomeSecreen> {
  List<PrinterDevice> devices = [];
  PrinterDevice? device;
  bool connected = false;

  FpBtPrinter printer = FpBtPrinter();

  Future<void> getDevices() async {
    final response = await printer.scanBondedDevices();
    setState(() {
      devices = response;
    });
  }

  Future<void> setConnet(PrinterDevice d) async {
    final response = await printer.checkConnection(d.address);
    print(response.message);
    setState(() {
      if (response.success) {
        device = d;
        connected = true;
        printer.disconnect();
      } else {
        connected = false;
        device = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of devices - Printers'),
      ),
      body: Column(
        children: [
          Container(
            child: Column(
              children: [
                TextButton(
                  child: Center(child: Text("Open Settings")),
                  onPressed: () => printer.openSettings(),
                )
              ],
            ),
          ),
          Divider(),
          Text("Search Paired Bluetooth"),
          TextButton(
            onPressed: () {
              this.getDevices();
            },
            child: Text("Search"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(5),
                height: 200,
                child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: devices.length > 0 ? devices.length : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.print_rounded),
                      onTap: () => setConnet(devices[index]),
                      title: Text(
                          '${devices[index].name} - ${devices[index].address}'),
                      subtitle: Text("Click to connect"),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              color: Colors.grey.shade300,
              child: Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.print_rounded,
                        color: connected ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  ListTile(
                    minVerticalPadding: 5,
                    dense: true,
                    title: connected
                        ? Center(child: Text(device!.name!))
                        : Center(child: Text("No device")),
                    subtitle: connected
                        ? Center(child: Text(device!.address))
                        : Center(child: Text("Select a device of the list")),
                  ),
                  TextButton(
                    onPressed: connected
                        ? () => this.printTicket(device!.address)
                        : null,
                    child: Text("PRINT"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printTicket(String address) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // //  Print image:
    final ByteData data = await rootBundle.load('assets/wz.png');
    final Uint8List bytesImg = data.buffer.asUint8List();
    var image = decodePng(bytesImg);

    // resize
    var thumbnail =
        copyResize(image!, interpolation: Interpolation.nearest, height: 200);

    bytes += generator.text("fp_bt_printer",
        styles: PosStyles(align: PosAlign.center, bold: true));

    bytes += generator.imageRaster(thumbnail, align: PosAlign.center);

    bytes += generator.reset();
    bytes += generator.setGlobalCodeTable('CP1252');
    bytes += generator.feed(1);
    bytes += generator.text("HELLO PRINTER by FPV",
        styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.qrcode("https://github.com/FranciscoPV94",
        size: QRSize.Size6);
    bytes += generator.feed(1);
    bytes += generator.feed(1);

    final resp = await printer.printData(bytes, address: address);

    print(resp.message);
    print("$address");
  }
}
