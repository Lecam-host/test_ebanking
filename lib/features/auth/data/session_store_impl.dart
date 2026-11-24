import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';
import 'package:test_ebanking/features/auth/domain/ports/session_store.dart';

/// Session gardée dans flutter_secure_storage (Keystore Android, Keychain
/// iOS) : chiffrée par une clé que le système ne laisse pas sortir.
class SessionStoreImpl implements SessionStore {
  SessionStoreImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'session';

  @override
  Future<Session?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Session(
      phone: json['phone'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  @override
  Future<void> save(Session session) => _storage.write(
    key: _key,
    // Jamais le jeton d'accès : il ne vit qu'en mémoire.
    value: jsonEncode({
      'phone': session.phone,
      'refreshToken': session.refreshToken,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
