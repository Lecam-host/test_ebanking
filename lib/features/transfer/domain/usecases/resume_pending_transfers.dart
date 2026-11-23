import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/transfer_sender.dart';

/// Réconcilie les transferts au statut incertain : app tuée pendant l'envoi,
/// réponse perdue, serveur trop lent.
///
/// Ne génère jamais de nouvelle clé : chaque transfert garde la sienne.
class ResumePendingTransfers {
  ResumePendingTransfers({required this._store, required this._sender});

  final TransferLocalStore _store;
  final TransferSender _sender;

  Future<void> call() async {
    final pending = await _store.findNeedingReconciliation();
    for (final transfer in pending) {
      final result = await _sender.reconcile(transfer);

      final settled = switch (result) {
        Ok(:final value) => !value.status.needsReconciliation,
        Err(failure: RejectedFailure()) => true,
        Err() => false,
      };
      // Le serveur n'a pas pu trancher (injoignable, session expirée) : inutile
      // d'insister pour les suivants, on réessaiera au prochain passage.
      if (!settled) return;
    }
  }
}
