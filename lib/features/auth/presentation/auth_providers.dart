import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/features/auth/domain/ports/auth_repository.dart';
import 'package:test_ebanking/features/auth/domain/ports/biometric_auth.dart';
import 'package:test_ebanking/features/auth/domain/ports/pin_store.dart';
import 'package:test_ebanking/features/auth/domain/ports/session_store.dart';
import 'package:test_ebanking/features/auth/domain/usecases/pin_lock.dart';
import 'package:test_ebanking/features/auth/domain/usecases/session_manager.dart';
import 'package:test_ebanking/features/auth/domain/usecases/sign_out.dart';
import 'package:test_ebanking/features/push/presentation/push_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

// Ports déclarés sans implémentation, branchés dans lib/app/providers.dart
// (même principe que pour les transferts).

const _wiredInApp = 'Branché dans lib/app/providers.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final pinStoreProvider = Provider<PinStore>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => throw UnimplementedError(_wiredInApp),
);

/// Empreinte possible sur ce téléphone ? Sinon, le code secret directement.
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricAuthProvider).isAvailable(),
);

/// Une seule instance pour toute l'app : elle tient le jeton d'accès en
/// mémoire, et l'intercepteur HTTP s'en sert aussi.
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(
    repository: ref.watch(authRepositoryProvider),
    store: ref.watch(sessionStoreProvider),
  ),
);

final pinLockProvider = Provider<PinLock>(
  (ref) => PinLock(store: ref.watch(pinStoreProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(
    session: ref.watch(sessionManagerProvider),
    pins: ref.watch(pinStoreProvider),
    transfers: ref.watch(transferLocalStoreProvider),
    push: ref.watch(pushSubscriptionProvider),
  ),
);
