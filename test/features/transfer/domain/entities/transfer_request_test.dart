import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';

void main() {
  /// Numéro du client connecté.
  const me = '0700000001';

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
    expect(request().validate(senderPhone: me), isEmpty);
  });

  test('montant nul ou négatif refusé', () {
    for (final amount in [0, -100]) {
      expect(
        request(amount: amount).validate(senderPhone: me),
        hasLength(1),
        reason: '$amount',
      );
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
      expect(
        request(phone: phone).validate(senderPhone: me),
        hasLength(1),
        reason: phone,
      );
    }
  });

  test('nom vide ou fait d\'espaces refusé', () {
    for (final name in ['', '   ']) {
      expect(
        request(name: name).validate(senderPhone: me),
        hasLength(1),
        reason: '"$name"',
      );
    }
  });

  test('envoi à son propre numéro refusé', () {
    expect(request(phone: me).validate(senderPhone: me), [
      'Vous ne pouvez pas vous envoyer de l\'argent.',
    ]);
  });

  test('toutes les erreurs sont signalées ensemble', () {
    expect(
      request(amount: 0, name: '', phone: '1').validate(senderPhone: me),
      hasLength(3),
    );
  });
}
