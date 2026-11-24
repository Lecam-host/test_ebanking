import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/domain/usecases/pin_lock.dart';

import '../../auth_fakes.dart';

void main() {
  late InMemoryPinStore store;
  late PinLock pinLock;

  setUp(() {
    store = InMemoryPinStore([]);
    pinLock = PinLock(store: store);
  });

  test('le code secret comporte exactement 4 chiffres', () async {
    for (final pin in ['123', '12345', '12a4']) {
      expect(
        await pinLock.create(pin),
        isA<Err<void>>().having(
          (e) => e.failure,
          'failure',
          isA<ValidationFailure>(),
        ),
        reason: pin,
      );
    }
    expect(await pinLock.create('1234'), isA<Ok<void>>());
    expect(await pinLock.hasPin(), isTrue);
  });

  test('bon code → accepté, et le compteur d\'essais repart à zéro', () async {
    await pinLock.create('1234');
    await pinLock.check('0000');

    expect(await pinLock.check('1234'), isA<PinAccepted>());
    expect(store.failed, 0);
  });

  test(
    '5 mauvais codes → bloqué au 5e, avec le compte à rebours avant',
    () async {
      await pinLock.create('1234');

      final checks = [for (var i = 0; i < 5; i++) await pinLock.check('0000')];

      expect(checks.take(4).map((c) => (c as PinRejected).remainingAttempts), [
        4,
        3,
        2,
        1,
      ]);
      expect(checks.last, isA<PinBlocked>());
    },
  );

  test('les essais ratés survivent à un redémarrage de l\'app', () async {
    await pinLock.create('1234');
    for (var i = 0; i < 4; i++) {
      await pinLock.check('0000');
    }

    // Nouvelle instance, même stockage : comme après avoir tué l'app.
    final afterRestart = PinLock(store: store);

    expect(await afterRestart.check('0000'), isA<PinBlocked>());
  });
}
