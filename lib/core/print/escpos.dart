import 'dart:typed_data';

/// Builds what thermal receipt printers understand (ESC/POS, the standard of
/// Epson, Xprinter, Rongta… printers). Pure Dart: no Flutter, no printer needed.
///
/// Text is sent in Windows-1252 (code page 16) so French accents print correctly.
class EscPos {
  EscPos({this.width = 48}) {
    _bytes
      ..add([0x1B, 0x40]) // ESC @  reset
      ..add([0x1B, 0x74, 16]); // ESC t 16  code page WPC1252
  }

  /// Characters per line: 48 on 80 mm paper, 32 on 58 mm.
  final int width;
  final _bytes = BytesBuilder();

  static const left = 0, center = 1, right = 2;

  EscPos align(int a) => _cmd([0x1B, 0x61, a]);
  EscPos bold([bool on = true]) => _cmd([0x1B, 0x45, on ? 1 : 0]);

  /// Double width and height (titles, table number on kitchen tickets).
  EscPos big([bool on = true]) => _cmd([0x1D, 0x21, on ? 0x11 : 0x00]);

  /// One line of text (long text wraps at [width], or [width] / 2 when big).
  EscPos text(String s, {int? at, bool isBig = false}) {
    final max = isBig ? width ~/ 2 : width;
    if (at != null) align(at);
    for (final line in wrap(s, max)) {
      _bytes
        ..add(encode(line))
        ..addByte(0x0A);
    }
    if (at != null) align(left);
    return this;
  }

  /// "2 x Express ............ 2.400": left text, right text pushed to the edge.
  EscPos row(String l, String r) {
    final room = width - r.length - 1;
    final lines = wrap(l, room < 8 ? width : room);
    for (var i = 0; i < lines.length; i++) {
      final isLast = i == lines.length - 1;
      final s = isLast ? lines[i].padRight(width - r.length) + r : lines[i];
      _bytes
        ..add(encode(s))
        ..addByte(0x0A);
    }
    return this;
  }

  EscPos separator([String c = '-']) => text(c * width);

  EscPos feed([int lines = 1]) => _cmd([0x1B, 0x64, lines]);

  /// Feeds the paper out and cuts (partial cut).
  EscPos cut() => feed(4)._cmd([0x1D, 0x56, 0x42, 0x00]);

  Uint8List bytes() => _bytes.toBytes();

  EscPos _cmd(List<int> b) {
    _bytes.add(b);
    return this;
  }

  // ── Text helpers ─────────────────────────────────────────

  /// Splits on words to fit [max] characters per line (a too-long word is cut).
  static List<String> wrap(String s, int max) {
    if (s.length <= max) return [s];
    final out = <String>[];
    var line = '';
    for (final word in s.split(' ')) {
      var w = word;
      while (w.length > max) {
        if (line.isNotEmpty) {
          out.add(line);
          line = '';
        }
        out.add(w.substring(0, max));
        w = w.substring(max);
      }
      if (line.isEmpty) {
        line = w;
      } else if (line.length + 1 + w.length <= max) {
        line = '$line $w';
      } else {
        out.add(line);
        line = w;
      }
    }
    if (line.isNotEmpty) out.add(line);
    return out;
  }

  /// Windows-1252: Latin-1 accents keep their code; a few typographic signs are
  /// mapped; anything else prints as '?'.
  static List<int> encode(String s) => [
    for (final rune in s.runes)
      if (rune < 0x80 || (rune >= 0xA0 && rune <= 0xFF)) rune else _cp1252[rune] ?? 0x3F,
  ];

  static const _cp1252 = {
    0x20AC: 0x80, // €
    0x2026: 0x85, // …
    0x2018: 0x27, // ‘ → '
    0x2019: 0x27, // ’ → '
    0x201C: 0x93, // “
    0x201D: 0x94, // ”
    0x2013: 0x96, // –
    0x2014: 0x97, // —
    0x0152: 0x8C, // Œ
    0x0153: 0x9C, // œ
    0x2212: 0x2D, // − → -
    0x00D7: 0xD7, // ×
  };
}

/// Turns printer bytes back into readable text — for the virtual printer and tests.
/// Each cut ends one ticket. Alignment is reproduced with spaces; big text is upper-cased.
List<List<String>> decodeEscPos(Uint8List bytes, {int width = 48}) {
  final tickets = <List<String>>[];
  var lines = <String>[];
  var line = StringBuffer();
  var align = 0;
  var big = false;

  void endLine() {
    var s = line.toString();
    if (big) s = s.toUpperCase();
    final pad = width - s.length;
    if (pad > 0 && align == 1) s = '${' ' * (pad ~/ 2)}$s';
    if (pad > 0 && align == 2) s = '${' ' * pad}$s';
    lines.add(s);
    line = StringBuffer();
  }

  var i = 0;
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == 0x1B && i + 1 < bytes.length) {
      final c = bytes[i + 1];
      switch (c) {
        case 0x40: // ESC @
          align = 0;
          big = false;
          i += 2;
        case 0x61: // ESC a n
          align = bytes[i + 2];
          i += 3;
        case 0x64: // ESC d n — blank lines
          for (var k = 0; k < bytes[i + 2]; k++) {
            lines.add('');
          }
          i += 3;
        default: // ESC E n, ESC t n…
          i += 3;
      }
    } else if (b == 0x1D && i + 1 < bytes.length) {
      if (bytes[i + 1] == 0x21) big = bytes[i + 2] != 0;
      if (bytes[i + 1] == 0x56) {
        // GS V 66 n — cut
        while (lines.isNotEmpty && lines.last.isEmpty) {
          lines.removeLast();
        }
        tickets.add(lines);
        lines = <String>[];
        i += 4;
        continue;
      }
      i += 3;
    } else if (b == 0x0A) {
      endLine();
      i++;
    } else {
      line.writeCharCode(_fromCp1252[b] ?? b);
      i++;
    }
  }
  if (line.isNotEmpty) endLine();
  if (lines.any((l) => l.isNotEmpty)) tickets.add(lines);
  return tickets;
}

const _fromCp1252 = {
  0x80: 0x20AC,
  0x85: 0x2026,
  0x93: 0x201C,
  0x94: 0x201D,
  0x96: 0x2013,
  0x97: 0x2014,
  0x8C: 0x0152,
  0x9C: 0x0153,
};
