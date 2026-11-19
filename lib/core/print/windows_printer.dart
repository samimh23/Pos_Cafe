import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'printers.dart';

/// Printers installed in Windows. A USB receipt printer appears here once its
/// driver is installed (the maker's driver, or "Generic / Text Only").
List<String> installedWindowsPrinters() {
  if (!Platform.isWindows) return const [];
  return using((arena) {
    const flags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;
    final needed = arena<Uint32>();
    final count = arena<Uint32>();
    EnumPrinters(flags, nullptr, 4, nullptr, 0, needed, count); // asks for the size
    if (needed.value == 0) return const <String>[];
    final buffer = arena<Uint8>(needed.value);
    if (EnumPrinters(flags, nullptr, 4, buffer, needed.value, needed, count) == 0) return const <String>[];
    final infos = buffer.cast<PRINTER_INFO_4>();
    return [for (var i = 0; i < count.value; i++) infos[i].pPrinterName.toDartString()];
  });
}

/// Prints on an installed Windows printer in RAW mode: the printer receives the
/// ESC/POS bytes untouched, exactly as over the network (no driver layout).
class WindowsPrinterTransport implements PrinterTransport {
  const WindowsPrinterTransport();

  @override
  Future<void> send(PrinterConfig printer, Uint8List bytes) async {
    final name = printer.windowsName;
    if (!Platform.isWindows || name == null) {
      throw const PrintException('Imprimante USB : seulement sur une caisse Windows.');
    }
    using((arena) {
      final handle = arena<IntPtr>();
      if (OpenPrinter(name.toNativeUtf16(allocator: arena), handle, nullptr) == 0) {
        throw PrintException('Imprimante « $name » introuvable sur ce PC. Vérifiez le câble USB et le pilote.');
      }
      final h = handle.value;
      try {
        final doc =
            arena<DOC_INFO_1>()
              ..ref.pDocName = 'Kahwti'.toNativeUtf16(allocator: arena)
              ..ref.pOutputFile = nullptr
              ..ref.pDatatype = 'RAW'.toNativeUtf16(allocator: arena);
        if (StartDocPrinter(h, 1, doc) == 0) {
          throw PrintException('« $name » refuse l’impression (pilote ou file d’attente Windows).');
        }
        try {
          StartPagePrinter(h);
          final data = arena<Uint8>(bytes.length);
          data.asTypedList(bytes.length).setAll(0, bytes);
          final written = arena<Uint32>();
          final ok = WritePrinter(h, data, bytes.length, written);
          EndPagePrinter(h);
          if (ok == 0 || written.value != bytes.length) {
            throw PrintException('Impression incomplète sur « $name ».');
          }
        } finally {
          EndDocPrinter(h);
        }
      } finally {
        ClosePrinter(h);
      }
    });
  }
}

/// Network printers over TCP, USB printers through Windows — chosen per printer.
class AutoPrinterTransport implements PrinterTransport {
  const AutoPrinterTransport({
    this.network = const NetworkPrinterTransport(),
    this.windows = const WindowsPrinterTransport(),
  });
  final PrinterTransport network, windows;

  @override
  Future<void> send(PrinterConfig printer, Uint8List bytes) =>
      printer.isWindows ? windows.send(printer, bytes) : network.send(printer, bytes);
}
