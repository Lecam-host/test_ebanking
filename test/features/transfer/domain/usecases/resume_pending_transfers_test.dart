import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/resume_pending_transfers.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/transfer_sender.dart';

import '../fakes.dart';

void main() {
  late List<String> log;
  late FakeTransferRepository server;
  late FakeTransferLocalStore store;
  late ResumePendingTransfers resume;

  setUp(() {
    log = [];
    server = FakeTransferRepository(log);
    store = FakeTransferLocalStore(log);
    resume = ResumePendingTransfers(
      store: store,
      sender: TransferSender(
        repository: server,
        store: store,
        clock: FakeClock(),
      ),
    );
  });

  TransferStatus? statusOf(String key) => store.byKey[key]?.status;

  test('7. clé connue du serveur → mise à jour sans nouvel envoi', () async {
    store.byKey['k1'] = localTransfer('k1', TransferStatus.unknownOutcome);
    // Le serveur a créé le transfert, mais la réponse s'est perdue.
    server.created['k1'] = serverTransfer('k1', validRequest);

    await resume();

    expect(log, ['api.find k1', 'store.save k1 submitted']);
    expect(store.byKey['k1']!.serverId, 'tr_k1');
  });

  test('8. clé inconnue du serveur → envoi rejoué avec la même clé', () async {
    // App tuée juste après l'enregistrement local, avant l'envoi.
    store.byKey['k1'] = localTransfer('k1', TransferStatus.pendingSubmission);

    await resume();

    expect(log, ['api.find k1', 'api.submit k1', 'store.save k1 submitted']);
    expect(statusOf('k1'), TransferStatus.submitted);
  });

  test(
    '9. sans réseau → reste en unknownOutcome, et le passage s\'arrête',
    () async {
      store.byKey['k1'] = localTransfer('k1', TransferStatus.unknownOutcome);
      store.byKey['k2'] = localTransfer('k2', TransferStatus.pendingSubmission);
      server.findFailure = const NetworkFailure();

      await resume();

      // k2 n'est même pas tenté : le serveur est injoignable.
      expect(log, ['api.find k1', 'store.save k1 unknownOutcome']);
      expect(statusOf('k1'), TransferStatus.unknownOutcome);
      expect(statusOf('k2'), TransferStatus.pendingSubmission);
    },
  );

  test('9 bis. rejeu sans réponse → passe en unknownOutcome', () async {
    store.byKey['k1'] = localTransfer('k1', TransferStatus.pendingSubmission);
    server.submitFailure = const TimeoutFailure();

    await resume();

    expect(log, [
      'api.find k1',
      'api.submit k1',
      'store.save k1 unknownOutcome',
    ]);
  });

  test('10. aucune nouvelle clé n\'apparaît pendant une reprise', () async {
    store.byKey['k1'] = localTransfer('k1', TransferStatus.unknownOutcome);
    store.byKey['k2'] = localTransfer('k2', TransferStatus.pendingSubmission);
    server.created['k1'] = serverTransfer('k1', validRequest);

    await resume();

    final keysSentToServer = log
        .where((line) => line.startsWith('api.'))
        .map((line) => line.split(' ').last)
        .toSet();
    expect(keysSentToServer, {'k1', 'k2'});
    expect(store.byKey.keys, unorderedEquals(['k1', 'k2']));
    expect(server.created.keys, unorderedEquals(['k1', 'k2']));
  });

  test(
    'un refus n\'empêche pas de réconcilier les transferts suivants',
    () async {
      store.byKey['k1'] = localTransfer('k1', TransferStatus.pendingSubmission);
      store.byKey['k2'] = localTransfer('k2', TransferStatus.pendingSubmission);
      server.submitFailure = const RejectedFailure('validation_error');

      await resume();

      expect(statusOf('k1'), TransferStatus.rejected);
      expect(statusOf('k2'), TransferStatus.rejected);
      expect(log, contains('api.submit k2'));
    },
  );
}
