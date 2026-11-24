import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/send_transfer_notifier.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

import '../domain/fakes.dart';
import 'presentation_fakes.dart';

void main() {
  late FakeSendTransfer sendTransfer;
  late ProviderContainer container;

  SendTransferNotifier notifier() =>
      container.read(sendTransferNotifierProvider.notifier);
  SendFormState form() => container.read(sendTransferNotifierProvider);

  void setUpWith(FakeSendTransfer fake) {
    sendTransfer = fake;
    container = ProviderContainer.test(
      overrides: [
        sendTransferProvider.overrideWithValue(fake),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
  }

  test('« Réessayer » renvoie la même clé et le même contenu', () async {
    setUpWith(
      FakeSendTransfer(
        (_, key) async => Ok(localTransfer(key, TransferStatus.unknownOutcome)),
      ),
    );

    await notifier().send(validRequest);
    expect(form().canRetry, isTrue);
    await notifier().retry();

    expect(sendTransfer.keys, ['key-1', 'key-1']);
    expect(sendTransfer.requests, everyElement(same(validRequest)));
  });

  test('formulaire figé : un contenu modifié ne repart pas avec la même '
      'clé', () async {
    setUpWith(
      FakeSendTransfer(
        (_, key) async => Ok(localTransfer(key, TransferStatus.unknownOutcome)),
      ),
    );
    await notifier().send(validRequest);

    await notifier().send(
      const TransferRequest(
        amount: 99000,
        recipientName: 'Autre',
        recipientPhone: '0505050505',
      ),
    );

    expect(sendTransfer.requests, everyElement(same(validRequest)));
  });

  test('saisie invalide : formulaire modifiable, et la même clé sert à '
      'l\'envoi suivant', () async {
    setUpWith(
      FakeSendTransfer(
        (_, _) async => const Err(ValidationFailure(['Montant invalide'])),
      ),
    );

    await notifier().send(validRequest);
    expect(form().isLocked, isFalse);

    sendTransfer.respond = (_, key) async =>
        Ok(localTransfer(key, TransferStatus.submitted));
    await notifier().send(validRequest);

    expect(sendTransfer.keys, ['key-1', 'key-1']);
    expect(form().isLocked, isTrue);
  });

  test('« Nouveau transfert » crée une nouvelle clé', () async {
    setUpWith(FakeSendTransfer());
    await notifier().send(validRequest);

    notifier().startNew();

    expect(form().idempotencyKey, 'key-2');
    expect(form().isLocked, isFalse);
  });
}
