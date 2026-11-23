import 'package:test_ebanking/core/result.dart';

/// Inscrit le téléphone auprès du serveur pour recevoir les notifications de
/// changement de statut des transferts.
/// Interface seulement ; l'implémentation viendra avec l'étape FCM.
abstract interface class PushRegistry {
  Future<Result<void>> register(String deviceToken);

  Future<Result<void>> unregister();
}
