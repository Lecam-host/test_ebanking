/// Notification de changement de statut d'un transfert.
class PushMessage {
  const PushMessage({required this.transferKey, required this.title});

  /// Clé d'idempotence du transfert : c'est elle qui l'identifie dans l'app.
  final String transferKey;

  final String title;
}
