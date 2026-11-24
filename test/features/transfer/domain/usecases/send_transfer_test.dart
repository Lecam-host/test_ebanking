import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/send_transfer.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/transfer_sender.dart';

import '../fakes.dart';

void main() {
  late List<String> log;
  late FakeTransferRepository server;
  late FakeTransferLocalStore store;
  late SendTransfer sendTransfer;

  setUp(() {
    log = [];
    server = FakeTransferRepository(log);
    store = FakeTransferLocalStore(log);
    final clock = FakeClock();
    sendTransfer = SendTransfer(
      store: store,
      sender: TransferSender(repository: server, store: store, clock: clock),
      clock: clock,
    );
  });

  Matcher okWithStatus(TransferStatus status) =>
      isA<Ok<Transfer>>().having((ok) => ok.value.status, 'status', status);

  test('1. enregistre pendingSubmission AVANT l\'appel réseau', () async {
    final result = await sendTransfer(validRequest, 'k1');

    expect(log, [
      'store.save k1 pendingSubmission',
      'api.submit k1',
      'store.save k1 submitted',
    ]);
    expect(result, okWithStatus(TransferStatus.submitted));
    expect(store.byKey['k1']!.serverId, 'tr_k1');
  });

  group('2. timeout ou coupure → unknownOutcome, jamais failed', () {
    for (final failure in const [TimeoutFailure(), NetworkFailure()]) {
      test('${failure.runtimeType}', () async {
        server.submitFailure = failure;

        final result = await sendTransfer(validRequest, 'k1');

        // Pas un échec : le résultat dit « en vérification ».
        expect(result, okWithStatus(TransferStatus.unknownOutcome));
        expect(log, [
          'store.save k1 pendingSubmission',
          'api.submit k1',
          'store.save k1 unknownOutcome',
        ]);
      });
    }
  });

  test('3. erreur 5xx → unknownOutcome : le serveur a peut-être créé le '
      'transfert', () async {
    server.submitFailure = const ServerFailure();

    final result = await sendTransfer(validRequest, 'k1');

    expect(result, okWithStatus(TransferStatus.unknownOutcome));
    expect(store.byKey['k1']!.status, TransferStatus.unknownOutcome);
  });

  test('4. refus 4xx → rejected, avec le code du serveur', () async {
    server.submitFailure = const RejectedFailure('validation_error');

    final result = await sendTransfer(validRequest, 'k1');

    expect(
      result,
      isA<Err<Transfer>>().having(
        (err) => err.failure,
        'failure',
        isA<RejectedFailure>().having(
          (f) => f.code,
          'code',
          'validation_error',
        ),
      ),
    );
    expect(store.byKey['k1']!.status, TransferStatus.rejected);
  });

  test('5. requête invalide → aucune écriture, aucun appel réseau', () async {
    const invalid = TransferRequest(
      amount: 0,
      recipientName: '',
      recipientPhone: '123',
    );

    final result = await sendTransfer(invalid, 'k1');

    expect(
      result,
      isA<Err<Transfer>>().having(
        (err) => err.failure,
        'failure',
        isA<ValidationFailure>(),
      ),
    );
    expect(log, isEmpty);
    expect(store.byKey, isEmpty);
  });

  test('6. même clé envoyée deux fois → un seul transfert local, un seul '
      'envoi', () async {
    await sendTransfer(validRequest, 'k1');
    await sendTransfer(validRequest, 'k1');

    expect(store.byKey.keys, ['k1']);
    expect(log.where((line) => line.startsWith('api.submit')), hasLength(1));
  });

  test('6 bis. « Réessayer » après un timeout → vérifie auprès du serveur '
      'au lieu de renvoyer', () async {
    server.submitFailure = const TimeoutFailure();
    await sendTransfer(validRequest, 'k1');
    // Le serveur avait bien créé le transfert : seule la réponse s'est perdue.
    server.submitFailure = null;
    server.created['k1'] = serverTransfer('k1', validRequest);
    log.clear();

    final result = await sendTransfer(validRequest, 'k1');

    expect(log, ['api.find k1', 'store.save k1 submitted']);
    expect(result, okWithStatus(TransferStatus.submitted));
    expect(store.byKey.keys, ['k1']);
  });
}
