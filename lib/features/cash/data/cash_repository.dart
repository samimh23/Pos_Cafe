import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ids.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_event_types.dart';
import '../../order/data/order_repository.dart' show OrderException;

/// A cash movement as shown on screen and on the closing report.
class CashMovementView {
  final bool cashIn;
  final Money amount;
  final String reason;
  final String? staffName;
  final DateTime at;
  const CashMovementView({
    required this.cashIn,
    required this.amount,
    required this.reason,
    required this.staffName,
    required this.at,
  });

  Map<String, Object?> toJson() => {
    'type': cashIn ? 'in' : 'out',
    'amount': amount.millimes,
    'reason': reason,
    'staff': staffName,
    'at': at.millisecondsSinceEpoch,
  };

  factory CashMovementView.fromJson(Map<String, dynamic> j) => CashMovementView(
    cashIn: j['type'] == 'in',
    amount: Money(j['amount'] as int),
    reason: j['reason'] as String,
    staffName: j['staff'] as String?,
    at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
  );
}

/// Where a drawer stands right now (or at closing).
class CashSummary {
  final String sessionId;
  final DateTime openedAt;
  final String? openedBy;
  final Money openingFloat;
  final Money cashSales;
  final Money cardSales;
  final Money cashIn;
  final Money cashOut;
  final int ticketCount;

  /// Tickets still open in the café (the main POS can't close while some are).
  final int openTickets;
  final List<CashMovementView> movements;

  const CashSummary({
    required this.sessionId,
    required this.openedAt,
    required this.openedBy,
    required this.openingFloat,
    required this.cashSales,
    required this.cardSales,
    required this.cashIn,
    required this.cashOut,
    required this.ticketCount,
    required this.openTickets,
    required this.movements,
  });

  /// What should be in the drawer: float + cash sales + cash in − cash out.
  Money get expectedCash => openingFloat + cashSales + cashIn - cashOut;

  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'openedAt': openedAt.millisecondsSinceEpoch,
    'openedBy': openedBy,
    'openingFloat': openingFloat.millimes,
    'cashSales': cashSales.millimes,
    'cardSales': cardSales.millimes,
    'cashIn': cashIn.millimes,
    'cashOut': cashOut.millimes,
    'ticketCount': ticketCount,
    'openTickets': openTickets,
    'movements': [for (final m in movements) m.toJson()],
  };

  factory CashSummary.fromJson(Map<String, dynamic> j) => CashSummary(
    sessionId: j['sessionId'] as String,
    openedAt: DateTime.fromMillisecondsSinceEpoch(j['openedAt'] as int),
    openedBy: j['openedBy'] as String?,
    openingFloat: Money(j['openingFloat'] as int),
    cashSales: Money(j['cashSales'] as int),
    cardSales: Money(j['cardSales'] as int),
    cashIn: Money(j['cashIn'] as int),
    cashOut: Money(j['cashOut'] as int),
    ticketCount: j['ticketCount'] as int,
    openTickets: j['openTickets'] as int,
    movements: [
      for (final m in (j['movements'] as List? ?? const []))
        CashMovementView.fromJson((m as Map).cast<String, dynamic>()),
    ],
  );
}

/// The closing report ("Z"): the summary + what was counted.
class CashClosing {
  final CashSummary summary;
  final Money counted;
  final DateTime closedAt;
  final String? closedBy;
  final String? note;
  const CashClosing({
    required this.summary,
    required this.counted,
    required this.closedAt,
    required this.closedBy,
    required this.note,
  });

  /// counted − expected: negative = cash missing.
  Money get difference => counted - summary.expectedCash;

  Map<String, Object?> toJson() => {
    'summary': summary.toJson(),
    'counted': counted.millimes,
    'closedAt': closedAt.millisecondsSinceEpoch,
    'closedBy': closedBy,
    'note': note,
  };

  factory CashClosing.fromJson(Map<String, dynamic> j) => CashClosing(
    summary: CashSummary.fromJson((j['summary'] as Map).cast<String, dynamic>()),
    counted: Money(j['counted'] as int),
    closedAt: DateTime.fromMillisecondsSinceEpoch(j['closedAt'] as int),
    closedBy: j['closedBy'] as String?,
    note: j['note'] as String?,
  );
}

/// What the "Caisse" screen can do. On the main POS (or a POS working alone) it is
/// the local [CashRepository]; on a tablet allowed to take payments it goes to the main POS.
abstract interface class CashActions {
  Future<void> open(Money openingFloat);
  Future<void> move({required bool cashIn, required Money amount, required String reason});
  Future<CashSummary?> summary();
  Future<CashClosing> close({required Money counted, String? note});
}

/// Cash sessions of ONE drawer, on this POS's database. Every change also records
/// the sync event, in the same transaction.
class CashRepository implements CashActions {
  CashRepository(
    this._db,
    this._outbox, {
    required this.drawerId,
    String? Function()? staffId,
    DateTime Function()? clock,
    this.checkOpenTickets = true,
  }) : _staffId = staffId ?? (() => null),
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final OutboxRepository _outbox;

  /// Device id of the drawer.
  final String drawerId;
  final String? Function() _staffId;
  final DateTime Function() _now;

  /// The main POS refuses to close while tickets are open in the café; a tablet's drawer doesn't.
  final bool checkOpenTickets;

  /// Only these roles can take cash out or close the drawer.
  static const cashRoles = {'manager', 'cashier'};

  Stream<CashSessionRow?> watchOpen() => _openQuery(drawerId).watchSingleOrNull();

  @override
  Future<void> open(Money openingFloat) => _db.transaction(() async {
    if (openingFloat.isNegative) throw const OrderException('Le fond de caisse ne peut pas être négatif.');
    if (await _openQuery(drawerId).getSingleOrNull() != null) {
      throw const OrderException('La caisse est déjà ouverte.');
    }
    final id = newId();
    await _db
        .into(_db.cashSessions)
        .insert(
          CashSessionsCompanion.insert(
            id: id,
            drawerId: drawerId,
            openedAt: _now(),
            openedBy: Value(_staffId()),
            openingFloat: openingFloat.millimes,
          ),
        );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.cashSessionOpened,
      entityId: id,
      payload: {'drawerId': drawerId, 'openingFloat': openingFloat.millimes},
    );
  });

  @override
  Future<void> move({required bool cashIn, required Money amount, required String reason}) => _db.transaction(() async {
    await _requireCashRole('enregistrer une entrée ou une sortie d’argent');
    final session = await _requireOpen();
    if (amount <= Money.zero) throw const OrderException('Le montant doit être positif.');
    if (reason.trim().isEmpty) throw const OrderException('Indiquez le motif (ex. « Fournisseur pain »).');
    if (!cashIn) {
      final available = (await _summaryOf(session)).expectedCash;
      if (amount > available) throw OrderException('Pas assez d’espèces dans la caisse ($available).');
    }
    final id = newId();
    await _db
        .into(_db.cashMovements)
        .insert(
          CashMovementsCompanion.insert(
            id: id,
            sessionId: session.id,
            type: cashIn ? 'in' : 'out',
            amount: amount.millimes,
            reason: reason.trim(),
            staffId: Value(_staffId()),
            createdAt: _now(),
          ),
        );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.cashMoved,
      entityId: session.id,
      payload: {'movementId': id, 'type': cashIn ? 'in' : 'out', 'amount': amount.millimes, 'reason': reason.trim()},
    );
  });

  @override
  Future<CashSummary?> summary() async {
    final session = await _openQuery(drawerId).getSingleOrNull();
    return session == null ? null : _summaryOf(session);
  }

  @override
  Future<CashClosing> close({required Money counted, String? note}) => _db.transaction(() async {
    await _requireCashRole('clôturer la caisse');
    final session = await _requireOpen();
    if (counted.isNegative) throw const OrderException('Le montant compté ne peut pas être négatif.');
    final s = await _summaryOf(session);
    if (checkOpenTickets && s.openTickets > 0) {
      throw OrderException(
        'Encore ${s.openTickets} ticket${s.openTickets > 1 ? 's' : ''} ouvert${s.openTickets > 1 ? 's' : ''} : '
        'encaissez-les ou annulez-les avant de clôturer.',
      );
    }
    final now = _now();
    final cleanNote = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    final closing = CashClosing(
      summary: s,
      counted: counted,
      closedAt: now,
      closedBy: await _staffName(_staffId()),
      note: cleanNote,
    );
    await (_db.update(_db.cashSessions)..where((t) => t.id.equals(session.id))).write(
      CashSessionsCompanion(
        status: const Value('closed'),
        closedAt: Value(now),
        closedBy: Value(_staffId()),
        countedCash: Value(counted.millimes),
        expectedCash: Value(s.expectedCash.millimes),
        note: Value(cleanNote),
      ),
    );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.cashSessionClosed,
      entityId: session.id,
      payload: {
        'countedCash': counted.millimes,
        'expectedCash': s.expectedCash.millimes,
        'difference': closing.difference.millimes,
        'cashSales': s.cashSales.millimes,
        'cardSales': s.cardSales.millimes,
        'cashIn': s.cashIn.millimes,
        'cashOut': s.cashOut.millimes,
        'ticketCount': s.ticketCount,
        'note': cleanNote,
      },
    );
    return closing;
  });

  // ── Helpers ──────────────────────────────────────────────

  /// The open session of [drawerId] (also used by payments).
  SimpleSelectStatement<$CashSessionsTable, CashSessionRow> _openQuery(String drawerId) =>
      _db.select(_db.cashSessions)
        ..where((t) => t.drawerId.equals(drawerId) & t.status.equals('open'))
        ..limit(1);

  Future<CashSessionRow> _requireOpen() async {
    final s = await _openQuery(drawerId).getSingleOrNull();
    if (s == null) throw const OrderException('La caisse n’est pas ouverte.');
    return s;
  }

  Future<void> _requireCashRole(String what) async {
    final id = _staffId();
    final staff =
        id == null ? null : await (_db.select(_db.staffMembers)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (staff == null || !cashRoles.contains(staff.role)) {
      throw OrderException('Seul un gérant ou un caissier peut $what.');
    }
  }

  Future<String?> _staffName(String? id) async =>
      id == null ? null : (await (_db.select(_db.staffMembers)..where((s) => s.id.equals(id))).getSingleOrNull())?.name;

  Future<CashSummary> _summaryOf(CashSessionRow session) async {
    final totals =
        await _db
            .customSelect(
              '''
          SELECT
            COALESCE(SUM(CASE WHEN method = 'cash' THEN amount END), 0) AS cash,
            COALESCE(SUM(CASE WHEN method = 'card' THEN amount END), 0) AS card,
            (SELECT COUNT(*) FROM orders o WHERE o.status = 'paid' AND o.id IN
               (SELECT p2.order_id FROM payments p2 WHERE p2.drawer_id = ?1 AND p2.created_at >= ?2)) AS tickets,
            (SELECT COUNT(*) FROM orders o WHERE o.status = 'open') AS open_tickets
          FROM payments
          WHERE drawer_id = ?1 AND created_at >= ?2
          ''',
              variables: [Variable.withString(drawerId), Variable.withDateTime(session.openedAt)],
              readsFrom: {_db.payments, _db.orders},
            )
            .getSingle();
    final moves =
        await (_db.select(_db.cashMovements)
              ..where((m) => m.sessionId.equals(session.id))
              ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
            .get();
    final names = {for (final s in await _db.select(_db.staffMembers).get()) s.id: s.name};
    Money sum(String type) => moves.where((m) => m.type == type).fold(Money.zero, (acc, m) => acc + Money(m.amount));
    return CashSummary(
      sessionId: session.id,
      openedAt: session.openedAt,
      openedBy: names[session.openedBy],
      openingFloat: Money(session.openingFloat),
      cashSales: Money(totals.read<int>('cash')),
      cardSales: Money(totals.read<int>('card')),
      cashIn: sum('in'),
      cashOut: sum('out'),
      ticketCount: totals.read<int>('tickets'),
      openTickets: totals.read<int>('open_tickets'),
      movements: [
        for (final m in moves)
          CashMovementView(
            cashIn: m.type == 'in',
            amount: Money(m.amount),
            reason: m.reason,
            staffName: names[m.staffId],
            at: m.createdAt,
          ),
      ],
    );
  }
}
