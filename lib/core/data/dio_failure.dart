import 'package:dio/dio.dart';
import 'package:test_ebanking/core/failure.dart';

/// Traduit une erreur Dio en [Failure], selon ce qu'on sait du sort de la
/// requête. Dans le doute, on choisit toujours un échec « résultat inconnu »
/// (réseau, délai, serveur), jamais un refus : un refus est définitif, alors
/// qu'un résultat inconnu sera vérifié par la reprise.
Failure failureFromDioException(DioException exception) =>
    switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(),
      DioExceptionType.badResponse => _failureFromResponse(exception.response),
      // Connexion impossible ou coupée (y compris en pleine réponse), ou
      // erreur inattendue : on ne sait pas si la requête a été traitée.
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown => const NetworkFailure(),
    };

Failure _failureFromResponse(Response<dynamic>? response) =>
    switch (response?.statusCode) {
      401 => const UnauthorizedFailure(),
      final int status when status >= 400 && status < 500 => RejectedFailure(
        _errorCode(response!.data),
      ),
      // 5xx, ou code inattendu : le serveur a peut-être traité la requête.
      _ => const ServerFailure(),
    };

/// Champ `error` du corps JSON (ex. `validation_error`).
String _errorCode(Object? body) => switch (body) {
  {'error': final String code} => code,
  _ => 'http_error',
};
