import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';

/// Historique affiché, lu sur le téléphone : il est disponible sans réseau.
class TransferHistory {
  const TransferHistory({required this.transfers, required this.lastSyncedAt});

  /// Du plus récent au plus ancien.
  final List<Transfer> transfers;

  /// Dernière synchronisation réussie avec le serveur ; null si jamais.
  final DateTime? lastSyncedAt;
}
