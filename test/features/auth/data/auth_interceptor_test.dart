import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/data/auth_interceptor.dart';

/// Faux réseau : rend les réponses prévues, dans l'ordre, et note les requêtes.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final List<(int, Map<String, dynamic>)> responses;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter network;
  late String token;
  late int refreshes;
  late Result<String> Function() refreshAnswer;
  late Dio dio;

  setUp(() {
    token = 'old';
    refreshes = 0;
    refreshAnswer = () {
      token = 'new';
      return const Ok('new');
    };
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        accessToken: () => token,
        refresh: () async {
          refreshes++;
          return refreshAnswer();
        },
      ),
    );
  });

  void respond(List<(int, Map<String, dynamic>)> responses) {
    network = _FakeAdapter(responses);
    dio.httpClientAdapter = network;
  }

  Future<Response<dynamic>> postTransfer() => dio.post<dynamic>(
    '/transfers',
    data: {'amount': 25000},
    options: Options(headers: {'Idempotency-Key': 'k1'}),
  );

  test('chaque requête porte le jeton d\'accès', () async {
    respond([(200, {})]);

    await dio.get<dynamic>('/transfers');

    expect(network.requests.single.headers['Authorization'], 'Bearer old');
  });

  test('jeton expiré → renouvelé en silence, puis requête rejouée avec le '
      'même corps et la même Idempotency-Key', () async {
    respond([
      (401, {'error': 'token_expired'}),
      (201, {'id': 'tr_1'}),
    ]);

    final response = await postTransfer();

    expect(response.statusCode, 201);
    expect(refreshes, 1);
    final replay = network.requests.last;
    expect(replay.headers['Authorization'], 'Bearer new');
    expect(replay.headers['Idempotency-Key'], 'k1');
    expect(replay.data, {'amount': 25000});
  });

  test('session refusée → le 401 remonte, sans rejeu', () async {
    refreshAnswer = () => const Err(UnauthorizedFailure());
    respond([
      (401, {'error': 'session_revoked'}),
    ]);

    await expectLater(
      postTransfer(),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(network.requests, hasLength(1));
  });

  test(
    'renouvellement impossible faute de réseau → vu comme une coupure',
    () async {
      refreshAnswer = () => const Err(NetworkFailure());
      respond([
        (401, {'error': 'token_expired'}),
      ]);

      await expectLater(
        postTransfer(),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    },
  );

  test('un seul rejeu : un second 401 remonte au lieu de boucler', () async {
    respond([
      (401, {'error': 'token_expired'}),
      (401, {'error': 'token_expired'}),
    ]);

    await expectLater(postTransfer(), throwsA(isA<DioException>()));
    expect(refreshes, 1);
    expect(network.requests, hasLength(2));
  });
}
