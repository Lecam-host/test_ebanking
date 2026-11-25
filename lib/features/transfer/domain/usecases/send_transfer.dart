import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/transfer_sender.dart';

/// Envoie un transfert sans jamais risquer de l'envoyer deux fois.
///
/// La clé d'idempotence vient de l'appelant, qui la génère une fois par
/// formulaire : elle identifie CETTE intention d'envoi, même si l'utilisateur
/// appuie deux fois ou réessaie. Le domaine ne fabrique jamais de clé.
class SendTransfer {
  SendTransfer({
    required this._store,
    required this._sender,
    required this._clock,
  });

  final TransferLocalStore _store;
  final TransferSender _sender;
  final Clock _clock;

  /// Voir [TransferSender] pour le sens du résultat. `Err(ValidationFailure)`
  /// en plus quand la saisie est invalide.
  ///
  /// [senderPhone] : numéro du client connecté. Le solde, lui, n'est pas
  /// vérifié ici : le dernier solde connu peut être périmé (remboursement,
  /// recrédit), seul le serveur tranche.
  Future<Result<Transfer>> call(
    TransferRequest request,
    String idempotencyKey, {
    required String senderPhone,
  }) async {
    // 1. Saisie invalide, ou envoi à soi-même : rien n'est écrit, aucun appel
    //    réseau. Le formulaire a déjà vérifié avant le récapitulatif ; on
    //    revérifie ici, car c'est le domaine qui garantit la règle.
    final errors = request.validate(senderPhone: senderPhone);
    if (errors.isNotEmpty) return Err(ValidationFailure(errors));

    // 2. Clé déjà connue (double appui, « Réessayer ») : pas de deuxième transfert.
    final existing = await _store.findByKey(idempotencyKey);
    if (existing != null) {
      if (existing.status.needsReconciliation) {
        return _sender.reconcile(existing);
      }
      return Ok(existing);
    }

    // 3. Écrire AVANT d'appeler : si l'app est tuée pendant l'envoi, la
    //    reprise retrouvera ce transfert et le réconciliera.
    final pending = Transfer.pending(
      request,
      idempotencyKey: idempotencyKey,
      at: _clock.now(),
    );
    await _store.save(pending);

    // 4 à 7. Envoi avec la même clé, puis mise à jour selon la réponse.
    return _sender.submit(pending);
  }
}
