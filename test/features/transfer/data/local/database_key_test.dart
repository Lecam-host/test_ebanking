import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/data/local/database_key.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('créée au premier appel (32 octets en hexadécimal), puis relue telle '
      'quelle', () async {
    const storage = FlutterSecureStorage();

    final first = await DatabaseKey(storage).loadOrCreate();
    final second = await DatabaseKey(storage).loadOrCreate();

    expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(second, first);
  });
}
