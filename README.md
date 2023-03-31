# fp_bt_printer


This library allows printing receipts on bluetooth thermal printers (android only).
Support 58mm and 80mm printer.

It allows to print QR, BarCode, Images RasterImages with the [esc_pos_utils](https://pub.dev/packages/esc_pos_utils) package.


#### List bounded devices
Get list of bluetooth devices, it supports any version of bluetooth, not just BLE.

```dart
    List<PrinterDevice> devices = [];
    FpBtPrinter printer = FpBtPrinter();

    Future<void> getDevices() async {
        final response = await printer.scanBondedDevices();
        setState(() {
        devices = response;
        });
    }
```

#### Check device connected
You can check that the connection with the device is correct.

```dart
    Future<void> setConnet(PrinterDevice d) async {
        final response = await printer.checkConnection(d.address);
        print(response.message);
    }
```

#### Print data
This method recibe address of the printer and List<int> of the data;

```dart
    FpBtPrinter printer = FpBtPrinter();
    final resp = await printer.printData(bytes, address: address);
    if (resp.success) {
     //print ok
    } else {
    print(resp.message); //print error
    }
```

#### Ticket with Styles usin :
```dart
List<int> getTicket() {
  final List<int> bytes = [];
  // Using default profile
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
  return bytes;
}
```

## Tested and working with following Bluetooth Thermal Printers:

**Xprinter Portable Thermal Printer**
  
  Model: Bixolon SPP-R310

## Evidence

<img src="https://raw.githubusercontent.com/FranciscoPV94/fp_bt_printer/main/photo_recipe.jpg" alt="test receipt" width="400"/>
    
## Support me

If you think that this project has helped you with your developments, you can support this project, any support is much appreciated.
[![Paypal](https://raw.githubusercontent.com/arthas1888/flutter_pos_printer_platform/main/btn-sm-paypal-payment.png)](https://www.paypal.com/donate/?hosted_button_id=W9WAAB2RG5SVU)

