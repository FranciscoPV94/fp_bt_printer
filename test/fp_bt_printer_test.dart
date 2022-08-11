import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fp_bt_printer/fp_bt_printer.dart';

void main() {
  const MethodChannel channel = MethodChannel('fp_bt_printer');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  final printer = FpBtPrinter();

  test('getPlatformVersion', () async {
    expect(await printer.state, '42');
  });
}
