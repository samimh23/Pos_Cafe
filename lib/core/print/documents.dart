import 'dart:typed_data';

import '../money/money.dart';
import '../money/vat.dart';
import 'business_info.dart';
import 'escpos.dart';

/// One item as printed.
class PrintLine {
  final int qty;
  final String name;
  final List<String> modifiers;

  /// Price × quantity, before discount.
  final Money total;

  /// "Offert (Geste commercial)" and its amount, when discounted.
  final String? discountText;
  final Money discount;
  const PrintLine({
    required this.qty,
    required this.name,
    this.modifiers = const [],
    required this.total,
    this.discountText,
    this.discount = Money.zero,
  });
}

class PrintPayment {
  /// cash | card
  final String method;
  final Money amount, tendered, change;
  const PrintPayment({required this.method, required this.amount, required this.tendered, required this.change});
}

String _date(DateTime d) => '${_pad2(d.day)}/${_pad2(d.month)}/${d.year} ${_pad2(d.hour)}:${_pad2(d.minute)}';
String _time(DateTime d) => '${_pad2(d.hour)}:${_pad2(d.minute)}';
String _pad2(int n) => n.toString().padLeft(2, '0');

void _header(EscPos p, BusinessInfo? b) {
  if (b == null || b.businessName.isEmpty) return;
  p
    ..bold()
    ..big()
    ..text(b.businessName, at: EscPos.center, isBig: true)
    ..big(false)
    ..bold(false);
  if (b.address != null) p.text(b.address!, at: EscPos.center);
  if (b.phone != null) p.text('Tél. ${b.phone}', at: EscPos.center);
  if (b.taxId != null) p.text('MF : ${b.taxId}', at: EscPos.center);
  p.separator();
}

void _lines(EscPos p, List<PrintLine> lines) {
  for (final l in lines) {
    p.row('${l.qty} x ${l.name}', l.total.toDecimalString());
    for (final m in l.modifiers) {
      p.text('   + $m');
    }
    if (l.discountText != null) p.row('   ${l.discountText}', (-l.discount).toDecimalString());
  }
}

void _discountTotal(EscPos p, List<PrintLine> lines) {
  final d = lines.fold(Money.zero, (sum, l) => sum + l.discount);
  if (!d.isZero) p.row('Remises & offerts', (-d).toDecimalString());
}

/// The customer receipt ("ticket de caisse"), printed when the ticket is fully paid.
Uint8List receiptDocument({
  required int width,
  required BusinessInfo? business,
  required String receiptNumber,
  required DateTime at,
  String? table,
  String? staff,
  required List<PrintLine> lines,
  required Money total,
  required List<VatSplit> vat,
  required List<PrintPayment> payments,
  String? loyaltyUrl,
}) {
  final p = EscPos(width: width);
  _header(p, business);
  p.row('Ticket $receiptNumber', _date(at));
  if (table != null) p.text('Table $table');
  if (staff != null) p.text('Servi par $staff');
  p.separator();
  _lines(p, lines);
  p.separator();
  _discountTotal(p, lines);
  p
    ..bold()
    ..big()
    ..text('TOTAL ${total.toDecimalString()} DT', at: EscPos.right, isBig: true)
    ..big(false)
    ..bold(false);
  for (final pay in payments) {
    if (pay.method == 'card') {
      p.row('Carte', pay.amount.toDecimalString());
    } else {
      p.row('Espèces', pay.amount.toDecimalString());
      if (!pay.change.isZero) {
        p
          ..row('  Reçu', pay.tendered.toDecimalString())
          ..row('  Rendu', pay.change.toDecimalString());
      }
    }
  }
  if (vat.isNotEmpty) {
    p.separator();
    for (final v in vat) {
      p.row('TVA ${v.label} (HT ${v.ht.toDecimalString()})', v.vat.toDecimalString());
    }
  }
  if (loyaltyUrl != null) {
    p
      ..separator()
      ..bold()
      ..text('Gagnez des points fidélité', at: EscPos.center)
      ..bold(false)
      ..text('Scannez ce code avec votre téléphone', at: EscPos.center)
      ..qr(loyaltyUrl);
  }
  p
    ..separator()
    ..text(business?.receiptFooter ?? 'Merci de votre visite !', at: EscPos.center)
    ..cut();
  return p.bytes();
}

/// "L'addition": what the table owes, before paying. Not a receipt.
Uint8List billDocument({
  required int width,
  required BusinessInfo? business,
  required DateTime at,
  String? table,
  String? staff,
  required List<PrintLine> lines,
  required Money total,
  required Money paid,
}) {
  final p = EscPos(width: width);
  _header(p, business);
  p
    ..bold()
    ..big()
    ..text('ADDITION', at: EscPos.center, isBig: true)
    ..big(false)
    ..bold(false)
    ..row(table == null ? 'Comptoir' : 'Table $table', _date(at));
  if (staff != null) p.text('Servi par $staff');
  p.separator();
  _lines(p, lines);
  p.separator();
  _discountTotal(p, lines);
  p
    ..bold()
    ..row('TOTAL', '${total.toDecimalString()} DT')
    ..bold(false);
  if (!paid.isZero) {
    p
      ..row('Déjà payé', paid.toDecimalString())
      ..bold()
      ..row('RESTE À PAYER', '${(total - paid).toDecimalString()} DT')
      ..bold(false);
  }
  p
    ..feed()
    ..text('Ceci n’est pas un ticket de caisse', at: EscPos.center)
    ..cut();
  return p.bytes();
}

/// Bar / kitchen ticket: what to prepare, for which table. Big and readable from a distance.
Uint8List stationDocument({
  required int width,
  required String station,
  required DateTime at,
  String? table,
  String? staff,
  required List<PrintLine> lines,
  String? cancelledBecause,
}) {
  final cancelled = cancelledBecause != null;
  final p =
      EscPos(width: width)
        ..bold()
        ..big()
        ..text(
          '${cancelled ? 'ANNULÉ ' : ''}${station == 'kitchen' ? 'CUISINE' : 'BAR'}',
          at: EscPos.center,
          isBig: true,
        )
        ..text(table == null ? 'Comptoir' : 'Table $table', at: EscPos.center, isBig: true)
        ..big(false)
        ..bold(false)
        ..text('${_time(at)}${staff == null ? '' : ' · $staff'}', at: EscPos.center)
        ..separator();
  for (final l in lines) {
    p
      ..bold()
      ..big()
      ..text('${cancelled ? '-' : ''}${l.qty} x ${l.name}', isBig: true)
      ..big(false)
      ..bold(false);
    for (final m in l.modifiers) {
      p.text('    + $m');
    }
  }
  if (cancelled) p.text('Motif : $cancelledBecause');
  p
    ..separator()
    ..cut();
  return p.bytes();
}

/// Refund slip: what was given back, for which receipt, why.
Uint8List refundDocument({
  required int width,
  required BusinessInfo? business,
  required String receiptNumber,
  required DateTime at,
  String? staff,
  String? approvedBy,
  required String reason,
  required List<PrintLine> lines,
  required List<PrintPayment> refunds,
}) {
  final p = EscPos(width: width);
  _header(p, business);
  p
    ..bold()
    ..big()
    ..text('REMBOURSEMENT', at: EscPos.center, isBig: true)
    ..big(false)
    ..bold(false)
    ..row('Ticket $receiptNumber', _date(at))
    ..text('Motif : $reason');
  if (staff != null) p.text('Par $staff${approvedBy == null ? '' : ', validé par $approvedBy'}');
  p.separator();
  _lines(p, lines);
  p.separator();
  for (final r in refunds) {
    p
      ..bold()
      ..row(r.method == 'card' ? 'Rendu par carte' : 'Rendu en espèces', r.amount.toDecimalString())
      ..bold(false);
  }
  p.cut();
  return p.bytes();
}

/// The closing report ("Z") of a cash drawer.
Uint8List cashReportDocument({
  required int width,
  required BusinessInfo? business,
  required String drawer,
  required DateTime openedAt,
  String? openedBy,
  required DateTime closedAt,
  String? closedBy,
  required Money openingFloat,
  required Money cashSales,
  required Money cashIn,
  required Money cashOut,
  required Money expected,
  required Money counted,
  required Money cardSales,
  required int tickets,
  Money discounts = Money.zero,
  Money refunds = Money.zero,
  String? note,
}) {
  final p = EscPos(width: width);
  _header(p, business);
  final gap = counted - expected;
  p
    ..bold()
    ..text('CLÔTURE DE CAISSE · $drawer', at: EscPos.center)
    ..bold(false)
    ..text('Ouverte ${_date(openedAt)}${openedBy == null ? '' : ' · $openedBy'}')
    ..text('Clôturée ${_date(closedAt)}${closedBy == null ? '' : ' · $closedBy'}')
    ..separator()
    ..row('Fond de caisse', openingFloat.toDecimalString())
    ..row('Ventes espèces', cashSales.toDecimalString())
    ..row('Entrées', cashIn.toDecimalString())
    ..row('Sorties', (-cashOut).toDecimalString())
    ..separator()
    ..row('Espèces attendues', expected.toDecimalString())
    ..row('Espèces comptées', counted.toDecimalString())
    ..bold()
    ..row(gap.isZero ? 'Écart : caisse juste' : 'Écart', gap.toDecimalString())
    ..bold(false)
    ..separator()
    ..row('Ventes carte (TPE)', cardSales.toDecimalString())
    ..row('Tickets encaissés', '$tickets')
    ..row('Remises & offerts', (-discounts).toDecimalString())
    ..row('Remboursements', (-refunds).toDecimalString());
  if (note != null) p.text('Commentaire : $note');
  p.cut();
  return p.bytes();
}

/// "Tester l'imprimante".
Uint8List testDocument({required int width, required String label}) {
  final p =
      EscPos(width: width)
        ..bold()
        ..text('Kahwti · test d’impression', at: EscPos.center)
        ..bold(false)
        ..text(label, at: EscPos.center)
        ..separator()
        ..text('Accents : é è ê à â ç ù ô î €')
        ..row('Aligné à gauche', 'à droite')
        ..separator()
        ..text('Si ce texte est lisible, l’imprimante est prête.', at: EscPos.center)
        ..cut();
  return p.bytes();
}
