import 'package:dio/dio.dart';
import 'package:test_ebanking/core/data/dio_failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/push/domain/ports/push_registry.dart';

/// `POST /devices`, avec le client authentifié : le serveur rattache
/// l'identifiant à la session qui l'envoie.
class PushRegistryImpl implements PushRegistry {
  PushRegistryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<void>> register(String installationId) async {
    try {
      await _dio.post<void>('/devices', data: {'fid': installationId});
      return const Ok(null);
    } on DioException catch (e) {
      return Err(failureFromDioException(e));
    }
  }
}
