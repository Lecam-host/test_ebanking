import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/push/presentation/push_activation.dart';
import 'package:test_ebanking/features/push/presentation/push_providers.dart';

import '../../auth/auth_fakes.dart';
import '../push_fakes.dart';

void main() {
  test('le téléphone s\'inscrit aux notifications dès que la session est '
      'ouverte, pas avant', () async {
    final log = <String>[];
    final auth = FixedAuthNotifier(AuthStatus.restoring);
    final container = ProviderContainer.test(
      overrides: [
        pushMessagingProvider.overrideWithValue(FakePushMessaging(log)),
        pushRegistryProvider.overrideWithValue(FakePushRegistry(log)),
        authNotifierProvider.overrideWith(() => auth),
      ],
    );
    // Comme App : on écoute le provider pour le garder actif.
    container.listen(pushActivationProvider, (_, _) {});
    await pumpEventQueue();
    expect(log, isEmpty);

    auth.set(AuthStatus.locked);
    await pumpEventQueue();

    expect(log, ['fcm.register', 'api.registerDevice fid-1']);
  });
}
