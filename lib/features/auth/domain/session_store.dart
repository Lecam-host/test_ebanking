/// Garde le jeton de session sur le téléphone, en stockage sécurisé.
/// Interface seulement ; l'implémentation viendra avec l'étape auth.
abstract interface class SessionStore {
  Future<String?> readToken();

  Future<void> saveToken(String token);

  Future<void> clear();
}
