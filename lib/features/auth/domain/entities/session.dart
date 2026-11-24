/// Jetons rendus par le serveur à la connexion et à chaque renouvellement.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  /// Court (quelques minutes) : ouvre l'accès aux API.
  final String accessToken;

  /// Long (30 jours) et à usage unique : sert à obtenir de nouveaux jetons.
  final String refreshToken;
}

/// Session du client sur ce téléphone.
class Session {
  const Session({
    required this.phone,
    required this.refreshToken,
    this.accessToken,
  });

  final String phone;
  final String refreshToken;

  /// Gardé en mémoire seulement ; null après un redémarrage, jusqu'au premier
  /// renouvellement.
  final String? accessToken;
}
