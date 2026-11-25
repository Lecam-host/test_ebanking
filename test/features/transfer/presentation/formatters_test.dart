import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';

void main() {
  test('montants groupés par milliers, en FCFA', () {
    expect(formatAmount(500), '500 FCFA');
    expect(formatAmount(25000), '25 000 FCFA');
    expect(formatAmount(1000000), '1 000 000 FCFA');
  });

  test('montant en lettres, orthographe traditionnelle', () {
    const cases = {
      1: 'un franc CFA',
      21: 'vingt et un francs CFA',
      71: 'soixante et onze francs CFA',
      75: 'soixante-quinze francs CFA',
      80: 'quatre-vingts francs CFA',
      81: 'quatre-vingt-un francs CFA',
      91: 'quatre-vingt-onze francs CFA',
      200: 'deux cents francs CFA',
      201: 'deux cent un francs CFA',
      1000: 'mille francs CFA',
      3000: 'trois mille francs CFA',
      25000: 'vingt-cinq mille francs CFA',
      80000: 'quatre-vingt mille francs CFA',
      200000: 'deux cent mille francs CFA',
      1000000: 'un million de francs CFA',
      1500000: 'un million cinq cent mille francs CFA',
      2000000: 'deux millions de francs CFA',
      999999:
          'neuf cent quatre-vingt-dix-neuf mille neuf cent '
          'quatre-vingt-dix-neuf francs CFA',
    };
    cases.forEach((amount, words) {
      expect(amountInWords(amount), words, reason: '$amount');
    });
  });

  test('date et heure sur deux chiffres', () {
    final dateTime = DateTime(2026, 3, 5, 9, 7);
    expect(formatDate(dateTime), '05/03/2026');
    expect(formatTime(dateTime), '09:07');
    expect(formatDateTime(dateTime), '05/03/2026 09:07');
  });

  test('jour de l\'historique : aujourd\'hui, hier, puis la date', () {
    final now = DateTime(2026, 11, 23, 0, 30);

    expect(dayLabel(DateTime(2026, 11, 23, 0, 5), now), 'Aujourd\'hui');
    // 40 min plus tôt, mais la veille : c'est le jour qui compte.
    expect(dayLabel(DateTime(2026, 11, 22, 23, 50), now), 'Hier');
    expect(dayLabel(DateTime(2026, 11, 21, 12), now), '21/11/2026');
    // Horloge du serveur un peu en avance, juste avant minuit.
    expect(
      dayLabel(DateTime(2026, 11, 24, 0, 1), DateTime(2026, 11, 23, 23, 59)),
      'Aujourd\'hui',
    );
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
