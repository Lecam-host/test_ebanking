import 'package:test_ebanking/features/auth/domain/ports/pin_store.dart';
import 'package:test_ebanking/features/auth/domain/usecases/session_manager.dart';
import 'package:test_ebanking/features/push/domain/usecases/push_subscription.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';

/// Déconnexion : rien de sensible ne doit rester sur le téléphone, et plus
/// aucune notification de ce compte ne doit y arriver.
class SignOut {
  SignOut({
    required this._session,
    required this._pins,
    required this._transfers,
    required this._push,
  });

  final SessionManager _session;
  final PinStore _pins;
  final TransferLocalStore _transfers;
  final PushSubscription _push;

  Future<void> call() async {
    // D'abord tout ce qui est sur le téléphone : même hors ligne, l'effacement
    // est complet. Puis le réseau : jeton FCM invalidé, session révoquée (le
    // serveur cesse alors d'envoyer des notifications à ce téléphone).
    await _transfers.clear();
    await _pins.clear();
    await _push.disable();
    await _session.signOut();
  }
}
