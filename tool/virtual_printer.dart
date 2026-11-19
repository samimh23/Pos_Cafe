// A fake thermal printer for development: listens like a real network printer
// (port 9100, ESC/POS) and shows each ticket it receives, as it would print.
//
//   dart run tool/virtual_printer.dart                 → one printer on port 9100 (80 mm)
//   dart run tool/virtual_printer.dart 9100 9101 9102  → caisse, bar, cuisine
//   dart run tool/virtual_printer.dart --58            → 58 mm paper (32 characters)
//
// In the POS (⋮ → Imprimantes), use this PC's address (127.0.0.1 on the same PC,
// or its Wi-Fi address from a tablet) and these ports.
// Every ticket is also saved in build/printed/.
import 'dart:io';
import 'dart:typed_data';

import 'package:pos_cafe/core/print/escpos.dart';

Future<void> main(List<String> args) async {
  final width = args.contains('--58') ? 32 : 48;
  final ports = args.map(int.tryParse).whereType<int>().toList();
  if (ports.isEmpty) ports.add(9100);
  final dir = Directory('build/printed')..createSync(recursive: true);

  for (final port in ports) {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    stdout.writeln('🖨️  Imprimante virtuelle prête sur le port $port (${width == 48 ? '80' : '58'} mm)');
    server.listen((socket) async {
      final bytes = BytesBuilder();
      await socket.forEach(bytes.add);
      for (final ticket in decodeEscPos(bytes.toBytes(), width: width)) {
        final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
        final file = File('${dir.path}/$stamp-port$port-${DateTime.now().microsecond}.txt');
        file.writeAsStringSync('${ticket.join('\n')}\n');
        final border = '─' * (width + 2);
        stdout
          ..writeln('\n[port $port · ${DateTime.now().toString().substring(11, 19)}]')
          ..writeln('┌$border┐');
        for (final l in ticket) {
          stdout.writeln('│ ${l.padRight(width)} │');
        }
        stdout
          ..writeln('└$border┘')
          ..writeln('→ ${file.path}');
      }
    });
  }
  stdout.writeln('Ctrl+C pour arrêter.');
}
