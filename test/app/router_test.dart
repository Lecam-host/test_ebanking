import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/app/router.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';

void main() {
  String? redirect(AuthStatus status, String location) =>
      authRedirect(status, Uri.parse(location));

  test('sans session → connexion ; session à finir → écran de l\'étape', () {
    expect(redirect(AuthStatus.signedOut, '/login'), isNull);
    expect(redirect(AuthStatus.needsPin, '/login'), '/pin');
    expect(redirect(AuthStatus.restoring, '/start'), isNull);
  });

  test('verrouillé → déverrouillage, puis retour à la page demandée', () {
    final toUnlock = redirect(AuthStatus.locked, '/transfers/k1');
    expect(toUnlock, '/unlock?from=%2Ftransfers%2Fk1');

    expect(redirect(AuthStatus.unlocked, toUnlock!), '/transfers/k1');
  });

  test('la page demandée survit au démarrage puis au verrouillage', () {
    final atStart = redirect(AuthStatus.restoring, '/send')!;
    final toUnlock = redirect(AuthStatus.locked, atStart)!;

    expect(redirect(AuthStatus.unlocked, toUnlock), '/send');
  });

  test('déverrouillé : les pages de l\'app restent, celles de connexion '
      'renvoient à l\'historique', () {
    expect(redirect(AuthStatus.unlocked, '/send'), isNull);
    expect(redirect(AuthStatus.unlocked, '/login'), '/transfers');
  });
}
