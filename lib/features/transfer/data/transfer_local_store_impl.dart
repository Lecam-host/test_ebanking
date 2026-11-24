import 'package:drift/drift.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';

class TransferLocalStoreImpl implements TransferLocalStore {
  TransferLocalStoreImpl(this._db);

  final TransferDatabase _db;

  /// Identifiant de l'unique ligne de la table sync_state.
  static const _syncRowId = 1;

  @override
  Future<Transfer?> findByKey(String idempotencyKey) async {
    final query = _db.select(_db.transfers)
      ..where((t) => t.idempotencyKey.equals(idempotencyKey));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(Transfer transfer) async {
    // INSERT ... ON CONFLICT DO UPDATE : la même clé remplace la ligne.
    await _db.into(_db.transfers).insertOnConflictUpdate(_toRow(transfer));
  }

  @override
  Future<List<Transfer>> findNeedingReconciliation() async {
    final query = _db.select(_db.transfers)
      ..where(
        (t) => t.status.isInValues(
          TransferStatus.values.where((status) => status.needsReconciliation),
        ),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> saveSyncedHistory(List<Transfer> transfers, DateTime syncedAt) {
    return _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _db.transfers,
          transfers.map(_toRow).toList(),
        );
      });
      await _db
          .into(_db.syncState)
          .insertOnConflictUpdate(
            SyncStateRow(id: _syncRowId, lastSyncedAt: syncedAt),
          );
    });
  }

  @override
  Stream<TransferHistory> watchHistory() {
    // Requête vide qui déclare lire les deux tables : Drift la relance dès
    // que l'une d'elles change, et on relit alors l'historique complet.
    // (Surveiller seulement `transfers` raterait une synchro qui ne change
    // que la date, par exemple quand le serveur n'a aucun transfert.)
    final anyChange = _db.customSelect(
      'SELECT 1',
      readsFrom: {_db.transfers, _db.syncState},
    );
    return anyChange.watch().asyncMap((_) => _readHistory());
  }

  @override
  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_db.transfers).go();
    await _db.delete(_db.syncState).go();
  });

  /// Les deux lectures dans une transaction : la liste et sa date de synchro
  /// viennent toujours du même instant.
  Future<TransferHistory> _readHistory() => _db.transaction(() async {
    final transfers = await (_db.select(
      _db.transfers,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    final sync = await (_db.select(
      _db.syncState,
    )..where((s) => s.id.equals(_syncRowId))).getSingleOrNull();
    return TransferHistory(
      transfers: transfers.map(_toEntity).toList(),
      lastSyncedAt: sync?.lastSyncedAt,
    );
  });

  static TransferRow _toRow(Transfer transfer) => TransferRow(
    idempotencyKey: transfer.idempotencyKey,
    serverId: transfer.serverId,
    amount: transfer.amount,
    currency: transfer.currency,
    recipientName: transfer.recipientName,
    recipientPhone: transfer.recipientPhone,
    status: transfer.status,
    createdAt: transfer.createdAt,
    updatedAt: transfer.updatedAt,
  );

  static Transfer _toEntity(TransferRow row) => Transfer(
    idempotencyKey: row.idempotencyKey,
    serverId: row.serverId,
    amount: row.amount,
    currency: row.currency,
    recipientName: row.recipientName,
    recipientPhone: row.recipientPhone,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
