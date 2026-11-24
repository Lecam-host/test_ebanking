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
  final thisMonth = DateTime(2026, 11, 2);

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
