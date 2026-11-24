import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';
import 'package:test_ebanking/features/auth/domain/usecases/session_manager.dart';

import '../../auth_fakes.dart';

void main() {
  late List<String> log;
  late FakeAuthRepository server;
  late InMemorySessionStore store;
  late SessionManager session;

  setUp(() {
    log = [];
    server = FakeAuthRepository(log);
    store = InMemorySessionStore(log);
    session = SessionManager(repository: server, store: store);
  });

  Future<void> signedIn() async {
    await session.signIn('0700000001', '123456');
    log.clear();
  }

  test(
    'restore relit la session gardée, sans jeton d\'accès ni réseau',
    () async {
      expect(await session.restore(), isFalse);

      store.stored = const Session(phone: '0700000001', refreshToken: 'r');

      expect(await session.restore(), isTrue);
      expect(session.accessToken, isNull);
      expect(log, isEmpty);
    },
  );

  test('saisie invalide → ValidationFailure, aucun appel au serveur', () async {
    expect(
      await session.requestOtp('123'),
      isA<Err<void>>().having(
        (e) => e.failure,
        'failure',
        isA<ValidationFailure>(),
      ),
    );
    expect(
      await session.signIn('0700000001', '12'),
      isA<Err<void>>().having(
        (e) => e.failure,
        'failure',
        isA<ValidationFailure>(),
      ),
    );
    expect(log, isEmpty);
  });

  test('connexion : jeton de renouvellement gardé, jeton d\'accès en '
      'mémoire', () async {
    final result = await session.signIn('0700000001', '123456');

    expect(result, isA<Ok<void>>());
    expect(store.stored!.refreshToken, 'refresh-1');
    expect(session.accessToken, 'access-1');
  });

  test('renouvellement : le nouveau jeton de renouvellement est gardé '
      'AVANT d\'être utilisé', () async {
    await signedIn();

    final result = await session.refresh();

    expect(
      result,
      isA<Ok<String>>().having((ok) => ok.value, 'value', 'access-2'),
    );
    expect(log, ['api.refresh refresh-1', 'session.save refresh-2']);
    expect(session.accessToken, 'access-2');
  });

  test('plusieurs renouvellements simultanés → un seul échange : le jeton '
      'est à usage unique', () async {
    await signedIn();

    await Future.wait([
      session.refresh(),
      session.refresh(),
      session.refresh(),
    ]);

    expect(log.where((line) => line.startsWith('api.refresh')), hasLength(1));
  });

  test(
    'renouvellement refusé par le serveur → session finie, signalée',
    () async {
      await signedIn();
      server.refreshFailure = const UnauthorizedFailure();
      final ended = expectLater(session.sessionEnded, emits(anything));

      final result = await session.refresh();

      expect(
        result,
        isA<Err<String>>().having(
          (e) => e.failure,
          'failure',
          isA<UnauthorizedFailure>(),
        ),
      );
      await ended;
    },
  );

  test(
    'renouvellement impossible faute de réseau → la session reste',
    () async {
      await signedIn();
      server.refreshFailure = const NetworkFailure();
      var ended = false;
      final subscription = session.sessionEnded.listen((_) => ended = true);
      addTearDown(subscription.cancel);

      final result = await session.refresh();
      await pumpEventQueue();

      expect(
        result,
        isA<Err<String>>().having(
          (e) => e.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      );
      expect(ended, isFalse);
      expect(store.stored, isNotNull);
    },
  );

  test('déconnexion : le téléphone est vidé d\'abord, même si le serveur est '
      'injoignable', () async {
    await signedIn();
    server.signOutFailure = const NetworkFailure();

    await session.signOut();

    expect(log, ['session.clear', 'api.signOut refresh-1']);
    expect(store.stored, isNull);
    expect(session.accessToken, isNull);
  });
}
