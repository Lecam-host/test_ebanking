import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';

/// Transferts encore « en vérification » (pastille de la cloche).
int uncertainCount(List<Transfer> transfers) =>
    transfers.where((t) => t.status.needsReconciliation).length;
