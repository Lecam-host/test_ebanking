import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';

/// Authentification auprès du serveur. Implémenté dans data/.
abstract interface class AuthRepository {
  /// Fait envoyer un code par SMS au numéro [phone].
  Future<Result<void>> requestOtp(String phone);

  /// Échange le code SMS contre des jetons.
  Future<Result<AuthTokens>> signIn(String phone, String code);

  /// Échange le jeton de renouvellement (à usage unique) contre de nouveaux
  /// jetons.
  Future<Result<AuthTokens>> refresh(String refreshToken);

  /// Révoque la session côté serveur.
  Future<Result<void>> signOut(String refreshToken);
}
