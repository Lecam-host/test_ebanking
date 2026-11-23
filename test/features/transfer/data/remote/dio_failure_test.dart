import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/features/transfer/data/remote/dio_failure.dart';

void main() {
  DioException dioError(DioExceptionType type, {int? status, Object? body}) {
    final options = RequestOptions(path: '/transfers');
    return DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response(requestOptions: options, statusCode: status, data: body),
    );
  }

  test('délais dépassés → TimeoutFailure', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      expect(
        failureFromDioException(dioError(type)),
        isA<TimeoutFailure>(),
        reason: '$type',
      );
    }
  });

  test('connexion impossible ou coupée → NetworkFailure', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.unknown,
      DioExceptionType.cancel,
      DioExceptionType.badCertificate,
    ]) {
      expect(
        failureFromDioException(dioError(type)),
        isA<NetworkFailure>(),
        reason: '$type',
      );
    }
  });

  test('5xx → ServerFailure', () {
    for (final status in [500, 502, 503]) {
      expect(
        failureFromDioException(
          dioError(DioExceptionType.badResponse, status: status),
        ),
        isA<ServerFailure>(),
        reason: '$status',
      );
    }
  });

  test('4xx → RejectedFailure avec le champ error du serveur', () {
    final failure = failureFromDioException(
      dioError(
        DioExceptionType.badResponse,
        status: 422,
        body: {'error': 'idempotency_key_reused', 'message': '...'},
      ),
    );

    expect(
      failure,
      isA<RejectedFailure>().having(
        (f) => f.code,
        'code',
        'idempotency_key_reused',
      ),
    );
  });

  test('4xx sans corps JSON → RejectedFailure avec un code générique', () {
    final failure = failureFromDioException(
      dioError(DioExceptionType.badResponse, status: 400, body: 'Bad Request'),
    );

    expect(
      failure,
      isA<RejectedFailure>().having((f) => f.code, 'code', 'http_error'),
    );
  });

  test('401 → UnauthorizedFailure', () {
    expect(
      failureFromDioException(
        dioError(DioExceptionType.badResponse, status: 401),
      ),
      isA<UnauthorizedFailure>(),
    );
  });
}
