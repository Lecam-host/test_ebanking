import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/domain/ports/pin_store.dart';

/// Code secret de 4 chiffres, comme les apps de paiement de la région :
/// demandé à l'ouverture de l'app et à chaque envoi.
class PinLock {
  PinLock({required this._store});

  final PinStore _store;

  /// 10 000 codes possibles, 5 essais : un voleur a 0,05 % de chances de
  /// tomber juste avant que tout soit effacé.
  static const maxAttempts = 5;
  static final _fourDigits = RegExp(r'^\d{4}$');

  Future<bool> hasPin() => _store.hasPin();

  Future<Result<void>> create(String pin) async {
    if (!_fourDigits.hasMatch(pin)) {
      return const Err(
        ValidationFailure(['Le code secret comporte 4 chiffres.']),
      );
    }
    await _store.save(pin);
    await _store.setFailedAttempts(0);
    return const Ok(null);
  }

  Future<PinCheck> check(String pin) async {
    if (await _store.matches(pin)) {
      await _store.setFailedAttempts(0);
      return const PinAccepted();
    }
    final failed = await _store.failedAttempts() + 1;
    await _store.setFailedAttempts(failed);
    return failed >= maxAttempts
        ? const PinBlocked()
        : PinRejected(maxAttempts - failed);
  }
}
