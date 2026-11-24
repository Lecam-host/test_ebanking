import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/home_summary.dart';

Transfer transfer(int amount, TransferStatus status, DateTime createdAt) =>
    Transfer(
      idempotencyKey: '$amount-${status.name}',
      amount: amount,
      currency: 'XOF',
      recipientName: 'Awa Kone',
      recipientPhone: '0701020304',
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

void main() {
  final now = DateTime(2026, 11, 24, 12);
  final thisMonth = DateTime(2026, 11, 2);

  test(
    'envoyé ce mois-ci : seuls les transferts acceptés du mois comptent',
    () {
      final transfers = [
        transfer(50000, TransferStatus.paid, thisMonth),
        transfer(20000, TransferStatus.submitted, thisMonth),
        transfer(5000, TransferStatus.processing, thisMonth),
        // Peut-être pas parti, ou rien envoyé : exclus.
        transfer(7000, TransferStatus.unknownOutcome, thisMonth),
        transfer(3000, TransferStatus.rejected, thisMonth),
        transfer(2000, TransferStatus.failed, thisMonth),
        // Mois précédent : exclu.
        transfer(90000, TransferStatus.paid, DateTime(2026, 10, 31)),
      ];

      expect(amountSentThisMonth(transfers, now), 75000);
    },
  );

  test('pastille : transferts encore en vérification', () {
    expect(
      uncertainCount([
        transfer(1, TransferStatus.pendingSubmission, thisMonth),
        transfer(2, TransferStatus.unknownOutcome, thisMonth),
        transfer(3, TransferStatus.paid, thisMonth),
      ]),
      2,
    );
  });

  test('numéro affiché par paires, et masqué comme un numéro de carte', () {
    expect(formatPhone('0701020304'), '07 01 02 03 04');
    expect(maskPhone('0701020304'), '07 •• •• 03 04');
  });
}
