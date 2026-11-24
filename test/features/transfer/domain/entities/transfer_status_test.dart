import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

void main() {
  test('isFinal : paid, failed et rejected seulement', () {
    expect(TransferStatus.values.where((status) => status.isFinal), [
      TransferStatus.paid,
      TransferStatus.failed,
      TransferStatus.rejected,
    ]);
  });

  test(
    'needsReconciliation : pendingSubmission et unknownOutcome seulement',
    () {
      expect(
        TransferStatus.values.where((status) => status.needsReconciliation),
        [TransferStatus.pendingSubmission, TransferStatus.unknownOutcome],
      );
    },
  );
}
