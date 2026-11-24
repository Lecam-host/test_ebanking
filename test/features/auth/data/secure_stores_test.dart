import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/auth/data/pin_store_impl.dart';
import 'package:test_ebanking/features/auth/data/session_store_impl.dart';
import 'package:test_ebanking/features/auth/domain/entities/session.dart';

void main() {
  const storage = FlutterSecureStorage();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('session : numéro et jeton de renouvellement gardés, jamais le jeton '
      'd\'accès', () async {
    final store = SessionStoreImpl(storage);

    await store.save(
      const Session(
        phone: '0700000001',
        refreshToken: 'REFRESH',
        accessToken: 'ACCESS',
      ),
    );

    final stored = (await storage.readAll()).values.join();
    expect(stored, contains('REFRESH'));
    expect(stored, isNot(contains('ACCESS')));
    final read = await store.read();
    expect(read!.phone, '0700000001');
    expect(read.accessToken, isNull);

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('code secret : seule une empreinte salée est gardée', () async {
    final pins = PinStoreImpl(storage);

    await pins.save('1234');
    final firstHash = (await storage.readAll())['pin_hash'];

    expect((await storage.readAll()).values, isNot(contains('1234')));
    expect(firstHash, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await pins.matches('1234'), isTrue);
    expect(await pins.matches('0000'), isFalse);

    // Nouveau sel à chaque enregistrement : la même empreinte ne se retrouve
    // pas d'un téléphone à l'autre.
    await pins.save('1234');
    expect((await storage.readAll())['pin_hash'], isNot(firstHash));

    await pins.clear();
    expect(await pins.hasPin(), isFalse);
  });
}
