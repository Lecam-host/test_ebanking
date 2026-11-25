import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';

/// Un bénéficiaire déjà utilisé : un appui remplit le nom et le numéro.
typedef Beneficiary = ({String name, String phone});

/// Bénéficiaires des derniers transferts, du plus récent au plus ancien, un
/// seul par numéro. Tiré de l'historique du téléphone : pas de carnet à
/// tenir à part, et la liste marche hors ligne.
List<Beneficiary> recentBeneficiaries(
  List<Transfer> transfers, {
  int max = 10,
}) {
  final byPhone = <String, Beneficiary>{};
  // L'historique arrive du plus récent au plus ancien : le premier transfert
  // vers un numéro donne le nom le plus récent.
  for (final transfer in transfers) {
    if (byPhone.length == max) break;
    byPhone.putIfAbsent(
      transfer.recipientPhone,
      () => (name: transfer.recipientName, phone: transfer.recipientPhone),
    );
  }
  return byPhone.values.toList();
}
