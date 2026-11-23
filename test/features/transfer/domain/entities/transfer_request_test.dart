import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';

void main() {
  TransferRequest request({
    int amount = 25000,
    String name = 'Awa Kone',
    String phone = '0701020304',
  }) => TransferRequest(
    amount: amount,
    recipientName: name,
    recipientPhone: phone,
  );

  test('requête valide → aucune erreur', () {
    expect(request().validate(), isEmpty);
  });

  test('montant nul ou négatif refusé', () {
    for (final amount in [0, -100]) {
      expect(request(amount: amount).validate(), hasLength(1), reason: '$amount');
    }
  });

  test('numéro : exactement 10 chiffres, sans espace ni indicatif', () {
    for (final phone in [
      '070102030',
      '07010203045',
      '07 01 02 03 04',
      '+2250701020304',
      '070102030a',
    ]) {
      expect(request(phone: phone).validate(), hasLength(1), reason: phone);
    }
  });

  test('nom vide ou fait d\'espaces refusé', () {
    for (final name in ['', '   ']) {
      expect(request(name: name).validate(), hasLength(1), reason: '"$name"');
    }
  });

  test('toutes les erreurs sont signalées ensemble', () {
    expect(request(amount: 0, name: '', phone: '1').validate(), hasLength(3));
  });
}
