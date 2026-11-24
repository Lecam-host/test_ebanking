import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

/// Montant envoyé ce mois-ci, calculé sur l'historique du téléphone.
///
/// Seuls comptent les transferts acceptés par le serveur : un transfert
/// incertain n'est peut-être pas parti, un refusé ou échoué n'a rien envoyé.
int amountSentThisMonth(List<Transfer> transfers, DateTime now) => transfers
    .where((t) => _sameMonth(t.createdAt.toLocal(), now) && _accepted(t.status))
    .fold(0, (sum, t) => sum + t.amount);

/// Transferts encore « en vérification » (pastille de la cloche).
int uncertainCount(List<Transfer> transfers) =>
    transfers.where((t) => t.status.needsReconciliation).length;

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool _accepted(TransferStatus status) =>
    status == TransferStatus.submitted ||
    status == TransferStatus.processing ||
    status == TransferStatus.paid;
