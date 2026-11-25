import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/recent_beneficiaries.dart';

Transfer transferTo(String name, String phone, int minute) => Transfer(
  idempotencyKey: '$phone-$minute',
  amount: 1000,
  currency: 'XOF',
  recipientName: name,
  recipientPhone: phone,
  status: TransferStatus.paid,
  createdAt: DateTime(2026, 11, 25, 10, minute),
  updatedAt: DateTime(2026, 11, 25, 10, minute),
);

void main() {
  test('un bénéficiaire par numéro, le plus récent d\'abord, avec son dernier '
      'nom', () {
    // Historique : du plus récent au plus ancien.
    final history = [
      transferTo('Awa K.', '0701020304', 30),
      transferTo('Jean', '0505050505', 20),
      transferTo('Awa Kone', '0701020304', 10),
    ];

    expect(recentBeneficiaries(history), [
      (name: 'Awa K.', phone: '0701020304'),
      (name: 'Jean', phone: '0505050505'),
    ]);
  });

  test('limité aux plus récents', () {
    final history = [
      for (var i = 0; i < 5; i++) transferTo('B$i', '070000000$i', 50 - i),
    ];

    expect(recentBeneficiaries(history, max: 3).map((b) => b.name), [
      'B0',
      'B1',
      'B2',
    ]);
  });
}
