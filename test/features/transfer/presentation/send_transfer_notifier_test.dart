import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/send_transfer_notifier.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

import '../../auth/auth_fakes.dart';
import '../domain/fakes.dart';
import 'presentation_fakes.dart';

void main() {
  late FakeSendTransfer sendTransfer;
  late FakePinLock pinLock;
  late FixedAuthNotifier auth;
  late ProviderContainer container;

  SendTransferNotifier notifier() =>
      container.read(sendTransferNotifierProvider.notifier);
  SendFormState form() => container.read(sendTransferNotifierProvider);
  Future<void> send(TransferRequest request) =>
      notifier().send(request, pin: '1234');

  void setUpWith(FakeSendTransfer fake) {
    sendTransfer = fake;
    pinLock = FakePinLock();
    auth = FixedAuthNotifier(AuthStatus.unlocked);
    container = ProviderContainer.test(
      overrides: [
        sendTransferProvider.overrideWithValue(fake),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        pinLockProvider.overrideWithValue(pinLock),
        authNotifierProvider.overrideWith(() => auth),
        currentPhoneProvider.overrideWithValue('0700000001'),
      ],
    );
  }

  test('« Réessayer » renvoie la même clé et le même contenu', () async {
    setUpWith(
      FakeSendTransfer(
        (_, key) async => Ok(localTransfer(key, TransferStatus.unknownOutcome)),
      ),
    );

    await send(validRequest);
    expect(form().canRetry, isTrue);
    await notifier().retry();

    expect(sendTransfer.keys, ['key-1', 'key-1']);
    expect(sendTransfer.requests, everyElement(same(validRequest)));
    // Le domaine reçoit le numéro du client, pour refuser l'envoi à soi-même.
    expect(sendTransfer.senders, everyElement('0700000001'));
  });

  test('formulaire figé : un contenu modifié ne repart pas avec la même '
      'clé', () async {
    setUpWith(
      FakeSendTransfer(
        (_, key) async => Ok(localTransfer(key, TransferStatus.unknownOutcome)),
      ),
    );
    await send(validRequest);

    await send(
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

    await send(validRequest);
    expect(form().isLocked, isFalse);

    sendTransfer.respond = (_, key) async =>
        Ok(localTransfer(key, TransferStatus.submitted));
    await send(validRequest);

    expect(sendTransfer.keys, ['key-1', 'key-1']);
    expect(form().isLocked, isTrue);
  });

  test('« Nouveau transfert » crée une nouvelle clé', () async {
    setUpWith(FakeSendTransfer());
    await send(validRequest);

    notifier().startNew();

    expect(form().idempotencyKey, 'key-2');
    expect(form().isLocked, isFalse);
  });

  test('code secret incorrect → rien n\'est envoyé', () async {
    setUpWith(FakeSendTransfer());
    pinLock.answer = const PinRejected(3);

    await send(validRequest);

    expect(sendTransfer.keys, isEmpty);
    expect(form().pinError, contains('3'));
    expect(form().isSending, isFalse);
  });

  test('trop de codes ratés → déconnexion, et rien n\'est envoyé', () async {
    setUpWith(FakeSendTransfer());
    pinLock.answer = const PinBlocked();

    await send(validRequest);

    expect(sendTransfer.keys, isEmpty);
    expect(auth.signOutMessages, hasLength(1));
  });

  test('confirmation seulement si le serveur a accepté ; rouvrir l\'écran '
      'après un transfert accepté repart d\'une nouvelle clé', () async {
    setUpWith(FakeSendTransfer()); // répond « envoyé »
    await send(validRequest);
    expect(form().accepted?.idempotencyKey, 'key-1');

    notifier().open();

    expect(form().idempotencyKey, 'key-2');
    expect(form().accepted, isNull);
  });

  test('transfert incertain : pas de confirmation, et rouvrir l\'écran garde '
      'sa clé', () async {
    setUpWith(
      FakeSendTransfer(
        (_, key) async => Ok(localTransfer(key, TransferStatus.unknownOutcome)),
      ),
    );
    await send(validRequest);
    expect(form().accepted, isNull);

    notifier().open();

    expect(form().idempotencyKey, 'key-1');
    expect(form().isLocked, isTrue);
  });

  test('déconnexion → le formulaire repart avec une nouvelle clé', () async {
    setUpWith(FakeSendTransfer());
    await send(validRequest);
    expect(form().isLocked, isTrue);

    await auth.signOut();

    expect(form().isLocked, isFalse);
    expect(form().idempotencyKey, 'key-2');
  });
}
