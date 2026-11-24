import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/data/transfer_local_store_impl.dart';
import 'package:test_ebanking/features/transfer/domain/entities/account_statement.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

void main() {
  late TransferDatabase db;
  late TransferLocalStoreImpl store;

  setUp(() {
    // Base en mémoire, non chiffrée : rapide et isolée pour chaque test.
    db = TransferDatabase(NativeDatabase.memory());
    store = TransferLocalStoreImpl(db);
  });

  tearDown(() => db.close());

  Transfer transfer(
    String key,
    TransferStatus status, {
    String? serverId,
    int minute = 0,
  }) => Transfer(
    idempotencyKey: key,
    serverId: serverId,
    amount: 25000,
    currency: 'XOF',
    recipientName: 'Awa Kone',
    recipientPhone: '0701020304',
    status: status,
    createdAt: DateTime(2026, 11, 23, 10, minute),
    updatedAt: DateTime(2026, 11, 23, 10, minute),
  );

  List<Object?> fieldsOf(Transfer t) => [
    t.idempotencyKey,
    t.serverId,
    t.amount,
    t.currency,
    t.recipientName,
    t.recipientPhone,
    t.status,
    t.createdAt,
    t.updatedAt,
  ];

  List<String> keysOf(TransferHistory history) =>
      history.transfers.map((t) => t.idempotencyKey).toList();

  test('save puis findByKey restitue tous les champs', () async {
    final original = transfer('k1', TransferStatus.submitted, serverId: 'tr_1');

    await store.save(original);

    expect(fieldsOf((await store.findByKey('k1'))!), fieldsOf(original));
    expect(await store.findByKey('inconnue'), isNull);
  });

  test('save avec une clé existante remplace la ligne, sans doublon', () async {
    await store.save(transfer('k1', TransferStatus.pendingSubmission));
    await store.save(
      transfer('k1', TransferStatus.submitted, serverId: 'tr_1'),
    );

    expect(await db.select(db.transfers).get(), hasLength(1));
    final saved = (await store.findByKey('k1'))!;
    expect(saved.status, TransferStatus.submitted);
    expect(saved.serverId, 'tr_1');
  });

  test('clear efface tous les transferts, la date de synchro et le solde '
      '(déconnexion)', () async {
    await store.save(transfer('k1', TransferStatus.paid));
    await store.saveSyncedHistory(
      const AccountStatement(transfers: [], balance: 950000),
      DateTime(2026, 11, 23, 12),
    );

    await store.clear();

    final history = await store.watchHistory().first;
    expect(history.transfers, isEmpty);
    expect(history.lastSyncedAt, isNull);
    expect(history.balance, isNull);
  });

  test('findNeedingReconciliation : statuts incertains seulement, du plus '
      'ancien au plus récent', () async {
    await store.save(
      transfer('recent', TransferStatus.unknownOutcome, minute: 5),
    );
    await store.save(transfer('paye', TransferStatus.paid, minute: 1));
    await store.save(transfer('ancien', TransferStatus.pendingSubmission));

    final pending = await store.findNeedingReconciliation();

    expect(pending.map((t) => t.idempotencyKey), ['ancien', 'recent']);
  });

  test('saveSyncedHistory : enregistre la date et le solde, et garde les '
      'transferts encore inconnus du serveur', () async {
    await store.save(transfer('local', TransferStatus.pendingSubmission));
    final syncedAt = DateTime(2026, 11, 23, 12);

    await store.saveSyncedHistory(
      AccountStatement(
        transfers: [
          transfer('k1', TransferStatus.paid, serverId: 'tr_1', minute: 1),
        ],
        balance: 975000,
      ),
      syncedAt,
    );

    final history = await store.watchHistory().first;
    expect(keysOf(history), ['k1', 'local']); // du plus récent au plus ancien
    expect(history.lastSyncedAt, syncedAt);
    expect(history.balance, 975000);
  });

  test('migration 1 → 2 : une base déjà installée garde ses transferts et sa '
      'date ; le solde arrive à la synchro suivante', () async {
    final syncedAt = DateTime(2026, 11, 23, 12);
    final seconds = syncedAt.millisecondsSinceEpoch ~/ 1000;
    final v1 = TransferDatabase(
      NativeDatabase.memory(
        // Base telle qu'elle était en version 1, avant que Drift l'ouvre.
        setup: (raw) {
          raw.execute(
            'CREATE TABLE transfers (idempotency_key TEXT NOT NULL, '
            'server_id TEXT NULL, amount INTEGER NOT NULL, '
            'currency TEXT NOT NULL, recipient_name TEXT NOT NULL, '
            'recipient_phone TEXT NOT NULL, status TEXT NOT NULL, '
            'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
            'PRIMARY KEY (idempotency_key))',
          );
          raw.execute(
            'CREATE TABLE sync_state (id INTEGER NOT NULL, '
            'last_synced_at INTEGER NOT NULL, PRIMARY KEY (id))',
          );
          raw.execute(
            "INSERT INTO transfers VALUES ('k1', 'tr_1', 25000, 'XOF', "
            "'Awa Kone', '0701020304', 'paid', $seconds, $seconds)",
          );
          raw.execute('INSERT INTO sync_state VALUES (1, $seconds)');
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(v1.close);
    final migrated = TransferLocalStoreImpl(v1);

    final before = await migrated.watchHistory().first;
    expect(keysOf(before), ['k1']);
    expect(before.lastSyncedAt, syncedAt);
    expect(before.balance, isNull);

    await migrated.saveSyncedHistory(
      const AccountStatement(transfers: [], balance: 975000),
      syncedAt,
    );
    expect((await migrated.watchHistory().first).balance, 975000);
  });

  test('watchHistory réémet à chaque écriture, y compris une synchro qui ne '
      'change que la date', () async {
    final history = StreamIterator(store.watchHistory());
    addTearDown(history.cancel);

    expect(await history.moveNext(), isTrue);
    expect(keysOf(history.current), isEmpty);
    expect(history.current.lastSyncedAt, isNull);

    await store.save(transfer('k1', TransferStatus.pendingSubmission));
    expect(await history.moveNext(), isTrue);
    expect(keysOf(history.current), ['k1']);

    final syncedAt = DateTime(2026, 11, 23, 12);
    await store.saveSyncedHistory(
      const AccountStatement(transfers: [], balance: 1000000),
      syncedAt,
    );
    expect(await history.moveNext(), isTrue);
    expect(history.current.lastSyncedAt, syncedAt);
  });
}
