import 'package:test_ebanking/features/auth/domain/ports/pin_store.dart';
import 'package:test_ebanking/features/auth/domain/usecases/session_manager.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_local_store.dart';

/// Déconnexion : rien de sensible ne doit rester sur le téléphone.
class SignOut {
  SignOut({
    required this._session,
    required this._pins,
    required this._transfers,
  });

  final SessionManager _session;
  final PinStore _pins;
  final TransferLocalStore _transfers;

  Future<void> call() async {
    // D'abord tout ce qui est sur le téléphone : même hors ligne, l'effacement
    // est complet. La révocation côté serveur vient en dernier.
    await _transfers.clear();
    await _pins.clear();
    await _session.signOut();
  }
}
