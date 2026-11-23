import 'package:dio/dio.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/data/remote/dio_failure.dart';
import 'package:test_ebanking/features/transfer/data/remote/transfer_api.dart';
import 'package:test_ebanking/features/transfer/data/remote/transfer_json.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/domain/ports/transfer_repository.dart';

class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._api);

  final TransferApi _api;

  @override
  Future<Result<Transfer>> submit(
    TransferRequest request,
    String idempotencyKey,
  ) => _guard(() async {
    final json = await _api.postTransfer(
      transferRequestToJson(request),
      idempotencyKey,
    );
    return transferFromJson(json);
  });

  @override
  Future<Result<Transfer?>> findByIdempotencyKey(String idempotencyKey) =>
      _guard(() async {
        final json = await _api.findByIdempotencyKey(idempotencyKey);
        return json == null ? null : transferFromJson(json);
      });

  @override
  Future<Result<List<Transfer>>> fetchHistory() => _guard(() async {
    final items = await _api.fetchTransfers();
    return items.map(transferFromJson).toList();
  });

  @override
  Future<Result<Transfer>> getById(String serverId) =>
      _guard(() async => transferFromJson(await _api.getTransfer(serverId)));

  /// Les erreurs réseau deviennent des [Failure]. Les autres exceptions
  /// (réponse illisible) sont des bugs de contrat et remontent telles
  /// quelles : comme le transfert a été enregistré avant l'appel, il reste à
  /// réconcilier, sans risque de double envoi.
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on DioException catch (e) {
      return Err(failureFromDioException(e));
    }
  }
}
