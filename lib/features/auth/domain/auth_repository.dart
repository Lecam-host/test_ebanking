import 'package:test_ebanking/core/result.dart';

/// Authentification auprès du serveur : code OTP reçu par SMS, puis PIN.
/// Interface seulement ; l'implémentation viendra avec l'étape auth.
abstract interface class AuthRepository {
  /// Demande l'envoi d'un code OTP par SMS au numéro [phone].
  Future<Result<void>> requestOtp(String phone);

  /// Renvoie un jeton de session si le code est correct.
  Future<Result<String>> verifyOtp({required String phone, required String otp});

  /// Vérifié par le serveur, jamais sur le téléphone : un PIN de quelques
  /// chiffres se casse en quelques secondes sur un téléphone compromis, alors
  /// que le serveur peut limiter les essais.
  Future<Result<String>> verifyPin({required String phone, required String pin});
}
