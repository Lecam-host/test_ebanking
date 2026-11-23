// Faux écrits à la main pour les tests du domaine.
//
// Le faux serveur et le faux stockage écrivent dans le MÊME journal : un test
// peut ainsi vérifier l'ordre exact des écritures et des appels réseau.
import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_repository.dart';

final t0 = DateTime(2026, 11, 23, 10);

const validRequest = TransferRequest(
  amount: 25000,
  recipientName: 'Awa Kone',
  recipientPhone: '0701020304',
);

/// Transfert enregistré sur le téléphone, avec le statut voulu.
Transfer localTransfer(String key, TransferStatus status) => Transfer.pending(
  validRequest,
  idempotencyKey: key,
  at: t0,
).withStatus(status, at: t0);

/// Transfert tel que le serveur le renvoie après l'avoir créé.
Transfer serverTransfer(String key, TransferRequest request) => Transfer(
  idempotencyKey: key,
  serverId: 'tr_$key',
  amount: request.amount,
  currency: request.currency,
  recipientName: request.recipientName,
  recipientPhone: request.recipientPhone,
  status: TransferStatus.submitted,
  createdAt: t0,
  updatedAt: t0,
);

class FakeClock implements Clock {
  DateTime current = t0;

  @override
  DateTime now() => current;
}

class FakeTransferRepository implements TransferRepository {
  FakeTransferRepository(this.log);

  final List<String> log;

  /// Transferts créés côté serveur, par clé.
  final created = <String, Transfer>{};

  /// Quand ils sont renseignés, renvoyés à la place de la réponse normale.
  Failure? submitFailure;
  Failure? findFailure;
  Failure? historyFailure;

  @override
  Future<Result<Transfer>> submit(
    TransferRequest request,
    String idempotencyKey,
  ) async {
    log.add('api.submit $idempotencyKey');
    if (submitFailure case final failure?) return Err(failure);
    // Comme le vrai serveur : une clé déjà vue renvoie le transfert existant.
    return Ok(
      created.putIfAbsent(
        idempotencyKey,
        () => serverTransfer(idempotencyKey, request),
      ),
    );
  }

  @override
  Future<Result<Transfer?>> findByIdempotencyKey(String idempotencyKey) async {
    log.add('api.find $idempotencyKey');
    if (findFailure case final failure?) return Err(failure);
    return Ok(created[idempotencyKey]);
  }

  @override
  Future<Result<List<Transfer>>> fetchHistory() async {
    log.add('api.fetchHistory');
    if (historyFailure case final failure?) return Err(failure);
    return Ok(created.values.toList());
  }

  @override
  Future<Result<Transfer>> getById(String serverId) =>
      throw UnimplementedError('pas utilisé par ces tests');
}

class FakeTransferLocalStore implements TransferLocalStore {
  FakeTransferLocalStore(this.log);

  final List<String> log;

  /// Contenu du stockage, par clé, dans l'ordre de création.
  final byKey = <String, Transfer>{};
  DateTime? lastSyncedAt;

  @override
  Future<Transfer?> findByKey(String idempotencyKey) async =>
      byKey[idempotencyKey];

  @override
  Future<void> save(Transfer transfer) async {
    log.add('store.save ${transfer.idempotencyKey} ${transfer.status.name}');
    byKey[transfer.idempotencyKey] = transfer;
  }

  @override
  Future<List<Transfer>> findNeedingReconciliation() async => byKey.values
      .where((transfer) => transfer.status.needsReconciliation)
      .toList();

  @override
  Future<void> saveSyncedHistory(
    List<Transfer> transfers,
    DateTime syncedAt,
  ) async {
    log.add('store.saveSyncedHistory');
    for (final transfer in transfers) {
      byKey[transfer.idempotencyKey] = transfer;
    }
    lastSyncedAt = syncedAt;
  }

  @override
  Stream<TransferHistory> watchHistory() => Stream.value(
    TransferHistory(
      transfers: byKey.values.toList(),
      lastSyncedAt: lastSyncedAt,
    ),
  );
}
