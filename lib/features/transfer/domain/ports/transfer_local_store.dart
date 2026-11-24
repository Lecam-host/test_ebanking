import 'package:test_ebanking/features/transfer/domain/entities/account_statement.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';

/// Transferts stockés sur le téléphone : à la fois l'outbox (transferts à
/// confirmer) et le cache de l'historique. Implémenté dans data/.
///
/// Toute écriture « insère ou remplace » par idempotencyKey : rejouer une
/// écriture ne crée jamais de doublon.
///
/// Pas de `Result` ici : une erreur de stockage local (disque plein, base
/// corrompue) n'est pas un cas métier attendu, elle reste une exception.
abstract interface class TransferLocalStore {
  Future<Transfer?> findByKey(String idempotencyKey);

  Future<void> save(Transfer transfer);

  /// Transferts au statut incertain, du plus ancien au plus récent.
  Future<List<Transfer>> findNeedingReconciliation();

  /// Enregistre le relevé du serveur (transferts et solde) et l'heure de
  /// synchro dans la même transaction, pour que l'écran ne voie jamais l'un
  /// sans l'autre.
  /// N'efface rien : un transfert encore inconnu du serveur reste dans l'outbox.
  Future<void> saveSyncedHistory(AccountStatement statement, DateTime syncedAt);

  /// Historique local, réémis à chaque changement.
  Stream<TransferHistory> watchHistory();

  /// Efface tous les transferts, la date de synchro et le solde (déconnexion).
  Future<void> clear();
}
