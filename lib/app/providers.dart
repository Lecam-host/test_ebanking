import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:test_ebanking/core/config.dart';
import 'package:test_ebanking/core/data/dio_client.dart';
import 'package:test_ebanking/features/auth/data/auth_api.dart';
import 'package:test_ebanking/features/auth/data/auth_interceptor.dart';
import 'package:test_ebanking/features/auth/data/auth_repository_impl.dart';
import 'package:test_ebanking/features/auth/data/local_biometric_auth.dart';
import 'package:test_ebanking/features/auth/data/pin_store_impl.dart';
import 'package:test_ebanking/features/auth/data/session_store_impl.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/push/data/firebase_push_messaging.dart';
import 'package:test_ebanking/features/push/data/push_registry_impl.dart';
import 'package:test_ebanking/features/push/presentation/push_providers.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/data/remote/transfer_api.dart';
import 'package:test_ebanking/features/transfer/data/transfer_local_store_impl.dart';
import 'package:test_ebanking/features/transfer/data/transfer_repository_impl.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// Seul endroit qui assemble les couches : branche les implémentations de
/// data/ (et du système) sur ce que la présentation attend.
List<Override> appOverrides(TransferDatabase database) {
  const secureStorage = FlutterSecureStorage();
  return [
    // Le client de l'auth n'a pas d'intercepteur (voir AuthApi).
    authRepositoryProvider.overrideWithValue(
      AuthRepositoryImpl(AuthApi(createDio(AppConfig.apiBaseUrl))),
    ),
    sessionStoreProvider.overrideWithValue(SessionStoreImpl(secureStorage)),
    pinStoreProvider.overrideWithValue(PinStoreImpl(secureStorage)),
    biometricAuthProvider.overrideWithValue(
      LocalBiometricAuth(LocalAuthentication()),
    ),
    transferRepositoryProvider.overrideWith(
      (ref) => TransferRepositoryImpl(TransferApi(ref.watch(_apiDioProvider))),
    ),
    transferLocalStoreProvider.overrideWithValue(
      TransferLocalStoreImpl(database),
    ),
    pushRegistryProvider.overrideWith(
      (ref) => PushRegistryImpl(ref.watch(_apiDioProvider)),
    ),
    pushMessagingProvider.overrideWithValue(
      FirebasePushMessaging(FirebaseMessaging.instance),
    ),
    isOnlineProvider.overrideWith((ref) => _isOnline(Connectivity())),
  ];
}

/// Client des API protégées (transferts, inscription aux notifications) :
/// chaque requête porte le jeton d'accès, renouvelé en silence quand il expire.
final _apiDioProvider = Provider<Dio>((ref) {
  final session = ref.watch(sessionManagerProvider);
  final dio = createDio(AppConfig.apiBaseUrl);
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      accessToken: () => session.accessToken,
      refresh: session.refresh,
    ),
  );
  return dio;
});

/// L'état du réseau maintenant, puis à chaque changement.
Stream<bool> _isOnline(Connectivity connectivity) async* {
  bool online(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
}
