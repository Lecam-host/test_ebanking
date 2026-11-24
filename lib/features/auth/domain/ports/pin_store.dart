/// Garde le code secret (PIN) sur le téléphone, en stockage sécurisé.
/// Implémenté dans data/.
///
/// Le PIN est vérifié sur le téléphone, et non par le serveur, parce que
/// l'historique doit s'ouvrir en mode avion. Seule une empreinte salée est
/// gardée, jamais le PIN lui-même.
abstract interface class PinStore {
  Future<bool> hasPin();

  Future<void> save(String pin);

  Future<bool> matches(String pin);

  /// Essais ratés, gardés sur le disque : tuer l'app ne les remet pas à zéro.
  Future<int> failedAttempts();

  Future<void> setFailedAttempts(int count);

  Future<void> clear();
}
