import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io' show Platform;

import '../../../core/print/printers.dart';
import '../../../core/print/windows_printer.dart';
import '../print_providers.dart';

/// ⋮ → Imprimantes: the printers of this POS (the main POS in a café with tablets):
/// network (Wi-Fi / Ethernet) or, on Windows, USB.
class PrintersScreen extends ConsumerStatefulWidget {
  const PrintersScreen({super.key});

  @override
  ConsumerState<PrintersScreen> createState() => _PrintersScreenState();
}

class _PrinterFields {
  final host = TextEditingController();
  final port = TextEditingController(text: '9100');
  int width = 48;

  /// USB printer installed in Windows (instead of a network address).
  bool usb = false;
  String? windowsName;

  void load(PrinterConfig? p) {
    host.text = p?.host ?? '';
    port.text = '${p?.port ?? 9100}';
    width = p?.width ?? 48;
    usb = p?.isWindows ?? false;
    windowsName = p?.windowsName;
  }

  /// null = no printer for this use.
  PrinterConfig? read() {
    if (usb) return windowsName == null ? null : PrinterConfig.windows(windowsName!, width: width);
    final h = host.text.trim();
    if (h.isEmpty) return null;
    return PrinterConfig(host: h, port: int.tryParse(port.text.trim()) ?? 9100, width: width);
  }

  void dispose() {
    host.dispose();
    port.dispose();
  }
}

class _PrintersScreenState extends ConsumerState<PrintersScreen> {
  final _receipt = _PrinterFields(), _bar = _PrinterFields(), _kitchen = _PrinterFields();
  var _autoReceipt = true;
  var _loaded = false;

  @override
  void dispose() {
    _receipt.dispose();
    _bar.dispose();
    _kitchen.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = PrinterSettings(
      receipt: _receipt.read(),
      bar: _bar.read(),
      kitchen: _kitchen.read(),
      autoReceipt: _autoReceipt,
    );
    await ref.read(printServiceProvider).saveSettings(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imprimantes enregistrées ✓')));
    }
  }

  Future<void> _test(_PrinterFields f) async {
    final p = f.read();
    final messenger = ScaffoldMessenger.of(context);
    if (p == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            f.usb ? 'Choisissez d’abord l’imprimante USB.' : 'Saisissez d’abord l’adresse de l’imprimante.',
          ),
        ),
      );
      return;
    }
    try {
      await ref.read(printServiceProvider).printTest(p);
      messenger.showSnackBar(SnackBar(content: Text('Page de test envoyée à ${p.label} ✓')));
    } on PrintException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Printers installed in Windows (USB printers appear once their driver is installed).
  List<String> _installed = Platform.isWindows ? installedWindowsPrinters() : const [];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printerSettingsProvider).value;
    if (settings != null && !_loaded) {
      _loaded = true;
      _receipt.load(settings.receipt);
      _bar.load(settings.bar);
      _kitchen.load(settings.kitchen);
      _autoReceipt = settings.autoReceipt;
    }

    Widget section(String title, String help, _PrinterFields f, String key) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(help, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            if (Platform.isWindows) ...[
              SegmentedButton<bool>(
                key: Key('printer-$key-mode'),
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.wifi), label: Text('Réseau')),
                  ButtonSegment(value: true, icon: Icon(Icons.usb), label: Text('USB')),
                ],
                selected: {f.usb},
                onSelectionChanged: (s) => setState(() => f.usb = s.first),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (f.usb) ...[
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      key: Key('printer-$key-usb'),
                      value: _installed.contains(f.windowsName) ? f.windowsName : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Imprimante USB (Windows)',
                        border: OutlineInputBorder(),
                      ),
                      hint: Text(_installed.isEmpty ? 'Aucune imprimante installée' : 'Choisir…'),
                      items: [for (final n in _installed) DropdownMenuItem(value: n, child: Text(n))],
                      onChanged: (v) => setState(() => f.windowsName = v),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualiser la liste',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => _installed = installedWindowsPrinters()),
                  ),
                ] else ...[
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: Key('printer-$key-host'),
                      controller: f.host,
                      decoration: const InputDecoration(
                        labelText: 'Adresse IP',
                        hintText: '192.168.1.50',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      key: Key('printer-$key-port'),
                      controller: f.port,
                      decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 48, label: Text('80 mm')),
                    ButtonSegment(value: 32, label: Text('58 mm')),
                  ],
                  selected: {f.width},
                  onSelectionChanged: (s) => setState(() => f.width = s.first),
                ),
                const SizedBox(width: 8),
                OutlinedButton(key: Key('printer-$key-test'), onPressed: () => _test(f), child: const Text('Tester')),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Imprimantes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Imprimantes thermiques réseau (Wi-Fi ou câble Ethernet, port 9100)'
                '${Platform.isWindows ? ' ou USB : installez d’abord le pilote de l’imprimante dans Windows' : ''}. '
                'Une seule imprimante suffit : laissez Bar et Cuisine vides, elle imprimera aussi leurs bons.',
              ),
              const SizedBox(height: 16),
              section('Tickets clients et addition', 'Au comptoir.', _receipt, 'receipt'),
              section('Bar', 'Bons des boissons. Vide = imprimante des tickets.', _bar, 'bar'),
              section('Cuisine', 'Bons des plats. Vide = imprimante du bar.', _kitchen, 'kitchen'),
              SwitchListTile(
                key: const Key('printer-auto-receipt'),
                title: const Text('Imprimer le ticket client automatiquement après paiement'),
                value: _autoReceipt,
                onChanged: (v) => setState(() => _autoReceipt = v),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const Key('printers-save'),
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
