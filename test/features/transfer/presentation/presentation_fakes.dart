// Faux pour les tests de la présentation.
import 'package:test_ebanking/core/id_generator.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/send_transfer.dart';

import '../domain/fakes.dart';

/// Clés prévisibles : key-1, key-2…
class SequentialIdGenerator implements IdGenerator {
  var _next = 1;

  @override
  String newId() => 'key-${_next++}';
}

/// Remplace le cas d'usage : note chaque appel et répond ce qu'on lui dit.
class FakeSendTransfer implements SendTransfer {
  FakeSendTransfer([this.respond = _submitted]);

  /// Réponse à rendre ; un Completer permet de garder un envoi « en vol ».
  Future<Result<Transfer>> Function(TransferRequest request, String key)
  respond;

  final keys = <String>[];
  final requests = <TransferRequest>[];
  final senders = <String>[];

  @override
  Future<Result<Transfer>> call(
    TransferRequest request,
    String idempotencyKey, {
    required String senderPhone,
  }) {
    keys.add(idempotencyKey);
    requests.add(request);
    senders.add(senderPhone);
    return respond(request, idempotencyKey);
  }
}

Future<Result<Transfer>> _submitted(
  TransferRequest request,
  String key,
) async => Ok(localTransfer(key, TransferStatus.submitted));
