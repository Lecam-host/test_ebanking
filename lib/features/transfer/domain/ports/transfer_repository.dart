import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';

/// Accès aux transferts sur le serveur. Implémenté dans data/.
abstract interface class TransferRepository {
  /// Crée le transfert. Si le serveur connaît déjà [idempotencyKey], il renvoie
  /// le transfert existant au lieu d'en créer un deuxième.
  Future<Result<Transfer>> submit(
    TransferRequest request,
    String idempotencyKey,
  );

  /// `Ok(null)` si le serveur ne connaît pas la clé : le transfert n'a pas été créé.
  Future<Result<Transfer?>> findByIdempotencyKey(String idempotencyKey);

  /// Tous les transferts, du plus récent au plus ancien.
  Future<Result<List<Transfer>>> fetchHistory();

  Future<Result<Transfer>> getById(String serverId);
}
