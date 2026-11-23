import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_repository.dart';

/// Rafraîchit le cache local de l'historique depuis le serveur.
class SyncHistory {
  SyncHistory({
    required this._repository,
    required this._store,
    required this._clock,
  });

  final TransferRepository _repository;
  final TransferLocalStore _store;
  final Clock _clock;

  Future<Result<void>> call() async {
    final result = await _repository.fetchHistory();
    switch (result) {
      case Ok(value: final transfers):
        // Heure du téléphone et non celle du serveur : « il y a X min » se
        // calcule avec l'horloge du téléphone, qui peut être décalée.
        await _store.saveSyncedHistory(transfers, _clock.now());
        return const Ok(null);
      case Err(:final failure):
        // Échec : le cache et sa date restent tels quels.
        return Err(failure);
    }
  }
}
