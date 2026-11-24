import 'dart:async';

import 'package:test_ebanking/features/push/domain/ports/push_messaging.dart';
import 'package:test_ebanking/features/push/domain/ports/push_registry.dart';

/// Abonnement de ce téléphone aux notifications du client connecté.
class PushSubscription {
  PushSubscription({required this._messaging, required this._registry});

  final PushMessaging _messaging;
  final PushRegistry _registry;
  StreamSubscription<String>? _registrations;

  /// À chaque ouverture de session. Sans risque de doublon : le serveur garde
  /// une seule inscription par identifiant. Un échec (hors ligne) sera
  /// rattrapé au prochain démarrage.
  Future<void> enable() async {
    // Refusée : pas de notification, mais l'historique se met à jour à chaque
    // retour dans l'app.
    if (!await _messaging.requestPermission()) return;
    // On écoute AVANT de demander l'inscription, pour ne pas rater
    // l'identifiant ; les renouvellements suivants passent par le même chemin.
    _registrations ??= _messaging.registrations.listen(_registry.register);
    await _messaging.register();
  }

  /// Déconnexion : le téléphone se désinscrit de FCM. Le serveur, lui,
  /// n'envoie déjà plus rien à une session révoquée.
  Future<void> disable() async {
    await _registrations?.cancel();
    _registrations = null;
    await _messaging.unregister();
  }
}
