import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';

/// Échoué (montant remboursé) ou refusé (jamais débité) : l'argent n'est pas
/// parti.
bool isUnsuccessful(TransferStatus status) =>
    status == TransferStatus.failed || status == TransferStatus.rejected;

/// Onglets de l'historique, comme ceux de l'écran « Payment history » du kit.
enum HistoryFilter {
  all('Tous'),

  /// Tout ce qui n'est pas final, y compris les transferts en vérification.
  inProgress('En cours'),
  paid('Payés'),
  unsuccessful('Échoués');

  const HistoryFilter(this.label);

  final String label;

  bool matches(TransferStatus status) => switch (this) {
    all => true,
    inProgress => !status.isFinal,
    paid => status == TransferStatus.paid,
    unsuccessful => isUnsuccessful(status),
  };
}

typedef HistorySection = ({String title, List<Transfer> transfers});

/// Regroupe l'historique par jour : « Aujourd'hui », « Hier », puis la date.
///
/// L'historique arrive déjà trié du plus récent au plus ancien : un jour
/// commence quand le titre change.
List<HistorySection> sectionsByDay(List<Transfer> transfers, DateTime now) {
  final sections = <HistorySection>[];
  for (final transfer in transfers) {
    final title = dayLabel(transfer.createdAt, now);
    if (sections.isNotEmpty && sections.last.title == title) {
      sections.last.transfers.add(transfer);
    } else {
      sections.add((title: title, transfers: [transfer]));
    }
  }
  return sections;
}
