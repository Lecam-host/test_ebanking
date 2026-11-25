import 'dart:async';

import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/push/domain/ports/push_messaging.dart';
import 'package:test_ebanking/features/push/domain/ports/push_registry.dart';

/// Abonnement de ce téléphone aux notifications du client connecté.
class PushSubscription {
  PushSubscription({required this._messaging, required this._registry});

  final PushMessaging _messaging;
  final PushRegistry _registry;
  StreamSubscription<String>? _registrations;

  /// Dernier identifiant reçu de FCM, et s'il est bien inscrit sur le serveur.
  String? _fid;
  var _sentToServer = false;

  /// À chaque ouverture de session. Sans risque de doublon : le serveur garde
  /// une seule inscription par identifiant. Un échec (hors ligne) est
  /// rattrapé par [retryIfNeeded].
  Future<void> enable() async {
    // Refusée : pas de notification, mais l'historique se met à jour à chaque
    // retour dans l'app.
    if (!await _messaging.requestPermission()) return;
    // On écoute AVANT de demander l'inscription, pour ne pas rater
    // l'identifiant ; les renouvellements suivants passent par le même chemin.
    _registrations ??= _messaging.registrations.listen(_onRegistered);
    await _messaging.register();
  }

  /// Appelé après chaque synchro réussie, qui prouve que le serveur répond :
  /// si l'inscription avait échoué (app démarrée hors ligne, serveur
  /// injoignable), on la refait. Sinon, rien.
  Future<void> retryIfNeeded() async {
    // Pas d'abonnement : déconnecté, ou notifications refusées.
    if (_registrations == null) return;
    final fid = _fid;
    // FCM n'avait pas encore donné d'identifiant : on le redemande.
    if (fid == null) return _messaging.register();
    if (!_sentToServer) await _sendToServer(fid);
  }

  /// Déconnexion : le téléphone se désinscrit de FCM. Le serveur, lui,
  /// n'envoie déjà plus rien à une session révoquée.
  Future<void> disable() async {
    await _registrations?.cancel();
    _registrations = null;
    _fid = null;
    _sentToServer = false;
    await _messaging.unregister();
  }

  Future<void> _onRegistered(String fid) {
    _fid = fid;
    _sentToServer = false;
    return _sendToServer(fid);
  }

  Future<void> _sendToServer(String fid) async {
    _sentToServer = await _registry.register(fid) is Ok;
  }
}
