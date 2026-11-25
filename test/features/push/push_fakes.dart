// Faux écrits à la main pour les tests des notifications.
import 'dart:async';

import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/push/domain/entities/push_message.dart';
import 'package:test_ebanking/features/push/domain/ports/push_messaging.dart';
import 'package:test_ebanking/features/push/domain/ports/push_registry.dart';

/// FCM simulé : register() émet l'identifiant [fid] sur [registrations].
class FakePushMessaging implements PushMessaging {
  FakePushMessaging(this.log);

  final List<String> log;
  var permissionGranted = true;
  var fid = 'fid-1';
  final _registrations = StreamController<String>.broadcast();

  /// Simule un renouvellement d'identifiant par FCM.
  void renew(String newFid) => _registrations.add(newFid);

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Stream<String> get registrations => _registrations.stream;

  @override
  Future<void> register() async {
    log.add('fcm.register');
    _registrations.add(fid);
  }

  @override
  Future<void> unregister() async => log.add('fcm.unregister');

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<String> get openedTransfers => const Stream.empty();

  @override
  Future<String?> initialTransfer() async => null;
}

class FakePushRegistry implements PushRegistry {
  FakePushRegistry(this.log);

  final List<String> log;

  /// false : le serveur est injoignable (app démarrée hors ligne).
  var reachable = true;

  @override
  Future<Result<void>> register(String installationId) async {
    log.add('api.registerDevice $installationId');
    return reachable ? const Ok(null) : const Err(NetworkFailure());
  }
}
