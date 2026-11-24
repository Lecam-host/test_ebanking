import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

/// 25000 → « 25 000 FCFA » (espaces insécables, pour ne jamais couper le nombre).
String formatAmount(int amount) {
  final grouped = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return '$grouped FCFA';
}

/// « 23/11/2026 14:05 », à l'heure du téléphone.
String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String statusLabel(TransferStatus status) => switch (status) {
  TransferStatus.pendingSubmission ||
  TransferStatus.unknownOutcome => 'Vérification en cours',
  TransferStatus.submitted => 'Envoyé',
  TransferStatus.processing => 'En cours de traitement',
  TransferStatus.paid => 'Payé',
  TransferStatus.failed => 'Échoué',
  TransferStatus.rejected => 'Refusé',
};

/// « Mis à jour il y a 5 min », à partir de la dernière synchro réussie.
String updatedAgo(DateTime? lastSyncedAt, DateTime now) {
  if (lastSyncedAt == null) return 'Jamais mis à jour';
  final minutes = now.difference(lastSyncedAt).inMinutes;
  if (minutes < 1) return 'Mis à jour à l\'instant';
  if (minutes < 60) return 'Mis à jour il y a $minutes min';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'Mis à jour il y a $hours h';
  return 'Mis à jour le ${formatDateTime(lastSyncedAt)}';
}
