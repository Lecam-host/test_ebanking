import 'package:dio/dio.dart';
import 'package:test_ebanking/core/data/dio_failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/data/auth_api.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';
import 'package:test_ebanking/features/auth/domain/ports/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final AuthApi _api;

  @override
  Future<Result<void>> requestOtp(String phone) =>
      _guard(() => _api.requestOtp(phone));

  @override
  Future<Result<AuthTokens>> signIn(String phone, String code) =>
      _guard(() async => _tokens(await _api.signIn(phone, code)));

  @override
  Future<Result<AuthTokens>> refresh(String refreshToken) =>
      _guard(() async => _tokens(await _api.refresh(refreshToken)));

  @override
  Future<Result<void>> signOut(String refreshToken) =>
      _guard(() => _api.signOut(refreshToken));

  static AuthTokens _tokens(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on DioException catch (e) {
      return Err(failureFromDioException(e));
    }
  }
}
