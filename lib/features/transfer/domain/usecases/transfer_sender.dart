import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_repository.dart';

/// Envoie ou réconcilie un transfert DÉJÀ enregistré sur le téléphone.
///
/// Partagé par SendTransfer et ResumePendingTransfers : il n'existe qu'une
/// seule façon d'envoyer, toujours avec la clé du transfert, jamais une nouvelle.
///
/// Résultat :
/// - `Ok(transfert)` quand le transfert existe ou existe peut-être, y compris
///   en `unknownOutcome` : un résultat inconnu n'est pas un échec ;
/// - `Err(RejectedFailure)` quand le serveur a refusé (transfert `rejected`) ;
/// - `Err(UnauthorizedFailure)` quand la session est invalide : rien n'a été
///   créé, le transfert reste à envoyer après reconnexion.
class TransferSender {
  // `this._store` en paramètre nommé : l'appelant écrit `store:` (Dart 3.x).
  TransferSender({
    required this._repository,
    required this._store,
    required this._clock,
  });

  final TransferRepository _repository;
  final TransferLocalStore _store;
  final Clock _clock;

  /// Envoie le transfert avec SA clé d'idempotence.
  Future<Result<Transfer>> submit(Transfer transfer) async {
    final result = await _repository.submit(
      transfer.request,
      transfer.idempotencyKey,
    );
    switch (result) {
      case Ok(value: final fromServer):
        return _save(fromServer);
      case Err(
        failure: NetworkFailure() || TimeoutFailure() || ServerFailure(),
      ):
        // Pas de réponse, ou 5xx : le serveur a peut-être créé le transfert.
        return _save(_withStatus(transfer, TransferStatus.unknownOutcome));
      case Err(failure: final RejectedFailure failure):
        await _store.save(_withStatus(transfer, TransferStatus.rejected));
        return Err(failure);
      case Err(:final failure):
        // 401 : rien n'a été créé, on garde le transfert tel quel.
        return Err(failure);
    }
  }

  /// Demande d'abord au serveur s'il connaît la clé, et ne renvoie que s'il
  /// ne la connaît pas : c'est ce qui empêche le double envoi.
  Future<Result<Transfer>> reconcile(Transfer transfer) async {
    final lookup = await _repository.findByIdempotencyKey(
      transfer.idempotencyKey,
    );
    switch (lookup) {
      case Ok(value: final fromServer?):
        // Déjà créé (la réponse s'était perdue) : on met à jour, sans renvoi.
        return _save(fromServer);
      case Ok():
        // Inconnu du serveur : on rejoue l'envoi avec la même clé.
        return submit(transfer);
      case Err():
        // Impossible de vérifier : le résultat reste inconnu.
        return _save(_withStatus(transfer, TransferStatus.unknownOutcome));
    }
  }

  Transfer _withStatus(Transfer transfer, TransferStatus status) =>
      transfer.withStatus(status, at: _clock.now());

  Future<Result<Transfer>> _save(Transfer transfer) async {
    await _store.save(transfer);
    return Ok(transfer);
  }
}
