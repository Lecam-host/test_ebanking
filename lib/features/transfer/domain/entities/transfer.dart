import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

/// Un transfert tel que le téléphone le connaît.
class Transfer {
  const Transfer({
    required this.idempotencyKey,
    this.serverId,
    required this.amount,
    required this.currency,
    required this.recipientName,
    required this.recipientPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nouveau transfert, enregistré avant tout appel réseau.
  Transfer.pending(
    TransferRequest request, {
    required String idempotencyKey,
    required DateTime at,
  }) : this(
         idempotencyKey: idempotencyKey,
         amount: request.amount,
         currency: request.currency,
         recipientName: request.recipientName,
         recipientPhone: request.recipientPhone,
         status: TransferStatus.pendingSubmission,
         createdAt: at,
         updatedAt: at,
       );

  /// Identifiant local stable, qui existe avant tout appel réseau. C'est aussi
  /// la clé d'idempotence envoyée au serveur.
  final String idempotencyKey;

  /// Identifiant donné par le serveur ; null tant qu'il n'a rien confirmé.
  final String? serverId;

  /// Montant en FCFA.
  final int amount;
  final String currency;
  final String recipientName;
  final String recipientPhone;
  final TransferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Contenu exact à renvoyer lors d'un rejeu : le serveur refuse une clé
  /// réutilisée avec un contenu différent.
  TransferRequest get request => TransferRequest(
    amount: amount,
    currency: currency,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
  );

  /// Seul le statut évolue : le contenu est lié à la clé et ne change jamais.
  Transfer withStatus(TransferStatus status, {required DateTime at}) => Transfer(
    idempotencyKey: idempotencyKey,
    serverId: serverId,
    amount: amount,
    currency: currency,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
    status: status,
    createdAt: createdAt,
    updatedAt: at,
  );
}
