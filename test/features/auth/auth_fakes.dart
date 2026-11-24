// Faux écrits à la main pour les tests de l'auth.
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';
import 'package:test_ebanking/features/auth/domain/ports/auth_repository.dart';
import 'package:test_ebanking/features/auth/domain/ports/pin_store.dart';
import 'package:test_ebanking/features/auth/domain/ports/session_store.dart';
import 'package:test_ebanking/features/auth/domain/usecases/pin_lock.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';

/// Serveur d'auth simulé : délivre access-1/refresh-1, puis access-2/refresh-2…
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.log);

  final List<String> log;
  var _issued = 0;

  /// Quand il est renseigné, renvoyé à la place de nouveaux jetons.
  Failure? refreshFailure;
  Failure? signOutFailure;

  @override
  Future<Result<void>> requestOtp(String phone) async {
    log.add('api.requestOtp $phone');
    return const Ok(null);
  }

  @override
  Future<Result<AuthTokens>> signIn(String phone, String code) async {
    log.add('api.signIn $phone');
    return Ok(_issue());
  }

  @override
  Future<Result<AuthTokens>> refresh(String refreshToken) async {
    log.add('api.refresh $refreshToken');
    if (refreshFailure case final failure?) return Err(failure);
    return Ok(_issue());
  }

  @override
  Future<Result<void>> signOut(String refreshToken) async {
    log.add('api.signOut $refreshToken');
    if (signOutFailure case final failure?) return Err(failure);
    return const Ok(null);
  }

  AuthTokens _issue() {
    _issued++;
    return AuthTokens(
      accessToken: 'access-$_issued',
      refreshToken: 'refresh-$_issued',
    );
  }
}

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore(this.log);

  final List<String> log;
  Session? stored;

  @override
  Future<Session?> read() async => stored == null
      ? null
      : Session(phone: stored!.phone, refreshToken: stored!.refreshToken);

  @override
  Future<void> save(Session session) async {
    log.add('session.save ${session.refreshToken}');
    stored = session;
  }

  @override
  Future<void> clear() async {
    log.add('session.clear');
    stored = null;
  }
}

class InMemoryPinStore implements PinStore {
  InMemoryPinStore(this.log);

  final List<String> log;
  String? pin;
  var failed = 0;

  @override
  Future<bool> hasPin() async => pin != null;

  @override
  Future<void> save(String pin) async => this.pin = pin;

  @override
  Future<bool> matches(String pin) async => pin == this.pin;

  @override
  Future<int> failedAttempts() async => failed;

  @override
  Future<void> setFailedAttempts(int count) async => failed = count;

  @override
  Future<void> clear() async {
    log.add('pin.clear');
    pin = null;
    failed = 0;
  }
}

/// Code secret aux réponses choisies par le test (présentation).
class FakePinLock implements PinLock {
  PinCheck answer = const PinAccepted();
  final checked = <String>[];

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<Result<void>> create(String pin) async => const Ok(null);

  @override
  Future<PinCheck> check(String pin) async {
    checked.add(pin);
    return answer;
  }
}

/// État de session imposé par le test ; note les déconnexions demandées.
class FixedAuthNotifier extends AuthNotifier {
  FixedAuthNotifier(this.status);

  final AuthStatus status;
  final signOutMessages = <String?>[];

  @override
  AuthState build() => AuthState(status);

  void set(AuthStatus status) => state = AuthState(status);

  final otpRequests = <String>[];

  @override
  Future<Result<void>> requestOtp(String phone) async {
    otpRequests.add(phone);
    return const Ok(null);
  }

  @override
  Future<void> signOut({String? message}) async {
    signOutMessages.add(message);
    state = AuthState(AuthStatus.signedOut, message: message);
  }
}
