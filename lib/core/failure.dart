/// Échecs attendus, classés selon ce que l'app doit en faire.
///
/// Pour l'envoi d'un transfert, la distinction est vitale : après une
/// [NetworkFailure], une [TimeoutFailure] ou une [ServerFailure], le serveur a
/// peut-être créé le transfert (résultat inconnu). Après une
/// [RejectedFailure], on sait qu'il l'a refusé.
sealed class Failure {
  const Failure();
}

/// Saisie invalide, détectée avant tout appel réseau.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.errors);

  /// Un message lisible par problème, pour tout afficher d'un coup.
  final List<String> errors;
}

/// Pas de réponse exploitable : réseau coupé, connexion impossible ou interrompue.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Le serveur n'a pas répondu dans le délai imparti.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// Erreur du serveur (5xx).
final class ServerFailure extends Failure {
  const ServerFailure();
}

/// Refus métier (4xx) : le serveur a lu la requête et l'a refusée.
final class RejectedFailure extends Failure {
  const RejectedFailure(this.code);

  /// Champ `error` de la réponse du serveur, par exemple `validation_error`.
  final String code;
}

/// Session absente ou expirée (401).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}
