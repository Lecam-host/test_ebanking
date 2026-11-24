import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:test_ebanking/core/data/dio_client.dart';

void main() {
  test('les routes d\'auth ne sont jamais journalisées (code SMS, jetons)', () {
    for (final path in ['/auth/otp', '/auth/token', '/auth/refresh']) {
      expect(isLoggable(RequestOptions(path: path)), isFalse, reason: path);
    }
    expect(isLoggable(RequestOptions(path: '/transfers')), isTrue);
  });

  test('le journal ne montre pas les en-têtes : Authorization porte le '
      'jeton', () {
    final logger = httpLogger();

    expect(logger.requestHeader, isFalse);
    expect(logger.responseHeader, isFalse);
  });

  test('en debug, chaque client porte le journal', () {
    final dio = createDio('http://localhost:3000');

    expect(dio.interceptors.whereType<PrettyDioLogger>(), hasLength(1));
  });
}
