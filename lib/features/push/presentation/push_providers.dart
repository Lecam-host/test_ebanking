import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/features/push/domain/ports/push_messaging.dart';
import 'package:test_ebanking/features/push/domain/ports/push_registry.dart';
import 'package:test_ebanking/features/push/domain/usecases/push_subscription.dart';

// Ports déclarés sans implémentation, branchés dans lib/app/providers.dart.

const _wiredInApp = 'Branché dans lib/app/providers.dart';

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final pushRegistryProvider = Provider<PushRegistry>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final pushSubscriptionProvider = Provider<PushSubscription>(
  (ref) => PushSubscription(
    messaging: ref.watch(pushMessagingProvider),
    registry: ref.watch(pushRegistryProvider),
  ),
);
