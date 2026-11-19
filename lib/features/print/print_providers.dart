import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lan/hub_client.dart';
import '../../core/lan/lan_providers.dart';
import '../../core/print/printers.dart';
import '../../core/print/windows_printer.dart';
import '../../core/providers.dart';
import '../staff_login/view_model/staff_session.dart';
import 'print_service.dart';

/// How bytes reach printers (network or Windows USB). Tests replace it to capture what would print.
final printerTransportProvider = Provider<PrinterTransport>((ref) => const AutoPrinterTransport());

/// Prints on THIS POS's printers.
final printServiceProvider = Provider<PrintService>(
  (ref) => PrintService(
    ref.watch(databaseProvider),
    ref.watch(outboxRepositoryProvider),
    transport: ref.watch(printerTransportProvider),
    staffId: () => ref.read(staffSessionProvider)?.id,
  ),
);

/// Where the order screen's printing goes: here, or the main POS (tablets).
final printActionsProvider = Provider<PrintActions>((ref) {
  final client = ref.watch(hubClientProvider);
  if (client != null) return HubPrintActions(client, staffId: () => ref.read(staffSessionProvider)?.id);
  return ref.watch(printServiceProvider);
});

/// This POS's printers (⋮ → Imprimantes), live.
final printerSettingsProvider = StreamProvider<PrinterSettings>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.kvEntries)..where(
    (k) => k.key.equals(PrinterSettings.kvKey),
  )).watchSingleOrNull().map((r) => PrinterSettings.decode(r?.value));
});

/// Show print buttons? Tablets: yes (the main POS has the printers). Others: if a printer is set.
final canPrintProvider = Provider<bool>((ref) {
  if (ref.watch(posModeProvider) == PosMode.tablet) return true;
  return ref.watch(printerSettingsProvider).value?.hasAny ?? false;
});
