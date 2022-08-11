library fp_bt_printer;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

part './src/models/response_model.dart';
part './src/models/printer_model.dart';

class FpBtPrinter {
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? _connection;
  Timer? _discoverableTimeoutTimer;

  //connection
  bool get isConnected => (_connection?.isConnected ?? false);

  //Constructor
  FpBtPrinter() {
    //get state
    FlutterBluetoothSerial.instance.state.then((state) {
      bluetoothState = state;
    });
    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      bluetoothState = state;
      // Discoverable mode is disabled when Bluetooth gets disabled
      _discoverableTimeoutTimer = null;
    });
  }

  ///Describes is the Bluetooth interface enabled on host device.
  Future<BluetoothState> get state async =>
      FlutterBluetoothSerial.instance.state;

  Future<List<PrinterDevice>> scanBondedDevices() async {
    final bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    return bondedDevices
        .map((device) =>
            PrinterDevice(address: device.address, name: device.name))
        .toList();
  }

  ///test to connection for printer is ok
  Future<PrinterResponseModel<BluetoothConnection>> checkConnection(
      String address) async {
    final conn = await BluetoothConnection.toAddress(address);

    return PrinterResponseModel(
        success: conn.isConnected,
        message: conn.isConnected
            ? "connected with => $address"
            : "not connected => $address");
  }

  ///Opens the Bluetooth platform system settings.
  Future<void> openSettings() async {
    return FlutterBluetoothSerial.instance.openSettings();
  }

  ///Tries to enable Bluetooth interface (if disabled).
  Future<bool?> enableBluetooth() async {
    return FlutterBluetoothSerial.instance.requestEnable();
  }

  ///Tries to disable Bluetooth interface (if enabled).
  Future<bool?> disableBluetooth() async {
    return FlutterBluetoothSerial.instance.requestDisable();
  }

  ///Send data  in  List<int> for print, the address is required
  Future<PrinterResponseModel> printData(
    List<int> bytes, {
    required String address,
    int chunkSizeBytes = 50,
    int queueSleepTimeMs = 50,
  }) async {
    disconnect();
    if (bluetoothState.isEnabled) {
      print('address is => $address');
      try {
        final respuesta = await BluetoothConnection.toAddress(address);

        if (respuesta.isConnected) {
          _connection = respuesta;
          //apply chunks for bytelist
          final len = bytes.length;
          List<List<int>> chunks = [];
          for (var i = 0; i < len; i += chunkSizeBytes) {
            var end = (i + chunkSizeBytes < len) ? i + chunkSizeBytes : len;
            chunks.add(bytes.sublist(i, end));
          }

          for (var i = 0; i < chunks.length; i += 1) {
            print('$i  - ${chunks.length}');
            _connection!.output.add(Uint8List.fromList(chunks[i]));
            await _connection!.output.allSent;
            sleep(Duration(milliseconds: queueSleepTimeMs));
          }

          await Future.delayed(const Duration(seconds: 5), () {
            disconnect();
          });

          print("okayyy");

          return PrinterResponseModel(
              success: true, message: "The data was printed");
        } else {
          disconnect();
          return PrinterResponseModel(
              success: false, message: 'Could not connect to the device');
        }
      } on PlatformException catch (err) {
        print(err.details);
        print(err.message);
        disconnect();
        return PrinterResponseModel(
            success: false, message: 'An error has ocurred, code ${err.code}');
        // Handle err
      } catch (er) {
        print(er);
        disconnect();
        return PrinterResponseModel(
            success: false, message: 'No se pudo conectar, ocurrio un error');
      }
    } else {
      return PrinterResponseModel(
          success: false, message: 'Bluetooth is disabled');
    }
  }

  ///Disconnect all and set null the bluetooth connection
  void disconnect() {
    if (isConnected) {
      _connection?.dispose();
      _connection = null;
    }
    print('closed connection.');
  }

  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    if (isConnected) {
      _connection!.dispose();
      _connection = null;
    }
  }
}
