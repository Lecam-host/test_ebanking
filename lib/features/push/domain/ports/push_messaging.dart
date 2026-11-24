import 'package:test_ebanking/features/push/domain/entities/push_message.dart';

/// Les notifications côté téléphone (FCM). Implémenté dans data/.
abstract interface class PushMessaging {
  /// Demande l'autorisation d'afficher des notifications (Android 13+, iOS).
  Future<bool> requestPermission();

  /// Identifiant FCM de ce téléphone (FID), émis à l'inscription puis à
  /// chaque renouvellement : c'est lui que le serveur vise.
  Stream<String> get registrations;

  /// Inscrit le téléphone auprès de FCM ; l'identifiant arrive par
  /// [registrations].
  Future<void> register();

  /// Désinscrit le téléphone : plus rien n'arrive sur l'ancien identifiant.
  Future<void> unregister();

  /// Notifications reçues pendant que l'app est ouverte.
  Stream<PushMessage> get foregroundMessages;

  /// Transferts dont la notification a été touchée, app en arrière-plan.
  Stream<String> get openedTransfers;

  /// Transfert dont la notification a lancé l'app, alors fermée.
  Future<String?> initialTransfer();
}
