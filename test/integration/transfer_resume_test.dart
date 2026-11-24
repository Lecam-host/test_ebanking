// Tests de bout en bout contre le serveur simulé (mock_server/), avec la vraie
// couche data : Dio (et son intercepteur d'auth) et Drift (base en mémoire).
//
// Lancer d'abord : cd mock_server && npm start
// Puis : flutter test --tags integration --run-skipped
@Tags(['integration'])
library;

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/data/dio_client.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/id_generator.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/data/auth_api.dart';
import 'package:test_ebanking/features/auth/data/auth_interceptor.dart';
import 'package:test_ebanking/features/auth/data/auth_repository_impl.dart';
import 'package:test_ebanking/features/auth/domain/usecases/session_manager.dart';
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

import '../features/auth/auth_fakes.dart';

const _baseUrl = 'http://localhost:3000';
const _phone = '0700000001';

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
  late SessionManager session;
  late Dio api;
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

    // Connexion comme dans l'app ; le « SMS » est lu via /admin/otp.
    session = SessionManager(
      repository: AuthRepositoryImpl(AuthApi(createDio(_baseUrl))),
      store: InMemorySessionStore([]),
    );
    await session.requestOtp(_phone);
    final sms = await admin.get<Map<String, dynamic>>(
      '/admin/otp',
      queryParameters: {'phone': _phone},
    );
    expect(
      await session.signIn(_phone, sms.data!['code'] as String),
      isA<Ok<void>>(),
    );

    // Même branchement que lib/app/providers.dart.
    api = createDio(_baseUrl);
    api.interceptors.add(
      AuthInterceptor(
        dio: api,
        accessToken: () => session.accessToken,
        refresh: session.refresh,
      ),
    );

    db = TransferDatabase(NativeDatabase.memory());
    store = TransferLocalStoreImpl(db);
    const clock = SystemClock();
    final sender = TransferSender(
      repository: TransferRepositoryImpl(TransferApi(api)),
      store: store,
      clock: clock,
    );
    sendTransfer = SendTransfer(store: store, sender: sender, clock: clock);
    resume = ResumePendingTransfers(store: store, sender: sender);
  });

  tearDown(() => db.close());

  String newKey() => const UuidIdGenerator().newId();

  Future<void> setChaos(String mode) => admin.post<void>(
    '/admin/chaos',
    data: {'mode': mode, 'count': 1}, // ne casse que la prochaine requête
  );

  Future<List<dynamic>> transfersOnServer() async {
    final response = await api.get<Map<String, dynamic>>('/transfers');
    return response.data!['items'] as List<dynamic>;
  }

  Matcher okWithStatus(TransferStatus status) =>
      isA<Ok<Transfer>>().having((ok) => ok.value.status, 'status', status);

  test('drop : transfert créé mais réponse perdue → la reprise le retrouve, '
      'sans doublon', () async {
    final key = newKey();
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
    final key = newKey();
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

  test('session expirée en pleine utilisation → renouvelée en silence, le '
      'transfert part une seule fois', () async {
    await admin.post<void>('/admin/sessions/expire');

    expect(
      await sendTransfer(_request, newKey()),
      okWithStatus(TransferStatus.submitted),
    );
    expect(await transfersOnServer(), hasLength(1));
  });

  test('session révoquée (téléphone déclaré volé) → rien ne part, et la fin '
      'de session est signalée à l\'app', () async {
    final ended = expectLater(session.sessionEnded, emits(anything));
    await admin.post<void>('/admin/sessions/revoke', data: {'phone': _phone});
    final key = newKey();

    final result = await sendTransfer(_request, key);

    expect(
      result,
      isA<Err<Transfer>>().having(
        (err) => err.failure,
        'failure',
        isA<UnauthorizedFailure>(),
      ),
    );
    await ended;
    expect(
      (await store.findByKey(key))!.status,
      TransferStatus.pendingSubmission,
    );
  });
}
