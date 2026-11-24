import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';

void main() {
  test('montants groupés par milliers, en FCFA', () {
    expect(formatAmount(500), '500 FCFA');
    expect(formatAmount(25000), '25 000 FCFA');
    expect(formatAmount(1000000), '1 000 000 FCFA');
  });

  test('« Mis à jour il y a X » selon la dernière synchro', () {
    final now = DateTime(2026, 11, 23, 12);

    expect(updatedAgo(null, now), 'Jamais mis à jour');
    expect(updatedAgo(now, now), 'Mis à jour à l\'instant');
    expect(
      updatedAgo(now.subtract(const Duration(minutes: 5)), now),
      'Mis à jour il y a 5 min',
    );
    expect(
      updatedAgo(now.subtract(const Duration(hours: 3)), now),
      'Mis à jour il y a 3 h',
    );
  });
}
