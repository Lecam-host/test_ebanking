import 'package:dio/dio.dart';

/// Client HTTP partagé par les couches données.
///
/// Délais choisis pour la 3G instable : 10 s pour établir la connexion, 20 s
/// sans recevoir de données. Au-delà, le résultat est « inconnu » et la reprise
/// prend le relais, sans risque de doublon.
Dio createDio(String baseUrl) => Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ),
);
