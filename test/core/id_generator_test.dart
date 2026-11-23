import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/id_generator.dart';

void main() {
  test('UuidIdGenerator produit des UUID v4 tous différents', () {
    const generator = UuidIdGenerator();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    final ids = List.generate(100, (_) => generator.newId());

    expect(ids, everyElement(matches(uuidV4)));
    expect(ids.toSet(), hasLength(100));
  });
}
