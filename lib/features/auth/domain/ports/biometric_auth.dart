/// Vérification par empreinte (ou visage), faite par le système du téléphone.
/// Implémenté dans data/.
///
/// Comme le code secret, c'est une preuve locale : elle dit que le
/// propriétaire du téléphone est là, le serveur ne la voit pas.
abstract interface class BiometricAuth {
  /// Le téléphone sait vérifier une empreinte et le client en a enregistré
  /// une. Sinon, l'app propose directement le code secret.
  Future<bool> isAvailable();

  /// Ouvre la fenêtre du système. `false` si l'empreinte est refusée, si le
  /// client annule ou si la vérification est impossible : l'app propose
  /// alors le code secret.
  Future<bool> authenticate(String reason);
}
