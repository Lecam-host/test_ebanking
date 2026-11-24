import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';

/// Relevé renvoyé par le serveur : les transferts et le solde, lus au même
/// instant, donc toujours cohérents entre eux.
class AccountStatement {
  const AccountStatement({required this.transfers, required this.balance});

  /// Du plus récent au plus ancien.
  final List<Transfer> transfers;

  /// Solde en FCFA. Seul le serveur le calcule : c'est lui qui débite,
  /// rembourse et refuse un montant trop élevé.
  final int balance;
}
