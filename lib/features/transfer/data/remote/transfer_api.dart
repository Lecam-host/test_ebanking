import 'package:dio/dio.dart';

/// Appels HTTP au serveur des transferts (contrat : mock_server/server.js).
///
/// Renvoie le JSON brut et laisse remonter les DioException : la conversion
/// en entités et en Failure se fait dans TransferRepositoryImpl.
///
/// Le client Dio reçu porte l'intercepteur d'authentification (lib/app/).
class TransferApi {
  TransferApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> postTransfer(
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/transfers',
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return response.data!;
  }

  /// null si le serveur ne connaît pas la clé (404) : le transfert n'a jamais
  /// été créé.
  Future<Map<String, dynamic>?> findByIdempotencyKey(
    String idempotencyKey,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/transfers',
        queryParameters: {'idempotencyKey': idempotencyKey},
      );
      return response.data!;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// `{ items, serverTime, balance }` : les transferts du serveur, du plus
  /// récent au plus ancien, et le solde du client.
  Future<Map<String, dynamic>> fetchHistory() async {
    final response = await _dio.get<Map<String, dynamic>>('/transfers');
    return response.data!;
  }

  Future<Map<String, dynamic>> getTransfer(String serverId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transfers/$serverId',
    );
    return response.data!;
  }
}
