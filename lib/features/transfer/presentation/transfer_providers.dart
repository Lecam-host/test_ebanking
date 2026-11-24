import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/clock.dart';
import 'package:test_ebanking/core/id_generator.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_repository.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/resume_pending_transfers.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/send_transfer.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/sync_history.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/transfer_sender.dart';
import 'package:test_ebanking/features/transfer/domain/usecases/watch_history.dart';

// Ce dont la présentation a besoin, déclaré SANS implémentation : lib/app/ les
// branche au démarrage (ProviderScope overrides) et les tests y branchent des
// faux. La présentation ne connaît ainsi que le domaine, jamais data/.

const _wiredInApp = 'Branché dans lib/app/providers.dart';

final transferRepositoryProvider = Provider<TransferRepository>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final transferLocalStoreProvider = Provider<TransferLocalStore>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

/// true quand le téléphone a une connexion réseau. Ce n'est qu'un indice (un
/// Wi-Fi peut être sans Internet) : il déclenche une reprise et affiche un
/// bandeau, il ne décide jamais du sort d'un transfert.
final isOnlineProvider = StreamProvider<bool>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidIdGenerator(),
);

/// Heure courante, réémise chaque minute pour que « il y a X min » avance
/// tout seul.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => clock.now());
});

// Les cas d'usage, construits à partir des ports ci-dessus.

final transferSenderProvider = Provider<TransferSender>(
  (ref) => TransferSender(
    repository: ref.watch(transferRepositoryProvider),
    store: ref.watch(transferLocalStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

final sendTransferProvider = Provider<SendTransfer>(
  (ref) => SendTransfer(
    store: ref.watch(transferLocalStoreProvider),
    sender: ref.watch(transferSenderProvider),
    clock: ref.watch(clockProvider),
  ),
);

final resumePendingTransfersProvider = Provider<ResumePendingTransfers>(
  (ref) => ResumePendingTransfers(
    store: ref.watch(transferLocalStoreProvider),
    sender: ref.watch(transferSenderProvider),
  ),
);

final syncHistoryProvider = Provider<SyncHistory>(
  (ref) => SyncHistory(
    repository: ref.watch(transferRepositoryProvider),
    store: ref.watch(transferLocalStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Historique lu sur le téléphone : il s'affiche sans réseau.
final historyProvider = StreamProvider<TransferHistory>(
  (ref) => WatchHistory(store: ref.watch(transferLocalStoreProvider))(),
);
