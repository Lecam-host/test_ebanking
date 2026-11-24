import 'package:test_ebanking/features/auth/domain/entities/session.dart';

/// Garde la session sur le téléphone, en stockage sécurisé. Implémenté dans
/// data/.
///
/// Seuls le numéro et le jeton de renouvellement sont gardés : le jeton
/// d'accès ne touche jamais le disque.
abstract interface class SessionStore {
  /// La session gardée, sans jeton d'accès ; null si aucune.
  Future<Session?> read();

  Future<void> save(Session session);

  Future<void> clear();
}
