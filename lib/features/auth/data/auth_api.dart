import 'package:dio/dio.dart';

/// Appels HTTP d'authentification (contrat : mock_server/auth.js).
///
/// Son client Dio n'a PAS l'intercepteur d'authentification : renouveler la
/// session ne doit jamais déclencher un autre renouvellement.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<void> requestOtp(String phone) =>
      _dio.post<void>('/auth/otp', data: {'phone': phone});

  Future<Map<String, dynamic>> signIn(String phone, String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/token',
      data: {'phone': phone, 'code': code},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return response.data!;
  }

  Future<void> signOut(String refreshToken) =>
      _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken});
}
