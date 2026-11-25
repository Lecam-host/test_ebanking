import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/history_sections.dart';

Transfer transferAt(String key, DateTime at) => Transfer(
  idempotencyKey: key,
  amount: 1000,
  currency: 'XOF',
  recipientName: 'Awa Kone',
  recipientPhone: '0701020304',
  status: TransferStatus.paid,
  createdAt: at,
  updatedAt: at,
);

void main() {
  test('chaque statut est dans « Tous » et dans un seul autre onglet', () {
    const expected = {
      TransferStatus.pendingSubmission: HistoryFilter.inProgress,
      TransferStatus.unknownOutcome: HistoryFilter.inProgress,
      TransferStatus.submitted: HistoryFilter.inProgress,
      TransferStatus.processing: HistoryFilter.inProgress,
      TransferStatus.paid: HistoryFilter.paid,
      TransferStatus.failed: HistoryFilter.unsuccessful,
      TransferStatus.rejected: HistoryFilter.unsuccessful,
    };
    // Aucun statut oublié.
    expect(expected.keys, unorderedEquals(TransferStatus.values));

    expected.forEach((status, filter) {
      expect(HistoryFilter.values.where((f) => f.matches(status)).toList(), [
        HistoryFilter.all,
        filter,
      ], reason: '$status');
    });
  });

  test('regroupé par jour, dans l\'ordre de l\'historique', () {
    final now = DateTime(2026, 11, 23, 18);
    // Du plus récent au plus ancien, comme la base les renvoie.
    final history = [
      transferAt('a', DateTime(2026, 11, 23, 10)),
      transferAt('b', DateTime(2026, 11, 23, 9)),
      transferAt('c', DateTime(2026, 11, 22, 20)),
      transferAt('d', DateTime(2026, 11, 20, 8)),
    ];

    final sections = sectionsByDay(history, now);

    expect(sections.map((s) => s.title), [
      'Aujourd\'hui',
      'Hier',
      '20/11/2026',
    ]);
    expect(
      sections.map((s) => s.transfers.map((t) => t.idempotencyKey).toList()),
      [
        ['a', 'b'],
        ['c'],
        ['d'],
      ],
    );
  });

  test('historique vide : aucune section', () {
    expect(sectionsByDay(const [], DateTime(2026, 11, 23)), isEmpty);
  });
}
