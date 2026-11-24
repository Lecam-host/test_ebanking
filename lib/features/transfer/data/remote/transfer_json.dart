import 'package:test_ebanking/features/transfer/domain/entities/account_statement.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

/// Corps de `POST /transfers`. Le serveur calcule une empreinte de ces quatre
/// champs : un rejeu doit les renvoyer à l'identique.
Map<String, dynamic> transferRequestToJson(TransferRequest request) => {
  'amount': request.amount,
  'currency': request.currency,
  'recipientPhone': request.recipientPhone,
  'recipientName': request.recipientName,
};

/// Réponse de `GET /transfers` : `{ items, serverTime, balance }`. Un solde
/// absent est un contrat rompu : l'exception remonte, le cache reste tel quel.
AccountStatement accountStatementFromJson(Map<String, dynamic> json) =>
    AccountStatement(
      transfers: (json['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(transferFromJson)
          .toList(),
      balance: json['balance'] as int,
    );

/// Transfert tel que le serveur le renvoie.
Transfer transferFromJson(Map<String, dynamic> json) => Transfer(
  idempotencyKey: json['idempotencyKey'] as String,
  serverId: json['id'] as String,
  amount: json['amount'] as int,
  currency: json['currency'] as String,
  recipientName: json['recipientName'] as String,
  recipientPhone: json['recipientPhone'] as String,
  status: transferStatusFromServer(json['status'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

TransferStatus transferStatusFromServer(String status) => switch (status) {
  'SUBMITTED' => TransferStatus.submitted,
  'PROCESSING' => TransferStatus.processing,
  'PAID' => TransferStatus.paid,
  'FAILED' => TransferStatus.failed,
  // Contrat rompu : on refuse de deviner. Le transfert reste alors à
  // réconcilier, sans risque de double envoi.
  _ => throw FormatException('Statut serveur inconnu : $status'),
};
