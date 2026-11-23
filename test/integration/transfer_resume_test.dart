// Tests de bout en bout contre le serveur simulé (mock_server/), avec la vraie
// couche data : Dio et Drift (base en mémoire).
//
// Lancer d'abord : cd mock_server && npm start
// Puis : flutter test --tags integration --run-skipped
@Tags(['integration'])
library;

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/id_generator.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/data/remote/transfer_api.dart';
import 'package:test_ebanking/features/transfer/data/transfer_local_store_impl.dart';
import 'package:test_ebanking/features/transfer/data/transfer_repository_impl.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/resume_pending_transfers.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/send_transfer.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/transfer_sender.dart';

const _baseUrl = 'http://localhost:3000';

const _request = TransferRequest(
  amount: 25000,
  recipientName: 'Awa Kone',
  recipientPhone: '0701020304',
);

void main() {
  // Client séparé pour piloter le serveur : les routes /admin ne subissent
  // jamais les pannes simulées.
  final admin = Dio(BaseOptions(baseUrl: _baseUrl));

  late TransferDatabase db;
  late TransferLocalStoreImpl store;
  late SendTransfer sendTransfer;
  late ResumePendingTransfers resume;

  setUpAll(() async {
    try {
      await admin.get<void>('/admin/chaos');
    } on DioException {
      fail(
        'Serveur simulé injoignable sur $_baseUrl : cd mock_server && npm start',
      );
    }
  });

  setUp(() async {
    await admin.post<void>('/admin/reset');

    db = TransferDatabase(NativeDatabase.memory());
    store = TransferLocalStoreImpl(db);
    const clock = SystemClock();
    final sender = TransferSender(
      repository: TransferRepositoryImpl(TransferApi.create(_baseUrl)),
      store: store,
      clock: clock,
    );
    sendTransfer = SendTransfer(store: store, sender: sender, clock: clock);
    resume = ResumePendingTransfers(store: store, sender: sender);
  });

  tearDown(() => db.close());

  Future<void> setChaos(String mode) => admin.post<void>(
    '/admin/chaos',
    data: {'mode': mode, 'count': 1}, // ne casse que la prochaine requête
  );

  Future<List<dynamic>> transfersOnServer() async {
    final response = await admin.get<Map<String, dynamic>>('/transfers');
    return response.data!['items'] as List<dynamic>;
  }

  Matcher okWithStatus(TransferStatus status) =>
      isA<Ok<Transfer>>().having((ok) => ok.value.status, 'status', status);

  test('drop : transfert créé mais réponse perdue → la reprise le retrouve, '
      'sans doublon', () async {
    final key = const UuidIdGenerator().newId();
    await setChaos('drop');

    expect(
      await sendTransfer(_request, key),
      okWithStatus(TransferStatus.unknownOutcome),
    );

    await resume();

    expect((await store.findByKey(key))!.status, TransferStatus.submitted);
    final onServer = await transfersOnServer();
    expect(onServer, hasLength(1));
    expect(onServer.single['idempotencyKey'], key);
  });

  test('down : coupure avant traitement → la reprise renvoie le POST avec la '
      'même clé, toujours un seul transfert', () async {
    final key = const UuidIdGenerator().newId();
    await setChaos('down');

    expect(
      await sendTransfer(_request, key),
      okWithStatus(TransferStatus.unknownOutcome),
    );
    expect(await transfersOnServer(), isEmpty); // rien n'a été créé

    await resume();

    final saved = (await store.findByKey(key))!;
    expect(saved.status, TransferStatus.submitted);
    final onServer = await transfersOnServer();
    expect(onServer, hasLength(1));
    expect(onServer.single['idempotencyKey'], key);
    expect(onServer.single['id'], saved.serverId);
  });
}
