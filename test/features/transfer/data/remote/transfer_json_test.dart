import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/data/remote/transfer_json.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

void main() {
  // Forme exacte renvoyée par mock_server/server.js (toPublic).
  final serverJson = <String, dynamic>{
    'id': 'tr_123',
    'idempotencyKey': 'k1',
    'amount': 25000,
    'currency': 'XOF',
    'recipientPhone': '0701020304',
    'recipientName': 'Awa Kone',
    'status': 'SUBMITTED',
    'createdAt': '2026-11-23T10:00:00.000Z',
    'updatedAt': '2026-11-23T10:00:05.000Z',
  };

  test('JSON du serveur → Transfer', () {
    final transfer = transferFromJson(serverJson);

    expect(transfer.serverId, 'tr_123');
    expect(transfer.idempotencyKey, 'k1');
    expect(transfer.amount, 25000);
    expect(transfer.currency, 'XOF');
    expect(transfer.recipientPhone, '0701020304');
    expect(transfer.recipientName, 'Awa Kone');
    expect(transfer.status, TransferStatus.submitted);
    expect(transfer.createdAt, DateTime.utc(2026, 11, 23, 10));
    expect(transfer.updatedAt, DateTime.utc(2026, 11, 23, 10, 0, 5));
  });

  test('réponse de GET /transfers → transferts et solde', () {
    final statement = accountStatementFromJson({
      'items': [serverJson],
      'serverTime': '2026-11-23T10:01:00.000Z',
      'balance': 975000,
    });

    expect(statement.transfers.single.serverId, 'tr_123');
    expect(statement.balance, 975000);
  });

  test('statuts serveur → TransferStatus', () {
    expect(transferStatusFromServer('SUBMITTED'), TransferStatus.submitted);
    expect(transferStatusFromServer('PROCESSING'), TransferStatus.processing);
    expect(transferStatusFromServer('PAID'), TransferStatus.paid);
    expect(transferStatusFromServer('FAILED'), TransferStatus.failed);
  });

  test('statut serveur inconnu → FormatException, pas de devinette', () {
    expect(
      () => transferStatusFromServer('CANCELLED'),
      throwsA(isA<FormatException>()),
    );
  });

  test('TransferRequest → corps de POST /transfers', () {
    const request = TransferRequest(
      amount: 25000,
      recipientName: 'Awa Kone',
      recipientPhone: '0701020304',
    );

    expect(transferRequestToJson(request), {
      'amount': 25000,
      'currency': 'XOF',
      'recipientPhone': '0701020304',
      'recipientName': 'Awa Kone',
    });
  });
}
