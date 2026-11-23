import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Clé de chiffrement de la base : 32 octets aléatoires créés au premier
/// lancement, puis gardés par le système (Keystore Android, Keychain iOS)
/// via flutter_secure_storage. La clé ne quitte jamais le téléphone.
class DatabaseKey {
  DatabaseKey(this._storage);

  final FlutterSecureStorage _storage;

  static const _storageKey = 'transfer_database_key';

  /// La clé en hexadécimal (64 caractères), créée si elle n'existe pas encore.
  Future<String> loadOrCreate() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null) return existing;

    final random = Random.secure();
    final key = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: _storageKey, value: key);
    return key;
  }
}
