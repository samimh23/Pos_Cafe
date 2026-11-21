import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/loyalty/receipt_code.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/print/business_info.dart';
import 'package:pos_cafe/core/print/escpos.dart';
import 'package:pos_cafe/core/print/printers.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';
import 'package:pos_cafe/features/print/print_service.dart';

import '../core/sync_engine_test.dart' show identity;
import '../fake_printer.dart';
import '../fakes.dart';
import '../order_helpers.dart';
import 'order_repository_test.dart' show product;

/// Fixed key → fixed code. The backend test (test/loyalty.test.ts) checks this exact
/// code with this public key, so both sides agree on the format.
final seed = List.filled(32, 7);
const vectorPublicKey = '6kpsY-KcUgq-9VB7Ey7F-ZVHdq6-vnuSQh7qaRRG0iw';
const vectorCode =
    'eyJvIjoiMDE5YTAwMDAtMDAwMC03MDAwLTgwMDAtMDAwMDAwMDAwMDAxIiwiZCI6IjAxOWEwMDAwLTAwMDAtNzAwMC04MDAwLTAwMDAwMDAwMDBkMSIsIm4iOiJUMS0wMDAwNDIiLCJ0IjoxMjUwMCwiYXQiOjE3NjM2NDcyMDB9.o1MNkjIJaP8kUpv4BRmuw_18wpIKDrA6FaEvnZYv3C_juLAI7cgk39GuM6qu2nWOCWVLkR-rqXbmERrOqaYaDg';

void main() {
  Future<MemorySecretStore> keyStore() async {
    final s = MemorySecretStore();
    await s.write(SecretKeys.devicePrivateKey, base64Url.encode(seed).replaceAll('=', ''));
    return s;
  }

  test('the receipt code is the order, signed with the POS key (same vector as the backend)', () async {
    final signer = ReceiptSigner(await keyStore(), () => '019a0000-0000-7000-8000-0000000000d1');
    final code = await signer.code(
      orderId: '019a0000-0000-7000-8000-000000000001',
      receiptNumber: 'T1-000042',
      total: const Money(12500),
      at: DateTime.utc(2025, 11, 20, 14),
    );
    final [payload, sig] = code!.split('.');
    expect(jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))), {
      'o': '019a0000-0000-7000-8000-000000000001',
      'd': '019a0000-0000-7000-8000-0000000000d1',
      'n': 'T1-000042',
      't': 12500,
      'at': 1763647200,
    });

    final pub = await (await Ed25519().newKeyPairFromSeed(seed)).extractPublicKey();
    expect(base64Url.encode(pub.bytes).replaceAll('=', ''), vectorPublicKey);
    final ok = await Ed25519().verify(
      utf8.encode(payload),
      signature: Signature(base64Url.decode(base64Url.normalize(sig)), publicKey: pub),
    );
    expect(ok, isTrue);
    expect(code, vectorCode);
    expect(ReceiptSigner.url(code), startsWith('$webUrl/r/eyJ'));
  });

  test('no key (not paired) → no code', () async {
    final signer = ReceiptSigner(MemorySecretStore(), () => 'dev-1');
    expect(
      await signer.code(orderId: 'o', receiptNumber: 'T1-1', total: const Money(1000), at: DateTime.now()),
      isNull,
    );
  });

  test('EscPos.qr: the printer draws the code; the virtual printer shows its content', () {
    final bytes =
        (EscPos()
              ..text('avant')
              ..qr('https://kahwti.tn/r/abc.def')
              ..text('après'))
            .bytes();
    final t = decodeEscPos(bytes).single.map((l) => l.trim());
    expect(t, ['avant', '[QR] https://kahwti.tn/r/abc.def', '', 'après']);
  });

  group('receipt', () {
    late AppDatabase db;
    late OutboxRepository outbox;
    late OrderRepository orders;
    late FakePrinter printer;
    late PrintService print;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      outbox = OutboxRepository(db);
      await SyncEngine(db, FakePosApi(), outbox, identity).syncNow();
      orders = OrderRepository(db, outbox);
      printer = FakePrinter();
      print = PrintService(
        db,
        outbox,
        transport: printer,
        loyalty: ReceiptSigner(await keyStore(), () => identity.deviceId),
      );
      await print.saveSettings(const PrinterSettings(receipt: PrinterConfig(host: '192.168.1.50')));
      await openTestDrawer(db);
    });
    tearDown(() => db.close());

    Future<void> loyalty(bool on) async {
      final b = jsonDecode((await db.getKv(BusinessInfo.kvKey))!) as Map<String, dynamic>;
      await db.setKv(BusinessInfo.kvKey, jsonEncode({...b, 'loyaltyEnabled': on}));
    }

    Future<String> paid() async {
      await orders.addProduct(product('p1', 'Express', 1200));
      final id = (await orders.watchOpenOrder().first)!.id;
      await orders.pay(id, const PaymentRequest.card(amount: Money(1200)), deviceCode: 'T1', drawerId: testDrawer);
      return id;
    }

    test('loyalty on → the receipt carries the signed QR', () async {
      await loyalty(true);
      final id = await paid();
      await print.printReceipt(id);
      final t = printer.tickets.single;
      expect(t.join('\n'), contains('Gagnez des points fidélité'));
      final qr = t.singleWhere((l) => l.startsWith('[QR] '));
      final url = (await print.loyaltyUrl(id))!;
      expect(qr, '[QR] $url');
      final code = url.substring('$webUrl/r/'.length);
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(code.split('.').first))));
      expect(payload, containsPair('o', id));
      expect(payload, containsPair('t', 1200));
      expect(payload, containsPair('n', 'T1-000001'));
      expect(payload, containsPair('d', identity.deviceId));
    });

    test('loyalty off → no QR; refunded ticket → no QR', () async {
      await loyalty(false);
      final id = await paid();
      await print.printReceipt(id);
      expect(printer.texts.single, isNot(contains('[QR]')));
      expect(await print.loyaltyUrl(id), isNull);

      await loyalty(true);
      await db
          .into(db.staffMembers)
          .insertOnConflictUpdate(
            StaffMembersCompanion.insert(id: 's-boss', name: 'Sonia', role: 'manager', pinHash: 'x'),
          );
      await orders.refund(id, approval: const Approval(approvedBy: 's-boss', reason: 'quality'), drawerId: testDrawer);
      expect(await print.loyaltyUrl(id), isNull);
    });
  });
}
