import 'package:test_ebanking/core/result.dart';

/// Inscrit ce téléphone auprès du serveur pour recevoir les notifications de
/// changement de statut. Implémenté dans data/.
///
/// Pas de désinscription explicite : le serveur rattache l'identifiant à la
/// session, et une session révoquée (déconnexion, vol) ne reçoit plus rien.
abstract interface class PushRegistry {
  /// [installationId] : l'identifiant FCM de ce téléphone (FID).
  Future<Result<void>> register(String installationId);
}
