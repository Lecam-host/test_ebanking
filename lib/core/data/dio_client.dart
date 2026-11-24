import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Client HTTP partagé par les couches données.
///
/// Délais choisis pour la 3G instable : 10 s pour établir la connexion, 20 s
/// sans recevoir de données. Au-delà, le résultat est « inconnu » et la reprise
/// prend le relais, sans risque de doublon.
Dio createDio(String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  // Journal lisible des appels, en debug seulement : rien dans un APK release.
  if (kDebugMode) dio.interceptors.add(httpLogger());
  return dio;
}

/// Journal des appels HTTP, sans secrets même en debug :
/// - pas d'en-têtes de requête : `Authorization` porte le jeton d'accès (la
///   clé d'idempotence, elle, apparaît dans la console du serveur) ;
/// - rien des routes d'auth : elles transportent le code SMS et les jetons.
PrettyDioLogger httpLogger() => PrettyDioLogger(
  requestBody: true,
  filter: (options, _) => isLoggable(options),
);

bool isLoggable(RequestOptions options) => !options.path.startsWith('/auth/');
