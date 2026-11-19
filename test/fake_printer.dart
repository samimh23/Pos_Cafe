import 'dart:typed_data';

import 'package:pos_cafe/core/print/escpos.dart';
import 'package:pos_cafe/core/print/printers.dart';

/// Records what would print, per printer; can be told to fail for one printer.
class FakePrinter implements PrinterTransport {
  final sent = <(PrinterConfig, Uint8List)>[];
  final offline = <String>{};

  @override
  Future<void> send(PrinterConfig printer, Uint8List bytes) async {
    if (offline.contains(printer.label)) {
      throw PrintException('Imprimante injoignable (${printer.label}).');
    }
    sent.add((printer, bytes));
  }

  /// Every printed ticket as text lines, in order.
  List<List<String>> get tickets => [for (final (p, b) in sent) ...decodeEscPos(b, width: p.width)];

  /// One ticket's text in one string (for `contains` checks).
  List<String> get texts => [for (final t in tickets) t.join('\n')];

  List<String> textsFor(String label) => [
    for (final (p, b) in sent)
      if (p.label == label) ...decodeEscPos(b, width: p.width).map((t) => t.join('\n')),
  ];
}
