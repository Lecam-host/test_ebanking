import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

enum AuthStatus {
  /// Lecture de la session gardée, au démarrage.
  restoring,

  /// Pas de session : connexion par code SMS.
  signedOut,

  /// Connecté, mais le code secret reste à créer.
  needsPin,

  /// Session présente, code secret demandé (démarrage, retour d'arrière-plan).
  locked,

  unlocked;

  bool get isSignedIn => this == locked || this == unlocked;
}

class AuthState {
  const AuthState(this.status, {this.message});

  final AuthStatus status;

  /// Explication à afficher après une déconnexion forcée.
  final String? message;
}

class AuthNotifier extends Notifier<AuthState> {
  /// Au-delà, l'app se verrouille quand elle revient au premier plan.
  static const lockAfter = Duration(minutes: 1);

  DateTime? _hiddenAt;

  @override
  AuthState build() {
    final session = ref.watch(sessionManagerProvider);
    // Session révoquée (téléphone déclaré volé, jeton copié) : tout effacer.
    final subscription = session.sessionEnded.listen(
      (_) => signOut(
        message: 'Votre session a été fermée par sécurité. Reconnectez-vous.',
      ),
    );
    ref.onDispose(subscription.cancel);
    _restore();
    return const AuthState(AuthStatus.restoring);
  }

  /// Sans réseau : seule la session gardée sur le téléphone est relue.
  Future<void> _restore() async {
    final hasSession = await ref.read(sessionManagerProvider).restore();
    final hasPin = await ref.read(pinLockProvider).hasPin();
    if (!ref.mounted) return;
    state = AuthState(
      !hasSession
          ? AuthStatus.signedOut
          : hasPin
          ? AuthStatus.locked
          : AuthStatus.needsPin,
    );
  }

  Future<Result<void>> requestOtp(String phone) =>
      ref.read(sessionManagerProvider).requestOtp(phone);

  Future<Result<void>> signIn(String phone, String code) async {
    final result = await ref.read(sessionManagerProvider).signIn(phone, code);
    if (result is Ok && ref.mounted) {
      state = const AuthState(AuthStatus.needsPin);
    }
    return result;
  }

  Future<Result<void>> createPin(String pin) async {
    final result = await ref.read(pinLockProvider).create(pin);
    if (result is Ok && ref.mounted) {
      state = const AuthState(AuthStatus.unlocked);
    }
    return result;
  }

  Future<PinCheck> unlock(String pin) async {
    final check = await ref.read(pinLockProvider).check(pin);
    switch (check) {
      case PinAccepted():
        if (ref.mounted) state = const AuthState(AuthStatus.unlocked);
      case PinRejected():
        break;
      case PinBlocked():
        await signOut(message: tooManyAttemptsMessage);
    }
    return check;
  }

  static const tooManyAttemptsMessage =
      'Trop d\'essais : pour votre sécurité, reconnectez-vous avec un code SMS.';

  /// Efface tout ce qui est sensible sur le téléphone, puis révoque la session.
  Future<void> signOut({String? message}) async {
    await ref.read(signOutProvider)();
    if (ref.mounted) {
      state = AuthState(AuthStatus.signedOut, message: message);
    }
  }

  void onHidden() => _hiddenAt = ref.read(clockProvider).now();

  void onShown() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (state.status != AuthStatus.unlocked || hiddenAt == null) return;
    final away = ref.read(clockProvider).now().difference(hiddenAt);
    if (away >= lockAfter) state = const AuthState(AuthStatus.locked);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
