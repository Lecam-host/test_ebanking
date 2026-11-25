import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:test_ebanking/features/auth/domain/ports/biometric_auth.dart';

/// Empreinte via local_auth 3.
///
/// `biometricOnly` : pas de repli sur le code de verrouillage du téléphone,
/// qui est un autre secret que le code secret de l'app. Le repli, c'est
/// l'app qui le propose (son propre code secret).
class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      // `canCheckBiometrics` ne dit que « le matériel existe » : on veut
      // aussi qu'une empreinte soit enregistrée.
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on LocalAuthException {
      // Annulée, trop d'essais (blocage du système), plus d'empreinte : le
      // code secret prend le relais.
      return false;
    } on PlatformException {
      return false;
    }
  }
}
