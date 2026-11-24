import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/resume_pending_transfers.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/sync_history.dart';
import 'package:test_ebanking/features/transfer/presentation/auto_resume.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

import '../domain/fakes.dart';

TransferHistory historyWith(TransferStatus status) => TransferHistory(
  transfers: [localTransfer('k1', status)],
  lastSyncedAt: null,
);

class _CountingResume implements ResumePendingTransfers {
  var calls = 0;

  @override
  Future<void> call() async => calls++;
}

class _NoopSync implements SyncHistory {
  @override
  Future<Result<void>> call() async => const Ok(null);
}

void main() {
  test('toutes les 30 s tant qu\'un transfert reste incertain, puis '
      's\'arrête', () {
    fakeAsync((async) {
      var passes = 0;
      final autoResume = AutoResume(() async => passes++);

      autoResume.onHistoryChanged(historyWith(TransferStatus.unknownOutcome));
      async.elapse(const Duration(seconds: 65));
      expect(passes, 2);

      autoResume.onHistoryChanged(historyWith(TransferStatus.submitted));
      async.elapse(const Duration(minutes: 5));
      expect(passes, 2);

      autoResume.dispose();
    });
  });

  test('un déclencheur pendant un passage le rejoint au lieu d\'en lancer '
      'un second', () async {
    final gate = Completer<void>();
    var passes = 0;
    final autoResume = AutoResume(() {
      passes++;
      return gate.future;
    });

    final first = autoResume.run();
    final second = autoResume.run();
    gate.complete();
    await Future.wait([first, second]);
    expect(passes, 1);

    await autoResume.run(); // le passage fini, un nouveau peut partir
    expect(passes, 2);
  });

  test('au démarrage, puis au retour du réseau (pas à sa perte)', () async {
    final resume = _CountingResume();
    final network = StreamController<bool>();
    addTearDown(network.close);
    final container = ProviderContainer.test(
      overrides: [
        resumePendingTransfersProvider.overrideWithValue(resume),
        syncHistoryProvider.overrideWithValue(_NoopSync()),
        isOnlineProvider.overrideWith((ref) => network.stream),
        historyProvider.overrideWith(
          (ref) => Stream.value(historyWith(TransferStatus.paid)),
        ),
      ],
    );
    // Comme App : on écoute le provider pour le garder actif.
    container.listen(autoResumeProvider, (_, _) {});
    await pumpEventQueue();
    expect(resume.calls, 1);

    network.add(true);
    await pumpEventQueue();
    network.add(false);
    await pumpEventQueue();
    expect(resume.calls, 1);

    network.add(true);
    await pumpEventQueue();
    expect(resume.calls, 2);
  });
}
