import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/push/domain/usecases/push_subscription.dart';

import '../../push_fakes.dart';

void main() {
  late List<String> log;
  late FakePushMessaging fcm;
  late FakePushRegistry registry;
  late PushSubscription subscription;

  setUp(() {
    log = [];
    fcm = FakePushMessaging(log);
    registry = FakePushRegistry(log);
    subscription = PushSubscription(messaging: fcm, registry: registry);
  });

  test('ouverture de session → inscription FCM, puis identifiant envoyé au '
      'serveur', () async {
    await subscription.enable();
    await pumpEventQueue();

    expect(log, ['fcm.register', 'api.registerDevice fid-1']);
  });

  test('autorisation refusée → aucune inscription', () async {
    fcm.permissionGranted = false;

    await subscription.enable();
    await pumpEventQueue();

    expect(log, isEmpty);
  });

  test('identifiant renouvelé par FCM → renvoyé au serveur', () async {
    await subscription.enable();
    await pumpEventQueue();
    log.clear();

    fcm.renew('fid-2');
    await pumpEventQueue();

    expect(log, ['api.registerDevice fid-2']);
  });

  test('serveur injoignable à l\'ouverture → inscription refaite après la '
      'synchro suivante, et une seule fois', () async {
    registry.reachable = false;
    await subscription.enable();
    await pumpEventQueue();
    registry.reachable = true;
    log.clear();

    await subscription.retryIfNeeded();
    await subscription.retryIfNeeded(); // déjà inscrit : rien

    expect(log, ['api.registerDevice fid-1']);
  });

  test('inscription réussie, ou pas d\'abonnement → retryIfNeeded ne fait '
      'rien', () async {
    await subscription.retryIfNeeded(); // jamais activé
    await subscription.enable();
    await pumpEventQueue();
    log.clear();

    await subscription.retryIfNeeded();

    expect(log, isEmpty);
  });

  test('déconnexion → désinscription FCM, et plus aucun renvoi au '
      'serveur', () async {
    await subscription.enable();
    await pumpEventQueue();
    log.clear();

    await subscription.disable();
    fcm.renew('fid-2');
    await pumpEventQueue();

    expect(log, ['fcm.unregister']);
  });
}
