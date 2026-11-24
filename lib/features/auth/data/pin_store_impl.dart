import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_ebanking/features/auth/domain/ports/pin_store.dart';

/// PIN gardé sous forme d'empreinte salée (SHA-256), dans
/// flutter_secure_storage.
///
/// Le hachage n'est pas la vraie protection : 10 000 codes se testent vite,
/// quel que soit l'algorithme. Ce qui protège, c'est la clé matérielle du
/// Keystore (il faut forcer le téléphone pour lire ce stockage) et la limite
/// de 5 essais suivie d'un effacement complet.
class PinStoreImpl implements PinStore {
  PinStoreImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';
  static const _failedKey = 'pin_failed_attempts';

  @override
  Future<bool> hasPin() async => await _storage.read(key: _hashKey) != null;

  @override
  Future<void> save(String pin) async {
    final random = Random.secure();
    final salt = base64Encode(List.generate(16, (_) => random.nextInt(256)));
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: _hash(salt, pin));
  }

  @override
  Future<bool> matches(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final hash = await _storage.read(key: _hashKey);
    return salt != null && hash == _hash(salt, pin);
  }

  @override
  Future<int> failedAttempts() async =>
      int.tryParse(await _storage.read(key: _failedKey) ?? '') ?? 0;

  @override
  Future<void> setFailedAttempts(int count) =>
      _storage.write(key: _failedKey, value: '$count');

  @override
  Future<void> clear() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _failedKey);
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
