import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/presentation/send_transfer_notifier.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// Relance la réconciliation des transferts incertains.
class AutoResume {
  AutoResume(this._pass, {this.interval = const Duration(seconds: 30)});

  /// Un passage : reprise des transferts incertains, puis historique.
  final Future<void> Function() _pass;
  final Duration interval;

  Future<void>? _running;
  Timer? _timer;

  /// Un seul passage à la fois : un déclencheur qui arrive pendant un passage
  /// le rejoint au lieu d'en lancer un second.
  Future<void> run() =>
      _running ??= _pass().whenComplete(() => _running = null);

  /// À chaque changement de l'historique local : la minuterie ne tourne que
  /// tant qu'il reste un transfert incertain.
  void onHistoryChanged(TransferHistory history) {
    final hasPending = history.transfers.any(
      (transfer) => transfer.status.needsReconciliation,
    );
    if (hasPending) {
      _timer ??= Timer.periodic(interval, (_) => run());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() => _timer?.cancel();
}

/// Reprise automatique, gardée active par App pendant toute la vie de l'app.
final autoResumeProvider = Provider<AutoResume>((ref) {
  final resume = ref.watch(resumePendingTransfersProvider);
  final sync = ref.watch(syncHistoryProvider);
  final autoResume = AutoResume(() async {
    await resume();
    // Un échec (hors ligne) laisse l'historique local tel quel.
    await sync();
  });
  ref.onDispose(autoResume.dispose);

  // 1. Au démarrage, dès que la session est relue (même verrouillée : ce sont
  //    les transferts du client, et le serveur exige son jeton).
  ref.listen(authNotifierProvider.select((auth) => auth.status.isSignedIn), (
    wasSignedIn,
    isSignedIn,
  ) {
    if (isSignedIn && wasSignedIn != true) autoResume.run();
  }, fireImmediately: true);

  // 2. Au retour du réseau. Simple déclencheur : c'est le serveur qui tranche.
  ref.listen(isOnlineProvider, (previous, next) {
    if (previous?.value == false && next.value == true) autoResume.run();
  });

  // 3. Toutes les 30 s tant qu'un transfert reste incertain.
  ref.listen(historyProvider, (_, next) {
    final history = next.value;
    if (history != null) autoResume.onHistoryChanged(history);
  }, fireImmediately: true);

  // 4. Après un envoi accepté par le serveur : le solde affiché se met à jour
  //    tout de suite, sans attendre un autre déclencheur.
  ref.listen(sendTransferNotifierProvider.select((form) => form.result), (
    _,
    result,
  ) {
    if (result case Ok(:final value) when !value.status.needsReconciliation) {
      autoResume.run();
    }
  });

  return autoResume;
});
