import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/print/escpos.dart';
import 'package:pos_cafe/core/print/printers.dart';
import 'package:pos_cafe/core/print/windows_printer.dart';

import '../fake_printer.dart';

void main() {
  test('a USB printer is saved by its Windows name; old saved settings stay network printers', () {
    const usb = PrinterConfig.windows('XP-80C', width: 32);
    expect(usb.label, 'USB « XP-80C »');
    final settings = PrinterSettings(receipt: usb, bar: const PrinterConfig(host: '192.168.1.50'));
    final back = PrinterSettings.decode(settings.encode());
    expect(back.receipt, usb);
    expect(back.receipt!.isWindows, isTrue);
    expect(back.bar!.isWindows, isFalse);

    // Settings saved before USB existed.
    final old = PrinterSettings.decode('{"receipt":{"host":"10.0.0.5","port":9100,"width":48},"autoReceipt":true}');
    expect((old.receipt!.isWindows, old.receipt!.label), (false, '10.0.0.5:9100'));
  });

  test('each printer goes its own way: network over TCP, USB through Windows', () async {
    final network = FakePrinter();
    final windows = FakePrinter();
    final auto = AutoPrinterTransport(network: network, windows: windows);
    final bytes =
        (EscPos()
              ..text('ok')
              ..cut())
            .bytes();
    await auto.send(const PrinterConfig(host: '192.168.1.50'), bytes);
    await auto.send(const PrinterConfig.windows('XP-80C'), bytes);
    expect(network.sent.single.$1.host, '192.168.1.50');
    expect(windows.sent.single.$1.windowsName, 'XP-80C');
  });

  group('real Windows print spooler (this PC)', () {
    test('lists the printers installed in Windows', () {
      final printers = installedWindowsPrinters();
      // ignore: avoid_print
      print('Imprimantes Windows : $printers');
      expect(printers, isA<List<String>>());
      expect(printers.toSet().length, printers.length);
    });

    test('a printer that is not installed gives a clear message (nothing is printed)', () async {
      await expectLater(
        const WindowsPrinterTransport().send(
          const PrinterConfig.windows('Kahwti imprimante absente 123'),
          Uint8List(4),
        ),
        throwsA(isA<PrintException>().having((e) => e.message, 'm', contains('introuvable sur ce PC'))),
      );
    });
  }, skip: !Platform.isWindows ? 'Windows only' : false);

  test('off Windows, a USB printer says so', () async {
    if (Platform.isWindows) return;
    await expectLater(
      const WindowsPrinterTransport().send(const PrinterConfig.windows('XP-80C'), Uint8List(1)),
      throwsA(isA<PrintException>()),
    );
    expect(installedWindowsPrinters(), isEmpty);
  });
}
