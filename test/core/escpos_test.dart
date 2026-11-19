import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/print/escpos.dart';

void main() {
  test('French accents use Windows-1252; typographic quotes are simplified', () {
    expect(EscPos.encode('Café à l’étage — 3€'), [
      ...'Caf'.codeUnits,
      0xE9,
      0x20,
      0xE0,
      ...' l\''.codeUnits,
      0xE9,
      ...'tage '.codeUnits,
      0x97,
      ...' 3'.codeUnits,
      0x80,
    ]);
    expect(EscPos.encode('漢'), [0x3F]); // unknown → ?
  });

  test('rows push the amount to the right edge; long names wrap', () {
    final p =
        EscPos(width: 32)
          ..row('2 x Express', '2.400')
          ..row('1 x Jus d’orange pressé avec glaçons', '4.500')
          ..text('TOTAL', at: EscPos.center)
          ..cut();
    final ticket = decodeEscPos(p.bytes(), width: 32).single;
    expect(ticket, [
      '2 x Express                2.400',
      '1 x Jus d\'orange pressé',
      'avec glaçons               4.500',
      '${' ' * 13}TOTAL', // (32 − 5) ÷ 2
    ]);
    expect(ticket.every((l) => l.length <= 32), isTrue);
  });

  test('a cut ends a ticket; two tickets in one send are split', () {
    final p =
        EscPos()
          ..text('BAR', at: EscPos.center)
          ..cut()
          ..text('CUISINE')
          ..cut();
    final tickets = decodeEscPos(p.bytes());
    expect(tickets.length, 2);
    expect(tickets[1], ['CUISINE']);
  });

  test('wrap never loses words and cuts words longer than a line', () {
    expect(EscPos.wrap('aaaa bbbb cc', 9), ['aaaa bbbb', 'cc']);
    expect(EscPos.wrap('abcdefghij', 4), ['abcd', 'efgh', 'ij']);
  });
}
