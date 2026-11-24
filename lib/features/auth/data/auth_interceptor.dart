import 'package:dio/dio.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';

/// Ajoute le jeton d'accès à chaque requête. Sur un 401, renouvelle la session
/// en silence et rejoue la requête une fois : quand le jeton expire en pleine
/// utilisation, le client ne voit rien et n'est pas déconnecté.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.accessToken,
    required this.refresh,
  });

  /// Le client qui porte cet intercepteur, pour rejouer la requête.
  final Dio dio;
  final String? Function() accessToken;

  /// Renvoie un nouveau jeton d'accès, ou l'échec du renouvellement.
  final Future<Result<String>> Function() refresh;

  static const _retried = 'auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retried] == true) {
      return handler.next(err);
    }

    switch (await refresh()) {
      case Ok():
        // Rejouée telle quelle (même corps, même Idempotency-Key) : un 401 est
        // renvoyé avant tout traitement, rien n'a été créé. onRequest y met
        // le nouveau jeton.
        options.extra[_retried] = true;
        try {
          handler.resolve(await dio.fetch<dynamic>(options));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      case Err(failure: UnauthorizedFailure()):
        // Session finie : le 401 remonte.
        handler.next(err);
      case Err():
        // Renouvellement impossible (réseau) : pour l'appelant, c'est une
        // coupure, pas un refus.
        handler.next(
          DioException.connectionError(
            requestOptions: options,
            reason: 'Renouvellement de session impossible',
          ),
        );
    }
  }
}
