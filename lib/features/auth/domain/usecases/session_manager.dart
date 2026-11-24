import 'dart:async';

import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';
import 'package:test_ebanking/features/auth/domain/ports/auth_repository.dart';
import 'package:test_ebanking/features/auth/domain/ports/session_store.dart';

/// Tient la session du client : connexion, renouvellement silencieux, fin.
class SessionManager {
  SessionManager({required this._repository, required this._store});

  final AuthRepository _repository;
  final SessionStore _store;

  static final _ivorianPhone = RegExp(r'^\d{10}$');
  static final _smsCode = RegExp(r'^\d{6}$');

  Session? _session;
  Future<Result<String>>? _refreshing;
  final _ended = StreamController<void>.broadcast();

  /// Émis quand le serveur refuse définitivement la session (révoquée par le
  /// support, expirée, jeton copié) : l'app doit alors tout effacer.
  Stream<void> get sessionEnded => _ended.stream;

  String? get accessToken => _session?.accessToken;

  /// Au démarrage, sans réseau : relit la session gardée sur le téléphone. Le
  /// jeton d'accès sera obtenu au premier appel au serveur.
  Future<bool> restore() async {
    _session = await _store.read();
    return _session != null;
  }

  Future<Result<void>> requestOtp(String phone) async {
    if (!_ivorianPhone.hasMatch(phone)) {
      return const Err(
        ValidationFailure(['Le numéro doit comporter exactement 10 chiffres.']),
      );
    }
    return _repository.requestOtp(phone);
  }

  Future<Result<void>> signIn(String phone, String code) async {
    if (!_smsCode.hasMatch(code)) {
      return const Err(
        ValidationFailure(['Le code reçu par SMS comporte 6 chiffres.']),
      );
    }
    switch (await _repository.signIn(phone, code)) {
      case Ok(value: final tokens):
        await _keep(phone, tokens);
        return const Ok(null);
      case Err(:final failure):
        return Err(failure);
    }
  }

  /// Renouvelle le jeton d'accès et le renvoie. Un seul renouvellement à la
  /// fois : le jeton de renouvellement est à usage unique, deux échanges
  /// simultanés feraient révoquer la session.
  Future<Result<String>> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<Result<String>> _refresh() async {
    final current = _session;
    if (current == null) return const Err(UnauthorizedFailure());

    switch (await _repository.refresh(current.refreshToken)) {
      case Ok(value: final tokens):
        await _keep(current.phone, tokens);
        return Ok(tokens.accessToken);
      case Err(failure: UnauthorizedFailure() || RejectedFailure()):
        // Refus définitif du serveur : la session est finie.
        _ended.add(null);
        return const Err(UnauthorizedFailure());
      case Err(:final failure):
        // Réseau ou serveur : on ne conclut rien, la session reste.
        return Err(failure);
    }
  }

  /// Oublie la session sur le téléphone d'abord (même hors ligne), puis
  /// demande au serveur de la révoquer.
  Future<void> signOut() async {
    final current = _session;
    _session = null;
    await _store.clear();
    if (current != null) await _repository.signOut(current.refreshToken);
  }

  Future<void> _keep(String phone, AuthTokens tokens) async {
    final session = Session(
      phone: phone,
      refreshToken: tokens.refreshToken,
      accessToken: tokens.accessToken,
    );
    // Enregistré avant d'être utilisé : l'ancien jeton de renouvellement est
    // déjà consommé côté serveur.
    await _store.save(session);
    _session = session;
  }
}
