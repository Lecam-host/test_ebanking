import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/sync_history.dart';

import '../fakes.dart';

void main() {
  late List<String> log;
  late FakeTransferRepository server;
  late FakeTransferLocalStore store;
  late FakeClock clock;
  late SyncHistory syncHistory;

  setUp(() {
    log = [];
    server = FakeTransferRepository(log);
    store = FakeTransferLocalStore(log);
    clock = FakeClock();
    syncHistory = SyncHistory(repository: server, store: store, clock: clock);
  });

  test('enregistre l\'historique du serveur, son solde et l\'heure de '
      'synchro', () async {
    server.created['k1'] = serverTransfer('k1', validRequest);
    server.created['k2'] = serverTransfer('k2', validRequest);
    server.balance = 950000;
    clock.current = DateTime(2026, 11, 23, 12);

    final result = await syncHistory();

    expect(result, isA<Ok<void>>());
    expect(store.byKey.keys, unorderedEquals(['k1', 'k2']));
    expect(store.balance, 950000);
    expect(store.lastSyncedAt, DateTime(2026, 11, 23, 12));
  });

  test('échec réseau → cache, solde et date de synchro inchangés', () async {
    server.historyFailure = const NetworkFailure();

    final result = await syncHistory();

    expect(result, isA<Err<void>>());
    expect(log, ['api.fetchHistory']);
    expect(store.lastSyncedAt, isNull);
    expect(store.balance, isNull);
  });
}
