/// Résultat de la vérification du code secret (PIN).
sealed class PinCheck {
  const PinCheck();
}

final class PinAccepted extends PinCheck {
  const PinAccepted();
}

final class PinRejected extends PinCheck {
  const PinRejected(this.remainingAttempts);

  final int remainingAttempts;
}

/// Trop d'essais ratés : la session doit être fermée et tout effacé.
final class PinBlocked extends PinCheck {
  const PinBlocked();
}
