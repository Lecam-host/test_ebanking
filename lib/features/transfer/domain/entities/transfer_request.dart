/// Données saisies pour un transfert, avant tout enregistrement.
class TransferRequest {
  const TransferRequest({
    required this.amount,
    required this.recipientName,
    required this.recipientPhone,
    this.currency = 'XOF',
  });

  /// Montant en FCFA. Un entier : le franc CFA n'a pas de centimes, et on
  /// évite les erreurs d'arrondi des nombres à virgule.
  final int amount;
  final String currency;
  final String recipientName;

  /// Numéro ivoirien : 10 chiffres, sans espace ni indicatif.
  final String recipientPhone;

  static final _ivorianPhone = RegExp(r'^\d{10}$');

  /// Problèmes de saisie, un message par problème ; vide si tout est valide.
  List<String> validate() => [
    if (amount <= 0) 'Le montant doit être supérieur à 0.',
    if (!_ivorianPhone.hasMatch(recipientPhone))
      'Le numéro doit comporter exactement 10 chiffres.',
    if (recipientName.trim().isEmpty) 'Le nom du bénéficiaire est obligatoire.',
  ];
}
