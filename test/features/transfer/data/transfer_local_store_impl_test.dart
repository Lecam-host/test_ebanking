import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/data/transfer_local_store_impl.dart';
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

  test('saveSyncedHistory : enregistre la date et garde les transferts '
      'encore inconnus du serveur', () async {
    await store.save(transfer('local', TransferStatus.pendingSubmission));
    final syncedAt = DateTime(2026, 11, 23, 12);

    await store.saveSyncedHistory([
      transfer('k1', TransferStatus.paid, serverId: 'tr_1', minute: 1),
    ], syncedAt);

    final history = await store.watchHistory().first;
    expect(keysOf(history), ['k1', 'local']); // du plus récent au plus ancien
    expect(history.lastSyncedAt, syncedAt);
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
    await store.saveSyncedHistory(const [], syncedAt);
    expect(await history.moveNext(), isTrue);
    expect(history.current.lastSyncedAt, syncedAt);
  });
}
