import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/features/auth/domain/usecases/session_manager.dart';
import 'package:test_ebanking/features/auth/domain/usecases/sign_out.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

import '../../../transfer/domain/fakes.dart';
import '../../auth_fakes.dart';

void main() {
  test('déconnexion : historique, code secret et session effacés du '
      'téléphone, puis session révoquée — même hors ligne', () async {
    final log = <String>[];
    final server = FakeAuthRepository(log)
      ..signOutFailure = const NetworkFailure();
    final sessionStore = InMemorySessionStore(log);
    final pins = InMemoryPinStore(log)..pin = '1234';
    final transfers = FakeTransferLocalStore(log);
    transfers.byKey['k1'] = localTransfer('k1', TransferStatus.paid);
    final session = SessionManager(repository: server, store: sessionStore);
    await session.signIn('0700000001', '123456');
    log.clear();

    await SignOut(session: session, pins: pins, transfers: transfers)();

    expect(log, [
      'store.clear',
      'pin.clear',
      'session.clear',
      'api.signOut refresh-1',
    ]);
    expect(transfers.byKey, isEmpty);
    expect(pins.pin, isNull);
    expect(sessionStore.stored, isNull);
  });
}
