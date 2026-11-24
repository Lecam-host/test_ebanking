import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:test_ebanking/features/push/domain/entities/push_message.dart';
import 'package:test_ebanking/features/push/domain/ports/push_messaging.dart';

/// Notifications via Firebase Cloud Messaging.
///
/// firebase_messaging 17 inscrit le téléphone par son identifiant
/// d'installation (FID, `register()` / `onRegistered`) ; l'ancien jeton
/// (`getToken`) est déprécié.
///
/// App en arrière-plan ou fermée : le système affiche lui-même la
/// notification (elle porte un bloc `notification`), aucun code ne tourne.
/// App ouverte : FCM n'affiche rien, l'app reçoit le message et le montre.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Stream<String> get registrations => _messaging.onRegistered;

  @override
  Future<void> register() async {
    try {
      await _messaging.register();
    } on FirebaseException {
      // Hors ligne ou sans services Google : on réessaiera au prochain
      // démarrage.
    }
  }

  @override
  Future<void> unregister() async {
    try {
      await _messaging.unregister();
    } on FirebaseException {
      // Hors ligne : le serveur n'envoie de toute façon plus rien à une
      // session révoquée.
    }
  }

  @override
  Stream<PushMessage> get foregroundMessages => FirebaseMessaging.onMessage
      .map(_toPushMessage)
      .where((message) => message != null)
      .cast<PushMessage>();

  @override
  Stream<String> get openedTransfers => FirebaseMessaging.onMessageOpenedApp
      .map(_transferKey)
      .where((key) => key != null)
      .cast<String>();

  @override
  Future<String?> initialTransfer() async =>
      _transferKey(await _messaging.getInitialMessage());

  static String? _transferKey(RemoteMessage? message) =>
      message?.data['transferKey'] as String?;

  static PushMessage? _toPushMessage(RemoteMessage message) {
    final key = _transferKey(message);
    if (key == null) return null;
    return PushMessage(
      transferKey: key,
      title: message.notification?.title ?? 'Transfert mis à jour',
    );
  }
}
