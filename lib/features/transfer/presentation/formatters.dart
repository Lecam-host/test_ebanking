import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

/// 25000 → « 25 000 FCFA » (espaces insécables, pour ne jamais couper le nombre).
String formatAmount(int amount) {
  final grouped = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return '$grouped FCFA';
}

/// 25000 → « vingt-cinq mille francs CFA ». Sous le champ du montant : un
/// zéro de trop se voit tout de suite en toutes lettres.
///
/// Orthographe traditionnelle : traits d'union sous cent, « et un »,
/// « quatre-vingts » et « cents » au pluriel seulement en fin de nombre,
/// « mille » invariable, « un million de francs ».
String amountInWords(int amount) {
  final words = _numberInWords(amount);
  final currency = amount <= 1 ? 'franc CFA' : 'francs CFA';
  // « un million de francs », mais « un million cinq cent mille francs ».
  final of = RegExp(r'(million|milliard)s?$').hasMatch(words) ? 'de ' : '';
  return '$words $of$currency';
}

const _units = [
  'zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', //
  'neuf', 'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize',
];

const _tens = [
  '', '', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante', //
];

String _numberInWords(int n) {
  if (n == 0) return _units[0];
  final billions = n ~/ 1000000000;
  final millions = n ~/ 1000000 % 1000;
  final thousands = n ~/ 1000 % 1000;
  final rest = n % 1000;
  return [
    if (billions > 0)
      '${_below1000(billions)} milliard${billions > 1 ? 's' : ''}',
    if (millions > 0)
      '${_below1000(millions)} million${millions > 1 ? 's' : ''}',
    if (thousands == 1) 'mille',
    // Devant « mille », « cents » et « quatre-vingts » perdent leur s.
    if (thousands > 1) '${_withoutFinalS(_below1000(thousands))} mille',
    if (rest > 0) _below1000(rest),
  ].join(' ');
}

/// « deux cents » → « deux cent », « quatre-vingts » → « quatre-vingt » ;
/// « trois » garde son s.
String _withoutFinalS(String words) =>
    words.endsWith('cents') || words.endsWith('vingts')
    ? words.substring(0, words.length - 1)
    : words;

String _below1000(int n) {
  final hundreds = n ~/ 100;
  final rest = n % 100;
  final hundredsWords = switch (hundreds) {
    0 => null,
    1 => 'cent',
    _ => '${_units[hundreds]} cent${rest == 0 ? 's' : ''}',
  };
  return [?hundredsWords, if (rest > 0) _below100(rest)].join(' ');
}

String _below100(int n) {
  if (n <= 16) return _units[n];
  if (n < 20) return 'dix-${_units[n - 10]}';
  final tens = n ~/ 10;
  final unit = n % 10;
  return switch (tens) {
    // 70 à 79 : soixante-dix… ; 90 à 99 : quatre-vingt-dix…
    7 when n == 71 => 'soixante et onze',
    7 => 'soixante-${_below100(n - 60)}',
    9 => 'quatre-vingt-${_below100(n - 80)}',
    8 => unit == 0 ? 'quatre-vingts' : 'quatre-vingt-${_units[unit]}',
    _ => switch (unit) {
      0 => _tens[tens],
      1 => '${_tens[tens]} et un',
      _ => '${_tens[tens]}-${_units[unit]}',
    },
  };
}

/// 0701020304 → « 07 01 02 03 04 ».
String formatPhone(String phone) => [
  for (var i = 0; i < phone.length; i += 2)
    phone.substring(i, i + 2 > phone.length ? phone.length : i + 2),
].join(' ');

/// 0701020304 → « 07 •• •• 03 04 », comme un numéro de carte masqué.
String maskPhone(String phone) => phone.length != 10
    ? phone
    : '${phone.substring(0, 2)} •• •• '
          '${phone.substring(6, 8)} ${phone.substring(8)}';

/// « 23/11/2026 », à l'heure du téléphone.
String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_two(local.day)}/${_two(local.month)}/${local.year}';
}

/// « 14:05 », à l'heure du téléphone.
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// « 23/11/2026 14:05 », à l'heure du téléphone.
String formatDateTime(DateTime dateTime) =>
    '${formatDate(dateTime)} ${formatTime(dateTime)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Titre d'un jour de l'historique : « Aujourd'hui », « Hier » ou la date.
String dayLabel(DateTime dateTime, DateTime now) {
  // Jours du calendrier comptés en UTC : un jour de changement d'heure (23 h
  // ou 25 h) ne fausse pas l'écart.
  DateTime day(DateTime value) {
    final local = value.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }

  return switch (day(now).difference(day(dateTime)).inDays) {
    // ≤ 0 : une horloge serveur un peu en avance ne crée pas de « demain ».
    <= 0 => 'Aujourd\'hui',
    1 => 'Hier',
    _ => formatDate(dateTime),
  };
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

/// Ce que le statut veut dire pour l'argent du client, sous le statut du
/// détail.
String statusExplanation(TransferStatus status) => switch (status) {
  TransferStatus.pendingSubmission || TransferStatus.unknownOutcome =>
    'Le serveur n\'a pas encore confirmé ce transfert. L\'app vérifie toute '
        'seule ; il ne partira jamais deux fois.',
  TransferStatus.submitted =>
    'Le serveur a accepté le transfert ; son traitement va commencer.',
  TransferStatus.processing =>
    'Le paiement au bénéficiaire est en cours. En cas d\'échec, le montant '
        'sera remboursé.',
  TransferStatus.paid => 'L\'argent a été versé au bénéficiaire.',
  TransferStatus.failed =>
    'Le transfert a échoué : le montant a été remboursé sur votre compte.',
  TransferStatus.rejected =>
    'Le serveur a refusé ce transfert : rien n\'a été débité.',
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
