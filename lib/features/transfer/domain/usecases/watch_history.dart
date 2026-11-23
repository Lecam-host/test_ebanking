import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';

/// Historique lu sur le téléphone uniquement : il s'affiche sans réseau, avec
/// l'heure de sa dernière synchronisation.
class WatchHistory {
  WatchHistory({required this._store});

  final TransferLocalStore _store;

  Stream<TransferHistory> call() => _store.watchHistory();
}
