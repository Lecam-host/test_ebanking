import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:test_ebanking/core/config.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/data/remote/transfer_api.dart';
import 'package:test_ebanking/features/transfer/data/transfer_local_store_impl.dart';
import 'package:test_ebanking/features/transfer/data/transfer_repository_impl.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// Seul endroit qui assemble les couches : branche les implémentations de
/// data/ (et du système) sur ce que la présentation attend.
List<Override> appOverrides(TransferDatabase database) => [
  transferRepositoryProvider.overrideWithValue(
    TransferRepositoryImpl(TransferApi.create(AppConfig.apiBaseUrl)),
  ),
  transferLocalStoreProvider.overrideWithValue(
    TransferLocalStoreImpl(database),
  ),
  isOnlineProvider.overrideWith((ref) => _isOnline(Connectivity())),
];

/// L'état du réseau maintenant, puis à chaque changement.
Stream<bool> _isOnline(Connectivity connectivity) async* {
  bool online(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
}
