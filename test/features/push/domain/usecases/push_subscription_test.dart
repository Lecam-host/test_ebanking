import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/push/domain/usecases/push_subscription.dart';

import '../../push_fakes.dart';

void main() {
  late List<String> log;
  late FakePushMessaging fcm;
  late PushSubscription subscription;

  setUp(() {
    log = [];
    fcm = FakePushMessaging(log);
    subscription = PushSubscription(
      messaging: fcm,
      registry: FakePushRegistry(log),
    );
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
