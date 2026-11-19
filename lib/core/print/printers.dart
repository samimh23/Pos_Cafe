import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A thermal printer: on the network ("192.168.1.50", port 9100) or a USB printer
/// installed in Windows ([windowsName]). 80 mm paper = 48 characters, 58 mm = 32.
class PrinterConfig {
  final String host;
  final int port;
  final int width;

  /// Set for a USB printer: its name in Windows ("XP-80C").
  final String? windowsName;

  const PrinterConfig({this.host = '', this.port = 9100, this.width = 48, this.windowsName});
  const PrinterConfig.windows(String name, {this.width = 48}) : host = '', port = 9100, windowsName = name;

  bool get isWindows => windowsName != null;

  String get label => isWindows ? 'USB « $windowsName »' : '$host:$port';

  Map<String, Object?> toJson() => {
    'host': host,
    'port': port,
    'width': width,
    if (windowsName != null) 'windowsName': windowsName,
  };
  factory PrinterConfig.fromJson(Map<String, dynamic> j) => PrinterConfig(
    host: (j['host'] as String?) ?? '',
    port: (j['port'] as int?) ?? 9100,
    width: (j['width'] as int?) ?? 48,
    windowsName: j['windowsName'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is PrinterConfig &&
      other.host == host &&
      other.port == port &&
      other.width == width &&
      other.windowsName == windowsName;
  @override
  int get hashCode => Object.hash(host, port, width, windowsName);
}

/// Which printer prints what, on this POS (set on the main POS: ⋮ → Imprimantes).
/// A café with one printer: just the receipt printer, it prints the bar/kitchen tickets too.
class PrinterSettings {
  static const kvKey = 'printers';

  final PrinterConfig? receipt, bar, kitchen;

  /// Print the customer receipt automatically when a ticket is fully paid.
  final bool autoReceipt;

  const PrinterSettings({this.receipt, this.bar, this.kitchen, this.autoReceipt = true});

  static const none = PrinterSettings();

  /// Bar orders → bar printer, else the receipt printer. Kitchen → kitchen, else bar, else receipt.
  PrinterConfig? forStation(String station) => switch (station) {
    'bar' => bar ?? receipt,
    'kitchen' => kitchen ?? bar ?? receipt,
    _ => null,
  };

  bool get hasAny => receipt != null || bar != null || kitchen != null;

  PrinterSettings copyWith({
    PrinterConfig? Function()? receipt,
    PrinterConfig? Function()? bar,
    PrinterConfig? Function()? kitchen,
    bool? autoReceipt,
  }) => PrinterSettings(
    receipt: receipt != null ? receipt() : this.receipt,
    bar: bar != null ? bar() : this.bar,
    kitchen: kitchen != null ? kitchen() : this.kitchen,
    autoReceipt: autoReceipt ?? this.autoReceipt,
  );

  String encode() => jsonEncode({
    'receipt': receipt?.toJson(),
    'bar': bar?.toJson(),
    'kitchen': kitchen?.toJson(),
    'autoReceipt': autoReceipt,
  });

  static PrinterSettings decode(String? s) {
    if (s == null) return none;
    final j = jsonDecode(s) as Map<String, dynamic>;
    PrinterConfig? p(String k) => j[k] == null ? null : PrinterConfig.fromJson((j[k] as Map).cast<String, dynamic>());
    return PrinterSettings(
      receipt: p('receipt'),
      bar: p('bar'),
      kitchen: p('kitchen'),
      autoReceipt: j['autoReceipt'] != false,
    );
  }
}

class PrintException implements Exception {
  final String message;
  const PrintException(this.message);
  @override
  String toString() => message;
}

/// Sends bytes to a printer. An interface so tests can capture what would print.
abstract interface class PrinterTransport {
  Future<void> send(PrinterConfig printer, Uint8List bytes);
}

/// Raw TCP on port 9100 — what every network thermal printer accepts.
class NetworkPrinterTransport implements PrinterTransport {
  const NetworkPrinterTransport();

  @override
  Future<void> send(PrinterConfig printer, Uint8List bytes) async {
    Socket? socket;
    try {
      socket = await Socket.connect(printer.host, printer.port, timeout: const Duration(seconds: 3));
      socket.add(bytes);
      await socket.flush();
    } on SocketException {
      throw PrintException('Imprimante injoignable (${printer.label}). Vérifiez qu’elle est allumée et sur le Wi-Fi.');
    } finally {
      await socket?.close();
    }
  }
}
