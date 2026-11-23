/// Statut d'un transfert vu du téléphone.
///
/// [pendingSubmission] et [unknownOutcome] n'existent que sur le téléphone.
/// [submitted], [processing], [paid] et [failed] reprennent les statuts du
/// serveur (SUBMITTED, PROCESSING, PAID, FAILED). [rejected] traduit un refus 4xx.
enum TransferStatus {
  /// Enregistré sur le téléphone, envoi pas encore confirmé.
  pendingSubmission,

  /// Envoyé sans réponse exploitable : le serveur l'a peut-être créé.
  unknownOutcome,

  submitted,
  processing,
  paid,
  failed,

  /// Refusé par le serveur : rien n'a été créé.
  rejected;

  bool get isFinal => this == paid || this == failed || this == rejected;

  /// Statut incertain : il faut demander au serveur avant de conclure.
  bool get needsReconciliation =>
      this == pendingSubmission || this == unknownOutcome;
}
